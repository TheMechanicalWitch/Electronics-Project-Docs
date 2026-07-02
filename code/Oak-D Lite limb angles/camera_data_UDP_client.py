import socket
import time
import json

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
PORT = 12345

sock.bind(('127.0.0.1', PORT))

def get_points():
    data, addr = sock.recvfrom(1024)
    return json.loads(data.decode())

while True:
    print(get_points())
    time.sleep(0.1)
