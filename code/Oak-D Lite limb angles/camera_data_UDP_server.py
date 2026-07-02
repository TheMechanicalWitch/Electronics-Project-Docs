#{{{IMPORTS
import time
import urllib.request
from pathlib import Path

import cv2
import numpy as np
import depthai as dai
import mediapipe as mp
from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision

import socket
import json
#}}}
#{{{CONSTANTS
W, H = 640, 360        # RGB preview + depth output size (16:9 = full FOV of the 1080p sensor)
FPS = 30
ROI = 4                # depth = median of a (2*ROI+1)^2 pixel window around each joint
Z_MIN, Z_MAX = 200, 6000   # accept depth only in this range (mm)
VIS_THRESH = 0.5       # minimum MediaPipe landmark visibility

MODEL = "lite"         # "lite" (fastest), "full" or "heavy" (more accurate, slower)
MODEL_URL = ("https://storage.googleapis.com/mediapipe-models/pose_landmarker/"
             f"pose_landmarker_{MODEL}/float16/1/pose_landmarker_{MODEL}.task")
MODEL_PATH = Path(__file__).parent / f"pose_landmarker_{MODEL}.task"

# MediaPipe pose landmark indices: (shoulder, elbow, wrist)
ARMS = {"R": (12, 14, 16),   # person's right arm
        "L": (11, 13, 15)}   # person's left arm

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
PORT = 12345

UPDATE_DELAY = 0.5
#}}}
#{{{HELPER FUNCTIONS
def get_model() -> str:
    """Download the pose model on first run."""
    if not MODEL_PATH.exists():
        print(f"Downloading pose model to {MODEL_PATH} ...")
        try:
            urllib.request.urlretrieve(MODEL_URL, MODEL_PATH)
        except Exception as e:
            raise SystemExit(f"Model download failed ({e}).\n"
                             f"Download it manually from:\n  {MODEL_URL}\n"
                             f"and place it next to this script.")
    return str(MODEL_PATH)


def build_pipeline() -> dai.Pipeline:
    pipeline = dai.Pipeline()

    cam = pipeline.create(dai.node.ColorCamera)
    cam.setBoardSocket(dai.CameraBoardSocket.CAM_A)
    cam.setResolution(dai.ColorCameraProperties.SensorResolution.THE_1080_P)
    cam.setPreviewSize(W, H)
    cam.setInterleaved(False)
    cam.setColorOrder(dai.ColorCameraProperties.ColorOrder.BGR)
    cam.setFps(FPS)

    mono_l = pipeline.create(dai.node.MonoCamera)
    mono_r = pipeline.create(dai.node.MonoCamera)
    mono_l.setBoardSocket(dai.CameraBoardSocket.CAM_B)
    mono_r.setBoardSocket(dai.CameraBoardSocket.CAM_C)
    for m in (mono_l, mono_r):
        m.setResolution(dai.MonoCameraProperties.SensorResolution.THE_480_P)  # OAK-D Lite monos
        m.setFps(FPS)

    stereo = pipeline.create(dai.node.StereoDepth)
    stereo.setDefaultProfilePreset(dai.node.StereoDepth.PresetMode.HIGH_DENSITY)
    stereo.initialConfig.setMedianFilter(dai.MedianFilter.KERNEL_7x7)
    stereo.setLeftRightCheck(True)        # better occlusion handling
    stereo.setSubpixel(True)              # smoother depth
    stereo.setDepthAlign(dai.CameraBoardSocket.CAM_A)   # align depth to the RGB camera
    stereo.setOutputSize(W, H)            # 1:1 pixel match with the RGB preview
    mono_l.out.link(stereo.left)
    mono_r.out.link(stereo.right)

    xout_rgb = pipeline.create(dai.node.XLinkOut)
    xout_rgb.setStreamName("rgb")
    cam.preview.link(xout_rgb.input)

    xout_depth = pipeline.create(dai.node.XLinkOut)
    xout_depth.setStreamName("depth")
    stereo.depth.link(xout_depth.input)
    return pipeline


def depth_at(depth_mm: np.ndarray, u: int, v: int) -> float:
    """Median valid depth (mm) in a small window around pixel (u, v). 0 = no data."""
    h, w = depth_mm.shape
    x0, x1 = max(0, u - ROI), min(w, u + ROI + 1)
    y0, y1 = max(0, v - ROI), min(h, v + ROI + 1)
    win = depth_mm[y0:y1, x0:x1]
    valid = win[(win >= Z_MIN) & (win <= Z_MAX)]
    return float(np.median(valid)) if valid.size else 0.0


