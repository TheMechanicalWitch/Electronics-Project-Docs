#{{{IMPORTS
import time
import urllib.request
from pathlib import Path

import cv2
import numpy as np
import depthai as dai
import math as math
import mediapipe as mp
from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision

import socket
import json

import os
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
HAND_MODEL_URL = (
    "https://storage.googleapis.com/mediapipe-models/hand_landmarker/"
    "hand_landmarker/float16/1/hand_landmarker.task"
)
HAND_MODEL_PATH = Path(__file__).parent / "hand_landmarker.task"

# MediaPipe pose landmark indices: (shoulder, elbow, wrist)
ARMS = {"R": (12, 14, 16),   # person's right arm
        "L": (11, 13, 15)}   # person's left arm


#----------------SOCKET------------------

SERVER_IP = "0.0.0.0"
SERVER_PORT = 12345

CLIENT_IP = "127.0.0.1"
CLIENT_PORT = 54321

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

UPDATE_DELAY = 0.1
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
def get_hand_model() -> str:
    if not HAND_MODEL_PATH.exists():
        print(f"Downloading hand model to {HAND_MODEL_PATH} ...")
        try:    
            urllib.request.urlretrieve(HAND_MODEL_URL, HAND_MODEL_PATH)
        except Exception as e:
            raise SystemExit(f"Hand model download failed ({e}).\n"
                            f"Download it manually from:\n  {HAND_MODEL_URL}\n"
                            f"and place it next to this script.")
    return str(HAND_MODEL_PATH)

def build_pipeline(device: dai.Device) -> tuple[dai.Pipeline, dai.Node.Output, dai.Node.Output]:
    pipeline = dai.Pipeline(device)

    cam = pipeline.create(dai.node.Camera).build(dai.CameraBoardSocket.CAM_A)
    cam_out = cam.requestOutput((W, H), dai.ImgFrame.Type.BGR888p, fps=FPS)

    mono_l = pipeline.create(dai.node.Camera).build(dai.CameraBoardSocket.CAM_B)
    mono_r = pipeline.create(dai.node.Camera).build(dai.CameraBoardSocket.CAM_C)

    left_out = mono_l.requestOutput((640, 480), dai.ImgFrame.Type.NV12, fps=FPS)
    right_out = mono_r.requestOutput((640, 480), dai.ImgFrame.Type.NV12, fps=FPS)

    stereo = pipeline.create(dai.node.StereoDepth).build(
        left=left_out, right=right_out, presetMode=dai.node.StereoDepth.PresetMode.FAST_DENSITY
    )
    stereo.initialConfig.setMedianFilter(dai.MedianFilter.KERNEL_7x7)
    stereo.setLeftRightCheck(True)
    stereo.setSubpixel(True)
    stereo.setDepthAlign(dai.CameraBoardSocket.CAM_A)
    stereo.setOutputSize(W, H)

    return pipeline, cam_out, stereo.depth

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

def joint_angle(a, b, c):
    #math at https://math.stackexchange.com/questions/974178/how-to-calculate-the-angle-between-2-vectors-in-3d-space-given-a-preset-function/974400#974400
    ba = (a[0]-b[0], a[1]-b[1], a[2]-b[2])
    bc = (c[0]-b[0], c[1]-b[1], c[2]-b[2])

    dot = sum(x*y for x, y in zip(ba, bc))
    mag_ba = math.sqrt(sum(x*x for x in ba))
    mag_bc = math.sqrt(sum(x*x for x in bc))

    if mag_ba == 0 or mag_bc == 0:
        return 0.0

    cos_theta = dot / (mag_ba * mag_bc)
    return math.degrees(math.acos(cos_theta))

