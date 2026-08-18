trans_mats = global_trans_mats(arm) → Dict

fixed_parameters = ArmParameters([
	shoulder_offset_a    => 10,
	shoulder_offset_b    => 20,
	upper_arm_a          => 30,
	upper_arm_b          => 30,
	lower_arm_a          => 30,
	lower_arm_b          => 30,

	index_finger_length  => 7,
	middle_finger_length => 9,
	ring_finger_length   => 8,
	pinky_finger_length  => 6,
	thumb_finger_length  => 7,

	lower_arm_rotation   => 30,

	index_finger         => 10,
	middle_finger        => 20,
	ring_finger          => 30,
	pinky_finger         => 40,
	thumb_finger         => 50
])

dynamic_parameters = ArmParameters([
	shoulder_left_right  => 30,
	shoulder_up_down     => 50,
	elbow_up_down        => 100,
	upper_arm_rotation   => 30,
])

#={{{=#@logged function visualize_arm(
	visual_data::Dict,
	cam_to_rob_coords_map::Function,
	time_limit::Real,
	side::Char='L'
)

	@ignore visual_data

	targets = Dict(
		"upper arm segment b" => cam_to_rob_coords_map(visual_data["arms"]["$(side)_elbow"] .→ Float64),
		"lower arm segment b" => cam_to_rob_coords_map(visual_data["arms"]["$(side)_wrist"] .→ Float64)
	)

	@log targets

	#fixed_parameters[lower_arm_rotation] = ...
	global fixed_parameters[index_finger] = visual_data["hands"][string(side=='L' ? 0 : 1)]["indexfinger"] == "open" ? 2.0 : 70.0
	global fixed_parameters[middle_finger] = visual_data["hands"][string(side=='L' ? 0 : 1)]["middlefinger"] == "open" ? 2.0 : 70.0
	global fixed_parameters[ring_finger] = visual_data["hands"][string(side=='L' ? 0 : 1)]["ringfinger"] == "open" ? 2.0 : 70.0
	global fixed_parameters[pinky_finger] = visual_data["hands"][string(side=='L' ? 0 : 1)]["pinkyfinger"] == "open" ? 2.0 : 70.0
	global fixed_parameters[thumb_finger] = visual_data["hands"][string(side=='L' ? 0 : 1)]["thumb"] == "open" ? 2.0 : 70.0

	@log fixed_parameters

	global dynamic_parameters = find_targets(
		targets,
		trans_mats,
		fixed_parameters,
		dynamic_parameters,
		x->joint_constraints_error_vector(x, joint_limits),
		param_translation,
		time_limit
	)

	@log dynamic_parameters

	render_arm(dynamic_parameters ∪ fixed_parameters, targets)

end#}}}
