import can_wrapper
import time, os

w = can_wrapper.CANWrapper()

UPDATE_DELAY = 0.5

def monitor_angles():
    while True:
        angles = w.get_angles()
        os.system('clear')
        nice_print(angles)
        time.sleep(UPDATE_DELAY)

def nice_print(d:dict):
    for key, val in sorted(d.items()):
        if key in w.SOURCES:
            print(f'{key} : {val:.2f}')

w.run_program(monitor_angles)
