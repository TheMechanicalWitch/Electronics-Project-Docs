using Sockets
using JSON

CLIENT_IP = ip"0.0.0.0"
CLIENT_PORT = 54321

sock = UDPSocket()
bind(sock, CLIENT_IP, CLIENT_PORT)

latest_data = Base.RefValue{Any}(nothing)

# Receiver task
@async begin
    while true
        latest_data[] = JSON.parse(String(recv(sock)))
    end
end

cam_to_rob(camc, shoulder) = begin
	normalized = (camc - shoulder) * 1000
	[-normalized[3], normalized[1], -normalized[2]]
end


big_map(arms, side) = [
	cam_to_rob(arms["$(side)_$point"], arms["$(side)_shoulder"])
	for point ∈ ("wrist", "elbow")
]