#}}}
#{{{MAIN LOOP
def main():
    landmarker = vision.PoseLandmarker.create_from_options(vision.PoseLandmarkerOptions(
        base_options=mp_python.BaseOptions(model_asset_path=get_model()),
        running_mode=vision.RunningMode.VIDEO,
        num_poses=1,
        min_pose_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    ))
    hand_landmarker = vision.HandLandmarker.create_from_options(vision.HandLandmarkerOptions(
        base_options=mp_python.BaseOptions(model_asset_path=get_hand_model()),
        running_mode=vision.RunningMode.VIDEO,
        num_hands=2,
        min_hand_detection_confidence = 0.5,
        min_tracking_confidence = 0.5,
    ))
    try:
        with dai.Device() as device:
            pipeline, rgb_out, depth_out = build_pipeline(device)

            M = np.array(device.readCalibration()
                        .getCameraIntrinsics(dai.CameraBoardSocket.CAM_A, W, H))
            fx, fy, cx, cy = M[0, 0], M[1, 1], M[0, 2], M[1, 2]

            q_rgb = rgb_out.createOutputQueue(maxSize=4, blocking=False)
            q_depth = depth_out.createOutputQueue(maxSize=4, blocking=False)

            pipeline.start()

            depth_mm = None
            last_ts = 0
            last_print = 0.0
            print("Running - press q or Esc to quit.")

            while pipeline.isRunning():
                msg = q_depth.tryGet()
                if msg is not None:
                    depth_mm = msg.getFrame()

                msg = q_rgb.tryGet()
                if msg is None:
                    if cv2.waitKey(1) in (ord('q'), 27):
                        break
                    continue
                frame = msg.getCvFrame()
                frame = cv2.flip(frame, 1)

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
                hand_result = hand_landmarker.detect_for_video(
                    mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb), last_ts)
                

                report = {}
                report["arms"] = {}
                report["hands"] = {}
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
                        if len(pts3d) == 3:
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
                                report["arms"][f"{side}_{name}"] = [P[0], P[1], P[2]] # x y z

                        if len(pts3d) != 3:
                            continue
                if hand_result.hand_landmarks:
                    #report["hands"] = hand_result.hand_landmarks
                    for hand_idx, hand_lms in enumerate(hand_result.hand_landmarks):
                        report["hands"][hand_idx] = {}
                        points_space = []
                        hand_identifier = 0.0
                        for i, lm in enumerate(hand_lms):
                            u,v = int(lm.x * W), int(lm.y * H)
                            report["hands"][hand_idx][i] = [lm.x, lm.y, lm.z]
                            lm.space= lm.x + lm.y + lm.z
                            point = (lm.x,lm.y,lm.z)
                            points_space.append(point)
                            if 0 <= u < W and 0 <= v < H:
                                cv2.circle(frame, (u, v), 4, (0, 255, 0), -1)
                                cv2.circle(depth_vis, (u, v), 4, (0, 255, 0), 1)
                        for p in range(len(points_space) - 1):
                            distance = math.dist(points_space[p], points_space[p + 1])
                            hand_identifier += distance
                            print(distance)
                        reference = math.dist(points_space[0], points_space[12])
                        if reference > 0:
                            hand_identifier /= reference

                            thumb_angle = joint_angle(points_space[0], points_space[2], points_space[4])
                            index_angle = joint_angle(points_space[0], points_space[6], points_space[7])
                            middle_angle = joint_angle(points_space[0], points_space[10], points_space[11])
                            ring_angle = joint_angle(points_space[0], points_space[13], points_space[16])
                            pinky_angle = joint_angle(points_space[0], points_space[18], points_space[19])
                            hand_angletowrist = joint_angle(points_space[0], points_space[9], points_space[5])
                        #fingers = {"thumb": thumb_angle, "index": index_angle, "middle": middle_angle, "ring": ring_angle, "pinky": pinky_angle}   
                            if thumb_angle <= 70:
                                report["hands"][hand_idx]["thumb"] = "close"
                            else:
                                report["hands"][hand_idx]["thumb"] = "open"
                            if index_angle <= 70:
                                report["hands"][hand_idx]["indexfinger"] = "close"
                            else:
                                report["hands"][hand_idx]["indexfinger"] = "open"
                            if middle_angle <= 70:
                                report["hands"][hand_idx]["middlefinger"] = "close"
                            else:
                                report["hands"][hand_idx]["middlefinger"] = "open"
                            if ring_angle <= 70:
                                report["hands"][hand_idx]["ringfinger"] = "close"
                            else:
                                report["hands"][hand_idx]["middlefinger"] = "open"
                            if pinky_angle <= 70:
                                report["hands"][hand_idx]["pinkyfinger"] = "close"
                            else:
                                report["hands"][hand_idx]["pinkyfinger"] = "open"
                            closed_count = sum(
                                1 for finger in [
                                    "thumb",
                                    "indexfinger",
                                    "middlefinger",
                                    "ringfinger",
                                    "pinkyfinger"
                                ]
                                if fingers[finger] == "close"
                            )

                            if closed_count >= 3:
                                hand_state = "closed"
                            else:
                                hand_state = "open"

                            report["hands"][hand_idx]["hand_state"] = hand_state






                if report and time.time() - last_print > UPDATE_DELAY:
                    report["time"] = time.time()
                    rep_str = json.dumps(report, sort_keys=False, indent=2)
                    #os.system('clear')
                    print()
                    print(rep_str)
                    sock.sendto(f'{rep_str}'.encode(), (CLIENT_IP, CLIENT_PORT))
                    last_print = time.time()
                
                cv2.imshow("arm 3D", frame)
                cv2.imshow("depth", depth_vis)
                
                if cv2.waitKey(1) in (ord('q'), 27):
                    break
    except Exception as e:
        print("Error:", e)
    finally:
        try:
            hand_landmarker.close()
        except:
            pass

        try:
            landmarker.close()
        except:
            pass

        cv2.destroyAllWindows()
#}}}

if __name__ == "__main__":
    main()
