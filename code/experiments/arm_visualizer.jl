
@START_OF_DEBUG_CATEGORY "arm"

segment_lengths = [33, 87, 225, 272]

current_configuration::Vector{<:Real} = zeros(5)

joint_limits = ((0, 90), (-90, 90), (-90, 90), (0, 160), (-90, 90))

@logged function base(x::Real, y::Real, z::Real)
	shoulders=50
	return union(
		translate((-x/2, -y, -z),
			cube(x, y, z)
		),
		#=
		difference(
			translate((0, -shoulders/2, 60),
				resize((60,60,70),
					sphere(10)
				)
			),
			translate((2, -shoulders/2+10, 6),
				sphere(1)
			),
			translate((2, -shoulders/2-10, 6),
				sphere(1)
			)
		)
		=#
	)
end

@logged function arm(joints::Vector{<:Real}, segment_lengths::Vector{<:Real})::String
	thickness = 30
	cylinder_dim = "$(thickness),$(thickness/2),$(thickness/2)"
	cube_dim=15
	#{{{
	return """
rotate([0,90,0])
    cylinder($cylinder_dim,center=true);
rotate([$(joints[1]),0,0])
union(){
    translate([-7.5,-7.5,-$(segment_lengths[1])])
        cube([$cube_dim,$cube_dim,$(segment_lengths[1])]);
    translate([-7.5,0,-$(segment_lengths[1]+7.5)])
        cube([$cube_dim,$(segment_lengths[2]),$cube_dim]);
    translate([0,$(segment_lengths[2]),-$(segment_lengths[1])])
        union(){
            rotate([90,0,0])
                cylinder($cylinder_dim,center=true);
            rotate([0,-$(joints[2]),0])
            union(){
                translate([-7.5,-7.5,-$(segment_lengths[3]/2)])
                    cube([$cube_dim,$cube_dim,$(segment_lengths[3]/2)]);
                translate([0,0,-$(segment_lengths[3]/2)])
                    union(){
                        rotate([0,0,0])
                            cylinder($cylinder_dim,center=true);
                        rotate([0,0,-$(joints[3])])
                        union(){
                            translate([-7.5,-7.5,-$(segment_lengths[3]/2)])
                                cube([$cube_dim,$cube_dim,$(segment_lengths[3]/2)]);
                            translate([0,0,-$(segment_lengths[3]/2)])
                                union(){
                                    rotate([90,0,0])
                                        cylinder($cylinder_dim,center=true);
                                    rotate([0,-$(joints[4]),0])
                                    union(){
                                        translate([-7.5,-7.5,-$(segment_lengths[4]/2)])
                                            cube([$cube_dim,$cube_dim,$(segment_lengths[4]/2)]);
                                        translate([0,0,-$(segment_lengths[4]/2)])
                                            union(){
                                                rotate([0,0,0])
                                                    cylinder($cylinder_dim,center=true);
                                                rotate([0,0,$(joints[5])])
                                                union(){
                                                    translate([-7.5,-7.5,-$(segment_lengths[4]/2)])
                                                        cube([$cube_dim,$cube_dim,$(segment_lengths[4]/2)]);
                                                }
                                            }
                                    }
                                }
                        }
                    }
            }
        }
}"""
	#}}}
end

@logged function render_arm(joints::Vector{<:Real}, targets::Vector{<:RVect}=[], resolution::Int=30)::Nothing
	write_out(
		set_rendering_parameter("fn", resolution),
		base(((50,100,130) .→ Float64)...),
		arm(joints, segment_lengths),
		#translate((0,-50,0),
		#	mirror((0,1,0),
		#		arm(joints, segment_lengths),
		#	)
		#)
		translate(end_effector_position(joints, segment_lengths),
			sphere(30) → highlight
		),
		translate(elbow_position(joints, segment_lengths),
			sphere(30) → highlight
		),
		[
			translate(targets[i], "color(\"#$(("00ff00","ff00ff","00ffff","ffff00")[i])\")sphere(12);")
			for i in 1:length(targets)
		]...
	)
	return
end

@logged function animate_arm(funs::Vector{Function}, steps::Real, Δstep::Real, Δtime::Real, resolution::Int=10)::Nothing
	for s ∈ 0:Δstep:steps
		println(s)
		render_arm(
			[fun(s) for fun ∈ funs],
			[],
			resolution,
		)
		sleep(Δtime)
	end
	return
end

@END_OF_DEBUG_CATEGORY

@START_OF_DEBUG_CATEGORY "arm math"

@logged function pred_matrix_end_effector(joints::Vector{<:Real}, segment_lengths::Vector{<:Real})#::Matrix{<:Real}
	#rx = LA_rotation_matrix_x
	#ry = LA_rotation_matrix_y
	#rz = LA_rotation_matrix_z
	#t  = LA_translation_matrix
	#rx(j1)*t(0,l1,-l2)*ry(-j2)*t(0,0,-l3/2)*rz(-j3)*t(0,0,-l3/2)*r(0,-j4,0)*t(0,0,-l4/2)*rz(j5)*t(0,0,-l4/2)

	return LA_rotation_matrix_x(joints[1])*
	LA_translation_matrix(0,segment_lengths[2],-segment_lengths[1])*
	LA_rotation_matrix_y(-joints[2])*
	LA_translation_matrix(0,0,-segment_lengths[3]/2)*
	LA_rotation_matrix_z(-joints[3])*
	LA_translation_matrix(0,0,-segment_lengths[3]/2)*
	LA_rotation_matrix_y(-joints[4])*
	LA_translation_matrix(0,0,-segment_lengths[4]/2)*
	LA_rotation_matrix_z(joints[5])*
	LA_translation_matrix(0,0,-segment_lengths[4]/2)
