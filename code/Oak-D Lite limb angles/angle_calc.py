import numpy as np

class AngleCalc():
    JOINTS = [
        'shoulder_up_down'   ,
        'shoulder_left_right',
        'upper_arm_rotation' ,
        'elbow_up_down'      ,
        'lower_arm_rotation' ,
        "thumb"              ,
        "index"              ,
        "middle"             ,
        "ring"               ,
        "pinky"              ,
    ]

    def angle_from_coords(b: np.ndarray, a: np.ndarray, c: np.ndarray):
        """Angle in degrees at point b, between the 3D segments b->a and b->c."""
        v1, v2 = a - b, c - b
        denom = np.linalg.norm(v1) * np.linalg.norm(v2)
        if denom < 1e-6:
            return None
        return float(np.degrees(np.arccos(np.clip(np.dot(v1, v2) / denom, -1.0, 1.0))))

    def get_angle(joint_name: str, side: str, data: dict):
        side = side.upper()

        if joint_name == JOINTS[4]: # elbow_up_down
            b = np.array(data[side+'_elbow'])
            a = np.array(data[side+'_wrist'])
            c = np.array(data[side+'_shoulder'])
            return self.angle_from_coords(b, a, c)
