import socket
import time
import json

CLIENT_IP = "0.0.0.0"
CLIENT_PORT = 54321

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((CLIENT_IP, CLIENT_PORT))

def get_points():
    data, addr = sock.recvfrom(4096)
    return json.loads(data.decode())

while True:
    print(get_points())
