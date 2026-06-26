#{{{INCLUDES
import struct
import time

from hardware.can.can_interface import *
from hardware.can.can_socketcan import SocketCANInterface
from hardware.can.can_message_parser import CANMessageParser
#}}}

#{{{get_map
def get_map(self, A: list, B: list) -> dict:
    m = {}
    for i, a in enumerate(A):
        try:
            m[a] = B[i]
        except:
            pass
    return m
#}}}

class Wrapper:
    #{{{CONSTANTS
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
    non_source_angles = get_map(NON_SOURCES, [0.0 for n in len(NON_SOURCES)])
    #}}}

    joint_to_act = get_map(JOINTS, ACTUATORS)
    act_to_joint = get_map(ACTUATORS, JOINTS)
    pot_to_joint = get_map(POTENTIOMETERS, JOINTS)


    def __init__(self):
        self.can_message_parser = CANMessageParser()

    #{{{get_angles
    def get_angles(self, can_interface: SocketCANInterface) -> dict:
        pot_angles = {}
        while not all((pot in pot_angles) for pot in POTENTIOMETERS):
            messages = can_interface.read(timeout=0.1)
            for msg in messages:
                msg_type = getattr(msg, 'message_type', 'unknown')
                parsed_data = getattr(msg, 'parsed_data', {})

                try:
                    pot_angles[pot_to_joint(msg_type)] = parsed_data['value']
                except:
                    pass

            time.sleep(0.1)

        return pot_angles | non_source_angles
    #}}}

    #{{{command_angles
    def command_angles(self, can_interface: SocketCANInterface, angle_map: dict[str, float]) -> None:
        for joint, angle in angle_map.items():
            self.command_angle(can_interface, self.joint_to_act[joint], angle, 100)
    #}}}

    #{{{command_angle
    def command_angle(self, can_interface: SocketCANInterface, actuator: str, angle, velocity) -> None:
        can_id, data = self.can_message_parser.encode(actuator, {"angle": float(angle), "velocity": float(velocity)})
        self.can_interface.send(can_id, data)
        if self.act_to_joint(actuator) in NON_SOURCES:
            self.non_source_angles[self.act_to_joint[actuator]] = angle #TODO: ADD CONFIRMATION CHECK FROM NODES
    #}}}

    #{{{run_program
    def run_program(self, program: function) -> None:
        can_interface = SocketCANInterface(interface="can0", bitrate=1000000)
        can_interface.start()
        #TODO: ADD RESET OF NON_SOURCE JOINTS, SUCH THAT non_source_angles IS CORRECT IN THE BEGINNING
        try:
            program(can_interface)
        except:
            print('program error')
        can_interface.stop()
    #}}}
