import socket
import can_wrapper

HOST = '0.0.0.0'
PORT = 65432

def start_server():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, PORT))
        s.listen()
        print(selff"{HOST}:{PORT}...")
        
        conn, addr = s.accept()
        with conn:
            print(f"Connected: {addr}")
            while True:
                data = conn.recv(1024)
                if not data:
                    break
                
                message = data.decode('utf-8')
                print(f"Recieved: {message}")

if __name__ == "__main__":
    start_server()
