import can_wrapper
import time, random

w = can_wrapper.CANWrapper()

def displace_arm():
    angles = w.get_angles()

    for joint, angle in angles.items():
        angles[joint] = angle + random.choice([10,-10])

    print(w.command_angles(angles, wait_until_complete=True, timeout=100.0, precision=10.0))

def shake_arm():
    for i in range(5):
        displace_arm()
        print("LOOP")

w.run_program(shake_arm)
