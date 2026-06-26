#{{{INCLUDES
import struct
import time

from hardware.can.can_interface import *
from hardware.can.can_socketcan import SocketCANInterface
from hardware.can.can_message_parser import CANMessageParser
#}}}

#{{{get_map
def get_map(A: list, B: list) -> dict:
    m = {}
    for i, a in enumerate(A):
        try:
            m[a] = B[i]
        except:
            pass
    return m
#}}}

class CANWrapper:
    #{{{CONSTANTS
    DEFAULT_PRECISION = 5.0

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
    SOURCES        = JOINTS[0:4]
    NON_SOURCES    = JOINTS[4:]
    POTENTIOMETERS = ['robot_' + joint + '_potentiometer' for joint in SOURCES]
    ACTUATORS      = ['robot_' + joint + '_actuation'     for joint in JOINTS ]
    #}}}

    #{{{GLOBALS
    non_source_angles = get_map(NON_SOURCES, [0.0 for n in range(len(NON_SOURCES))])
    #}}}

    joint_to_act = get_map(JOINTS, ACTUATORS)
    act_to_joint = get_map(ACTUATORS, JOINTS)
    pot_to_joint = get_map(POTENTIOMETERS, JOINTS)


    def __init__(self):
        self.can_message_parser = CANMessageParser()
        self.can_interface = None

    #{{{get_angles
    def get_angles(self) -> dict:
        pot_angles = {}
        while not all((self.pot_to_joint[pot] in pot_angles) for pot in self.POTENTIOMETERS):
            messages = self.can_interface.read(timeout=0.1)
            for msg in messages:
                msg_type = getattr(msg, 'message_type', 'unknown')
                parsed_data = getattr(msg, 'parsed_data', {})

                try:
                    pot_angles[self.pot_to_joint[msg_type]] = parsed_data['value']
                except Exception as e:
                    print(e)
                    pass
                print(pot_angles)

            time.sleep(0.1)

        return pot_angles | self.non_source_angles
    #}}}

    #{{{command_angles
    def command_angles(self, angle_map: dict[str, float], speed=100, wait_until_complete=False, timeout=5.0, precision=DEFAULT_PRECISION) -> bool:
        start_time = time.time()

        for joint, angle in angle_map.items():
            self.command_angle(self.joint_to_act[joint], angle, speed)

        if not wait_until_complete:
            return False

        while time.time() - start_time >= timeout:
            if angles_are_reached(angle_map, precision):
                return True
            time.sleep(0.1)
        return False
    #}}}

    #{{{angles_are_reached
    def angles_are_reached(self, angle_map, precision=DEFAULT_PRECISION):
        return False not in [target_angle + precision > get_angles()[joint] >= target_angle - precision
                             for joint, target_angle in angle_map.items()]
    #}}}

    #{{{command_angle
    def command_angle(self, actuator: str, angle, velocity) -> None:
        can_id, data = self.can_message_parser.encode(actuator, {"angle": float(angle), "velocity": float(velocity)})
        self.can_interface.send(can_id, data)
        if self.act_to_joint[actuator] in self.NON_SOURCES:
            self.non_source_angles[self.act_to_joint[actuator]] = angle #TODO: ADD CONFIRMATION CHECK FROM NODES
    #}}}

    #{{{run_program
    def run_program(self, program) -> None:
        self.can_interface = SocketCANInterface(interface="can0", bitrate=1000000)
        self.can_interface.start()
        try:
            program()
        except Exception as e:
            print(e)
        self.can_interface.stop()
    #}}}
