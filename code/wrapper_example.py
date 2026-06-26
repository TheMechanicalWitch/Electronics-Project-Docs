import can_wrapper
import time, random

w = can_wrapper.CANWrapper()

def displace_arm():
    angles = w.get_angles()

    for joint, angle in angles.items():
        angles[joint] = angle + random.choice([10,-10])

    w.command_angles(angles)

def shake_arm():
    for i in range(5):
        displace_arm()
        time.sleep(1)

w.run_program(shake_arm)
