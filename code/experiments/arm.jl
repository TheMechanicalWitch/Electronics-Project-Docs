
@START_OF_DEBUG_CATEGORY "arm"

segment_lengths = [33, 87, 225, 272]

@logged function base(x::Real, y::Real, z::Real)
	shoulders=50
	union(
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
	"""
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

@logged function render_arm(joints::Vector{<:Real}, resolution::Int=30)::Nothing
	write_out(
		set_rendering_parameter("fn", resolution),
		base(50,100,130),
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
		)
	)
end

@logged function animate_arm(funs::Vector{Function}, steps::Real, Δstep::Real, Δtime::Real, resolution::Int=10)::Nothing
	for s ∈ 0:Δstep:steps
		println(s)
		render_arm(
			[fun(s) for fun ∈ funs],
			resolution,
		)
		sleep(Δtime)
	end
end

@logged function pred_matrix_end_effector(joints::Vector{<:Real}, segment_lengths::Vector{<:Real})#::Matrix{<:Real}
	#rx = LA_rotation_matrix_x
	#ry = LA_rotation_matrix_y
	#rz = LA_rotation_matrix_z
	#t  = LA_translation_matrix
	#rx(j1)*t(0,l1,-l2)*ry(-j2)*t(0,0,-l3/2)*rz(-j3)*t(0,0,-l3/2)*r(0,-j4,0)*t(0,0,-l4/2)*rz(j5)*t(0,0,-l4/2)

	LA_rotation_matrix_x(joints[1])*
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

	LA_rotation_matrix_x(joints[1])*
	LA_translation_matrix(0,segment_lengths[2],-segment_lengths[1])*
	LA_rotation_matrix_y(-joints[2])*
	LA_translation_matrix(0,0,-segment_lengths[3])
end

end_effector_position(joints::Vector{<:Real}, segment_lengths::Vector{<:Real})::Vector{Real} = Vector{Real}((pred_matrix_end_effector(joints, segment_lengths)*[0,0,0,1])[1:3])

elbow_position(joints::Vector{<:Real}, segment_lengths::Vector{<:Real})::RVect = Vector{Real}((pred_matrix_elbow(joints, segment_lengths)*[0,0,0,1])[1:3])

@logged function distance_from_targets(joints::Vector{<:Real}, segment_lengths::Vector{<:Real}, targets::Vector{<:RVect})::Vector{Real}
	funcs = [end_effector_position, elbow_position]
	[
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

using Optim

@logged function fitness(joints::Vector{<:Real}, target::RVect)::Real
	distance_from_targets(joints, segment_lengths, [target, [0,0,0]])[1]^2
end

@logged function fitness_with_elbow(joints::Vector{<:Real}, targets::Vector{<:RVect})<:Real
	sum(abs2, distance_from_targets(joints, segment_lengths, targets))
end

@logged function follow_target(target::RVect)::Any
	[Optim.minimizer(optimize(x->fitness([x..., 0], target), zeros(4)))..., 0] → render_arm
end

@logged function follow_targets(targets::Vector{<:RVect})::Any
	[Optim.minimizer(optimize(x->fitness_with_elbow([x..., 0], targets), zeros(4)))..., 0] → render_arm
end

@END_OF_DEBUG_CATEGORY
