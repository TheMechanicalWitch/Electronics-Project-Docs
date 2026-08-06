include("inclusions.jl")

using Sockets
using JSON

IP = ip"192.168.55.1"
PORT = 65432

sock = connect(IP, PORT)

JOINTS = [
	"shoulder_left_right",
	"shoulder_up_down"   ,
	"upper_arm_rotation" ,
	"elbow_up_down"      ,
	"lower_arm_rotation" ,
	"thumb"              ,
	"index"              ,
	"middle"             ,
	"ring"               ,
	"pinky"              ,
]

function send_angles(conf)
	command = Dict()
	for i ∈ 1:length(conf)
		command[JOINTS[i]] = conf[i]
	end
	display(command)
	write(sock, JSON.json(command))
end

#try
	while true
		display(latest_data[]["arms"])
		targets = big_map(latest_data[]["arms"], "L")
		display(targets)
		global current_configuration = goto_targets(targets, current_configuration)
		send_angles(current_configuration)
	end
#catch Except
#end

close(sock)
println("closed socket connection")
