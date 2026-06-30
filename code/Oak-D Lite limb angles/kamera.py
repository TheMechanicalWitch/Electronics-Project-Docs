#!/usr/bin/env python3

import os
os.environ["GLOG_minloglevel"] = "2"

import time
import cv2
import numpy as np
import depthai as dai
from depthai_nodes.node import ParsingNeuralNetwork

MODEL = "luxonis/yolov8-nano-pose-estimation:coco-512x288"
KP_CONF = 0.3   

# COCO-17 keypoint indices, vänster och höger axel/armbåge/handled
L_SH, R_SH = 5, 6
L_EL, R_EL = 7, 8
L_WR, R_WR = 9, 10


def angle(a, b, c):
    a, b, c = np.array(a, float), np.array(b, float), np.array(c, float)
    ba, bc = a - b, c - b
    cos = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-9)
    return np.degrees(np.arccos(np.clip(cos, -1.0, 1.0)))

device = dai.Device(maxUsbSpeed=dai.UsbSpeed.HIGH)
print("USB speed:", device.getUsbSpeed())

with dai.Pipeline(device) as pipeline:
    cam = pipeline.create(dai.node.Camera).build(dai.CameraBoardSocket.CAM_A)
    nn = pipeline.create(ParsingNeuralNetwork).build(cam, MODEL)

    det_q = nn.out.createOutputQueue(maxSize=4, blocking=False)
    img_q = nn.passthrough.createOutputQueue(maxSize=4, blocking=False)

    pipeline.start()
    print("On-device pose running. Press 'q' to quit.")
    t_prev, fps = time.time(), 0.0

    while pipeline.isRunning():
        in_img = img_q.get()
        in_det = det_q.get()
        frame = in_img.getCvFrame()
        H, W = frame.shape[:2]

        for det in in_det.detections:
            kps = det.getKeypoints()

            def kp_coords(kp):
                p = kp.imageCoordinates
                return p.x, p.y, kp.confidence

            pts = []
            for kp in kps:
                x, y, c = kp_coords(kp)
                pts.append((int(x * W), int(y * H), c))
                if c > KP_CONF:
                    cv2.circle(frame, (int(x * W), int(y * H)), 3, (0, 255, 0), -1)

            y_txt = 50
            for label, (s, e, w) in {
                "L elbow": (L_SH, L_EL, L_WR),
                "R elbow": (R_SH, R_EL, R_WR),
            }.items():
                if max(s, e, w) < len(pts):
                    (xs, ys, cs) = pts[s]; (xe, ye, ce) = pts[e]; (xw, yw, cw) = pts[w]
                    if min(cs, ce, cw) > KP_CONF:
                        cv2.line(frame, (xs, ys), (xe, ye), (0, 220, 255), 2)
                        cv2.line(frame, (xe, ye), (xw, yw), (0, 220, 255), 2)
                        a = angle((xs, ys), (xe, ye), (xw, yw))
                        cv2.putText(frame, f"{a:.0f}", (xe + 8, ye - 8),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 255), 2)
                        cv2.putText(frame, f"{label}: {a:5.1f}", (10, y_txt),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 255), 2)
                        y_txt += 28
        now = time.time()
        fps = 0.9 * fps + 0.1 * (1.0 / max(now - t_prev, 1e-6))
        t_prev = now
        cv2.putText(frame, f"{fps:.1f} FPS", (10, 24),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 0), 2)

        cv2.imshow("On-device pose (OAK-D Lite)", frame)
        if cv2.waitKey(1) == ord("q"):
            break

    cv2.destroyAllWindows()