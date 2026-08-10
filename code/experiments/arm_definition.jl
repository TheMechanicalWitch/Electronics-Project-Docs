
finger(var::Symbol, name::String, len::Symbol, number_of_segments::Int64)::ArmLink = ArmLink(
	LA_rot_x(var)*
	LA_trans(0,0,len),
	"$name $number_of_segments",
	number_of_segments > 1 ? [finger(var, name, len, number_of_segments-1)] : []
)

hand = ArmLink(
	LA_trans(0,0,0),
	"hand base",
	[
		ArmLink(
			LA_trans(9,0,-20),
			"knuckle 1",
			[
				finger(:index_finger, "index finger", :index_finger_length, 3)
			]
		),
		ArmLink(
			LA_trans(3,0,-20),
			"knuckle 2",
			[
				finger(:middle_finger, "middle finger", :middle_finger_length, 3)
			]
		),
		ArmLink(
			LA_trans(-3,0,-20),
			"knuckle 3",
			[
				finger(:ring_finger, "ring finger", :ring_finger_length, 3)
			]
		),
		ArmLink(
			LA_trans(-9,0,-20),
			"knuckle 4",
			[
				finger(:pinky_finger, "pinky finger", :pinky_finger_length, 3)
			]
		),
		ArmLink(
			LA_trans(9,-9,-15)*
			LA_rot_x(-90),
			"knuckle 5",
			[
				finger(:thumb_finger, "thumb finger", :thumb_finger_length, 2)
			]
		)
	]
)

arm = ArmLink(
	LA_trans(0,0,0),
	"base",
	[
		ArmLink(
			LA_rot_x(:shoulder_left_right)*
			LA_trans(0,0,:shoulder_offset_a),
			"shoulder segment a",
			[
				ArmLink(
					LA_rot_y(:shoulder_up_down)*
					LA_trans(0,:shoulder_offset_b,0),
					"shoulder segment b",
					[
						ArmLink(
							LA_trans(0,0,:upper_arm_a)*
							LA_rot_z(:upper_arm_rotation),
							"upper arm segment a",
							[
								ArmLink(
									LA_trans(0,0,:upper_arm_b)*
									LA_rot_y(:elbow_up_down),
									"upper arm segment b",
									[
										ArmLink(
											LA_rot_z(:lower_arm_rotation)*
											LA_trans(0,0,:lower_arm_a),
											"lower arm segment a",
											[
												ArmLink(
													LA_trans(0,0,:lower_arm_b),
													"lower arm segment b",
													[
													hand
													]
												)
											]
										)
									]
								)
							]
						)
					]
				)
			]
		)
	]
)

joint_parameters = ArmParameters(
	shoulder_left_right  => 30,
	shoulder_up_down     => 50,
	elbow_up_down        => 100,
	upper_arm_rotation   => 30,
	lower_arm_rotation   => 30,

	index_finger         => 10,
	middle_finger        => 20,
	ring_finger          => 30,
	pinky_finger         => 40,
	thumb_finger         => 50,
)

segment_length_parameters = ArmParameters(
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
	thumb_finger_length  => 7
)

all_parameters = joint_parameters ∪ segment_length_parameters

joint_limits = Dict(
	shoulder_left_right => (  0, 90 ),
	shoulder_up_down    => (-90, 180),
	upper_arm_rotation  => (-90, 90 ),
	elbow_up_down       => (  0, 170),
	lower_arm_rotation  => (-90, 90 ),

	index_finger        => (0, 90),
	middle_finger       => (0, 90),
	ring_finger         => (0, 90),
	pinky_finger        => (0, 90),
	thumb_finger        => (0, 90)
)

joints = [joint for joint ∈ keys(joint_limits)]

param_translation(params::ArmParameters)::ArmParameters = begin
	c = deepcopy(params)

	for param ∈ params
		if param ∈ (
			shoulder_up_down,
			elbow_up_down,
			upper_arm_rotation,

			index_finger,
			middle_finger,
			ring_finger,
			pinky_finger,

			index_finger_length,
			middle_finger_length,
			ring_finger_length,
			pinky_finger_length,
			thumb_finger_length,

			shoulder_offset_a,
			upper_arm_a,
			upper_arm_b,
			lower_arm_a,
			lower_arm_b
		)
			c[param] = -params[param]
		end
	end

	return c
end

render_arm = parameters->arm_cad_model(arm)(
	parameters → param_translation,
	[
		x->tentacle(x, 5, 3, 1)
		[
			x->tentacle(x, 4, 1, 1)
			for _ in 1:10
		]...
	]
) → x->write_out(
	union(
		set_rendering_parameter("fn", 10),
		translate(
			(
				-parameters[shoulder_offset_b]/2,
				-parameters[upper_arm_a]*1.5,
				-parameters[upper_arm_a]*2,
			) .→ Float64,
			cube(
				(
					parameters[shoulder_offset_b],
					parameters[upper_arm_a]*1.5,
					parameters[upper_arm_a]*2
				) .→ Float64
			)
		),
		x
	)
)
