#requires basic.jl

function base(x::Real, y::Real, z::Real)
	union(
		translate((-x/2, -y, -z),
			cube(x, y, z)
		),
		difference(
			translate((0, -3.5, 6),
				resize((6,6,8),
					sphere(10)
				)
			),
			translate((2, -4.5, 6),
				sphere(1)
			),
			translate((2, -2.5, 6),
				sphere(1)
			)
		)
	)
end

function arm(joints::Vector{<:Real}, segment_lengths::Vector{<:Real})::String
	#{{{ DENNA KOD BÖR SKRIVAS OM I JULIA TILL EN REKURSIVT GENERERAD SÅDAN (OM MAN VILL GÖRA DET PÅ RÄTT SÄTT)
	"""
rotate([0,90,0])
    cylinder(2,0.8,0.8,center=true);
rotate([$(joints[1]),0,0])
union(){
    translate([-0.5,-0.0,-0.5])
        cube([1,$(segment_lengths[1]),1]);
    translate([0,$(segment_lengths[1]),0])
        union(){
            rotate([90,0,0])
                cylinder(2,0.8,0.8,center=true);
            rotate([0,-$(joints[2]),0])
            union(){
                translate([-0.5,-0.5,-$(segment_lengths[2]/2)])
                    cube([1,1,$(segment_lengths[2]/2)]);
                translate([0,0,-$(segment_lengths[2]/2)])
                    union(){
                        rotate([0,0,0])
                            cylinder(2,0.8,0.8,center=true);
                        rotate([0,0,-$(joints[3])])
                        union(){
                            translate([-0.5,-0.5,-$(segment_lengths[2]/2)])
                                cube([1,1,$(segment_lengths[2]/2)]);
                            translate([0,0,-$(segment_lengths[2]/2)])
                                union(){
                                    rotate([90,0,0])
                                        cylinder(2,1,1,center=true);
                                    rotate([0,-$(joints[4]),0])
                                    union(){
                                        translate([-0.5,-0.5,-$(segment_lengths[3]/2)])
                                            cube([1,1,$(segment_lengths[3]/2)]);
                                        translate([0,0,-$(segment_lengths[3]/2)])
                                            union(){
                                                rotate([0,0,0])
                                                    cylinder(2,1,1,center=true);
                                                rotate([0,0,$(joints[5])])
                                                union(){
                                                    translate([-0.5,-0.5,-$(segment_lengths[3]/2)])
                                                        cube([1,1,$(segment_lengths[3]/2)]);
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

function render_arm(joints::Vector{<:Real}, resolution::Int=30)::Nothing
	write_out(
		set_rendering_parameter("fn", resolution),
		base(3,7,13),
		arm(joints,[3,10,10]),
		translate((0,-7,0),
			mirror((0,1,0),
				arm(joints,[3,10,10])
			)
		)
	)
end

function animate_arm(funs::Vector{<:Function}, steps::Real, Δstep::Real, Δtime::Real, resolution::Int=10)::Nothing
	for s ∈ 0:Δstep:steps
		println(s)
		render_arm(
			[fun(s) for fun ∈ funs],
			resolution,
		)
		sleep(Δtime)
	end
end
