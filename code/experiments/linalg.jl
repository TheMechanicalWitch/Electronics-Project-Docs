using LinearAlgebra

function LA_translation_matrix(x::Real, y::Real, z::Real)::Matrix{Real}
	[
		1 0 0 x
		0 1 0 y
		0 0 1 z
		0 0 0 1
	]
end

function LA_rotation_matrix_x(θ::Real)::Matrix{Real}
	c = cosd(θ)
	s = sind(θ)

	[
		1 0  0 0
		0 c -s 0
		0 s  c 0
		0 0  0 1
	]
end


function LA_rotation_matrix_y(θ::Real)::Matrix{Real}
	c = cosd(θ)
	s = sind(θ)

	[
		 c 0 s 0
		 0 1 0 0
		-s 0 c 0
		 0 0 0 1
	]
end

function LA_rotation_matrix_z(θ::Real)::Matrix{Real}
	c = cosd(θ)
	s = sind(θ)

	[
		c -s 0 0
		s  c 0 0
		0  0 1 0
		0  0 0 1
	]
end

function LA_rotation_matrix(x::Real, y::Real, z::Real)::Matrix{Real}
	LA_rotation_matrix_z(z) * LA_rotation_matrix_y(y) * LA_rotation_matrix_x(x)
end