end

@logged function pred_matrix_elbow(joints::Vector{<:Real}, segment_lengths::Vector{<:Real})#::Matrix{<:Real}
	#rx = LA_rotation_matrix_x
	#ry = LA_rotation_matrix_y
	#rz = LA_rotation_matrix_z
	#t  = LA_translation_matrix
	#rx(j1)*t(0,l1,-l2)*ry(-j2)*t(0,0,-l3/2)*rz(-j3)*t(0,0,-l3/2)*r(0,-j4,0)*t(0,0,-l4/2)*rz(j5)*t(0,0,-l4/2)

	return LA_rotation_matrix_x(joints[1])*
	LA_translation_matrix(0,segment_lengths[2],-segment_lengths[1])*
	LA_rotation_matrix_y(-joints[2])*
	LA_translation_matrix(0,0,-segment_lengths[3])
end

end_effector_position(joints::Vector{<:Real}, segment_lengths::Vector{<:Real})::Vector{Real} = Vector{Real}((pred_matrix_end_effector(joints, segment_lengths)*[0,0,0,1])[1:3])

elbow_position(joints::Vector{<:Real}, segment_lengths::Vector{<:Real})::RVect = Vector{Real}((pred_matrix_elbow(joints, segment_lengths)*[0,0,0,1])[1:3])

@logged function distance_from_targets(joints::Vector{<:Real}, segment_lengths::Vector{<:Real}, targets::Vector{<:RVect})::Vector{<:Real}
	funcs = [end_effector_position, elbow_position]
	return [
		sqrt(
			sum(
				[
				 (funcs[i](joints, segment_lengths)[j] - targets[i][j])^2
					for j in 1:3
				]
			)
		)
		for i in 1:2
	]
end

@logged function joint_constraint_fitness(joints::Vector{<:Real}, margin::Real=2, cost::Real=100)::Real #TODO: ADD "MARGIN" TO CALCULATION
	normalize_deg(d) = d > 180 ? d - 360 : d

	for i ∈ 1:5
		if joint_limits[i][1] >= normalize_deg(joints[i])
			return cost*(joint_limits[i][1] - normalize_deg(joints[i]))^2
		elseif normalize_deg(joints[i]) >= joint_limits[i][2]
			return cost*(normalize_deg(joints[i]) - joint_limits[i][2])^2
		end
	end
	return 0
end

@logged function fitness(joints::Vector{<:Real}, target::RVect)::Real
	return distance_from_targets(joints, segment_lengths, [target, [0,0,0]])[1]^2 + joint_constraint_fitness(joints)
end

@logged function fitness_with_elbow(joints::Vector{<:Real}, targets::Vector{<:RVect})::Real
	return sum(abs2, distance_from_targets(joints, segment_lengths, targets)) + joint_constraint_fitness(joints)
end

@END_OF_DEBUG_CATEGORY

@START_OF_DEBUG_CATEGORY "arm"

@logged function find_target(target::RVect, last_joint_configuration::Vector{<:Real}=zeros(5), time_limit::Float64=0.1)::Any
	err_vect = x->[
		error_vector(
			x->end_effector_position(x, segment_lengths),
			x,
			target .→ Float64
		)...,
		joint_constraint_fitness(x)
	]

	return levenberg_marquardt(
		err_vect,
		last_joint_configuration,
		0.0,
		time_limit
	)
end

@logged function find_targets(targets::Vector{<:RVect}, last_joint_configuration::Vector{<:Real}=zeros(5), time_limit::Float64=0.1)::Any
	err_vect = x->[
		error_vector(
			x->end_effector_position(x, segment_lengths),
			x,
			targets[1] .→ Float64
		)...,
		error_vector(
			x->elbow_position(x, segment_lengths),
			x,
			targets[2] .→ Float64
		)...,
		joint_constraint_fitness(x)
	]

	return levenberg_marquardt(
		err_vect,
		last_joint_configuration,
		0.0,
		time_limit
	)
end

@logged function goto_target(target::RVect, time_limit::Float64=0.1)::Nothing
	global current_configuration
	joint_targets = find_target(target, current_configuration, time_limit)
	render_arm(joint_targets, [target], 10)
	current_configuration = joint_targets
	return
end

@logged function goto_targets(targets::Vector{<:RVect}, time_limit::Float64=0.1)::Nothing
	global current_configuration
	joint_targets = find_targets(targets, current_configuration, time_limit)
	render_arm(joint_targets, targets, 10)
	current_configuration = joint_targets
	return
end

@logged function goto_target(target::RVect, current_configuration::Vector{<:Real}, time_limit::Float64=0.1)::Vector{<:Real}
	joint_targets = find_target(target, current_configuration, time_limit)
	render_arm(joint_targets, [target], 10)
	if joint_constraint_fitness(joint_targets) != 0
		@warn "outside joint limits"
	end
	return joint_targets
end

@logged function goto_targets(targets::Vector{<:RVect}, current_configuration::Vector{<:Real}, time_limit::Float64=0.1)::Vector{<:Real}
	joint_targets = find_targets(targets, current_configuration, time_limit)
	render_arm(joint_targets, targets, 10)
	if joint_constraint_fitness(joint_targets) != 0
		@warn "outside joint limits"
	end
	return joint_targets
end

@END_OF_DEBUG_CATEGORY
