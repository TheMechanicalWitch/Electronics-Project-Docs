import can_wrapper
import time, os

w = can_wrapper.CANWrapper()

UPDATE_DELAY = 0.5

def monitor_angles():
    while True:
        angles = w.get_angles()
        os.system('clear')
        print(angles)
        time.sleep(UPDATE_DELAY)

w.run_program(monitor_angles)
