import socket
import can_wrapper
import time
import json

HOST = '0.0.0.0'
PORT = 65432

w = can_wrapper.CANWrapper()

def start_server():
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind((HOST, PORT))
            s.listen()
            print(f"{HOST}:{PORT}...")

            conn, addr = s.accept()
            with conn:
                print(f"Connected: {addr}")
                while True:
                    data = conn.recv(1024)
                    if not data:
                        break

                    message = data.decode('utf-8')
                    angles = json.loads(message)
                    w.command_angles(angles, wait_until_complete=False, timeout=10.0, precision=0.0)
    except:
        s.close()
        print("closed server")

if __name__ == "__main__":
    w.run_program(start_server)