def to_xyz(u: int, v: int, z_mm: float, fx, fy, cx, cy) -> np.ndarray:
    """Pixel (u, v) + depth -> metric X, Y, Z in the camera frame (meters)."""
    z = z_mm / 1000.0
    return np.array([(u - cx) * z / fx, (v - cy) * z / fy, z])
#}}}
#{{{MAIN LOOP
def main():
    sock.bind(('127.0.0.1', PORT))

    landmarker = vision.PoseLandmarker.create_from_options(vision.PoseLandmarkerOptions(
        base_options=mp_python.BaseOptions(model_asset_path=get_model()),
        running_mode=vision.RunningMode.VIDEO,
        num_poses=1,
        min_pose_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    ))

    try:
        device = dai.Device(build_pipeline())
    except RuntimeError as e:
        raise SystemExit(f"Could not connect to the OAK-D Lite: {e}\n"
                         "Check the USB cable (USB 3 recommended). On Linux, install the "
                         "udev rules from the Luxonis docs if the device is not found.")

    with device:
        # Intrinsics of the RGB camera, scaled to our resolution
        M = np.array(device.readCalibration()
                     .getCameraIntrinsics(dai.CameraBoardSocket.CAM_A, W, H))
        fx, fy, cx, cy = M[0, 0], M[1, 1], M[0, 2], M[1, 2]

        q_rgb = device.getOutputQueue("rgb", maxSize=4, blocking=False)
        q_depth = device.getOutputQueue("depth", maxSize=4, blocking=False)

        depth_mm = None
        last_ts = 0
        last_print = 0.0
        print("Running - press q or Esc to quit.")

        while True:
            msg = q_depth.tryGet()
            if msg is not None:
                depth_mm = msg.getFrame()          # uint16, millimeters, aligned to RGB

            msg = q_rgb.tryGet()
            if msg is None:
                if cv2.waitKey(1) in (ord('q'), 27):
                    break
                continue
            frame = msg.getCvFrame()

            if depth_mm is None:                   # no depth yet, just show video
                cv2.imshow("arm 3D", frame)
                if cv2.waitKey(1) in (ord('q'), 27):
                    break
                continue

            # Colored depth view (0.3 m red ... 4 m blue)
            dv = np.clip(depth_mm, 300, 4000).astype(np.float32)
            dv = (255 - (dv - 300) / (4000 - 300) * 255).astype(np.uint8)
            depth_vis = cv2.applyColorMap(dv, cv2.COLORMAP_TURBO)

            # Pose detection (VIDEO mode needs strictly increasing timestamps)
            last_ts = max(last_ts + 1, int(time.monotonic() * 1000))
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            result = landmarker.detect_for_video(
                mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb), last_ts)

            report = {}
            y_txt = 20
            if result.pose_landmarks:
                lms = result.pose_landmarks[0]
                for side, idx in ARMS.items():
                    pts2d, pts3d = [], []
                    for i in idx:
                        lm = lms[i]
                        u, v = int(lm.x * W), int(lm.y * H)
                        if ((lm.visibility or 0) < VIS_THRESH
                                or not (0 <= u < W and 0 <= v < H)):
                            break
                        z = depth_at(depth_mm, u, v)
                        if z == 0.0:               # hole in the depth map
                            break
                        pts2d.append((u, v))
                        pts3d.append(to_xyz(u, v, z, fx, fy, cx, cy))
                    if len(pts3d) != 3:
                        continue

                    # ---- draw on the RGB view ----
                    cv2.line(frame, pts2d[0], pts2d[1], (0, 255, 255), 2)   # upper arm
                    cv2.line(frame, pts2d[1], pts2d[2], (255, 180, 0), 2)   # forearm
                    for p in pts2d:
                        cv2.circle(frame, p, 5, (0, 0, 255), -1)
                        cv2.circle(depth_vis, p, 5, (255, 255, 255), 2)

                    # ---- text overlay + terminal report ----
                    for name, P in zip(("shoulder", "elbow", "wrist"), pts3d):
                        line = (f"{side} {name:<8s} "
                                f"X {P[0]:+.3f}  Y {P[1]:+.3f}  Z {P[2]:.3f} m")
                        cv2.putText(frame, line, (8, y_txt),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.42, (255, 255, 255), 1)
                        y_txt += 16
                        report[f"{side}_{name}"] = {'x': P[0], 'y': P[1], 'z': P[2]}

            if report and time.time() - last_print > UPDATE_DELAY:
                rep_str = json.dumps(report, sort_keys=true, indent=2)
                print(rep_str)
                sock.sendto(b'{rep_str}', ('127.0.0.1', PORT))
                last_print = time.time()

            cv2.imshow("arm 3D", frame)
            cv2.imshow("depth", depth_vis)
            if cv2.waitKey(1) in (ord('q'), 27):
                break

    landmarker.close()
    cv2.destroyAllWindows()
#}}}
