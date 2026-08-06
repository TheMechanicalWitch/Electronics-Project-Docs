
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


params = Dict([
	shoulder_left_right  => 30,
	shoulder_up_down     => 20,
	elbow_up_down        => -100,
	upper_arm_rotation   => 00,
	lower_arm_rotation   => 60,

	index_finger         => -35,
	middle_finger        => -20,
	ring_finger          => -10,
	pinky_finger         => -5,
	thumb_finger         => 30,

	index_finger_length  => -7,
	middle_finger_length => -9,
	ring_finger_length   => -8,
	pinky_finger_length  => -6,
	thumb_finger_length  => -7,

	shoulder_offset_a    => -10,
	shoulder_offset_b    => 30,
	upper_arm_a          => -30,
	upper_arm_b          => -30,
	lower_arm_a          => -30,
	lower_arm_b          => -30
])

render_arm = p->arm_cad_model(arm)(
	p,
	[
		x->tentacle(x, 5, 3, 1)
		[
			x->tentacle(x, 4, 1, 1)
			for _ in 1:10
		]...
	]
) → x->write_out(union(set_rendering_parameter("fn", 10), x))
