@START_OF_DEBUG_CATEGORY "kinematics"

using DataStructures

struct ArmLink
	trans_mat::Matrix{Num}
	name::Union{String}
	children::Vector{ArmLink}
end

ArmParameters = OrderedDict{Num, Float64}

Base.:*(a::ArmLink, b::ArmLink)::ArmLink = ArmLink(a.trans_mat * b.trans_mat, b.name, b.children)

Base.:∪(A::ArmParameters, B::ArmParameters)::ArmParameters = ArmParameters(collect(A) ∪ collect(B))

@logged function global_trans_mats(link::ArmLink)::Vector{Pair{String, Matrix{Num}}}
	children::Vector{Pair{String, Matrix{Num}}} = []
	if !isempty(link.children)
		children = ∪([global_trans_mats(link * l) for l ∈ link.children]...)
	end
	return [link.name => link.trans_mat] ∪ children
end

@logged function arm_chains(link::ArmLink, chains::Vector{Vector{String}})::Any
	push!(chains[end], link.name)
	@log chains
	if (link.children → length) == 1
		return arm_chains(link.children[1], chains)
	end
	if (link.children → length) > 1
		for child ∈ link.children
			push!(chains, [link.name])
			arm_chains(child, chains)
		end
	end
	return chains
end

@logged function arm_chains(link::ArmLink)::Vector{Vector{String}}
	@ignore link
	return arm_chains(link, [String[]])
end

@logged function get_coordinate(trans_mat::Matrix{Num}, parameters::ArmParameters)
	return (substitute(trans_mat, parameters)*[0,0,0,1])[1:3]
end

@logged function arm_cad_model(link::ArmLink, trans_mats::Dict{String, Matrix{Num}}, chains::Vector{Vector{String}})::Function
	@ignore link
	return (parameters::Dict{Num, Float64}, tentacle_funs::Vector{<:Function})->union(
		[
			tentacle_funs[i](
				[
					get_coordinate(trans_mats[node], parameters)
					for node ∈ chains[i]
				]
			)
			for i ∈ 1:length(chains)
		]...
	)::String
end

@logged function arm_cad_model(arm::ArmLink)::Function
	@ignore arm
	return arm_cad_model(arm, Dict(global_trans_mats(arm)), arm_chains(arm))
end

@logged function dict_to_vect(dict::Dict{Num, <:Real})::Vector{Float64}
	return [
		dict[key] → Float64
		for key ∈ keys(dict)
	]
end

@logged function vect_to_dict(dict::Dict{Num, <:Real}, vect::Vector{Float64})::Dict{String, <:Real}
	return Dict([
		key => vect[i]
		for (i, key) ∈ enumerate(keys(dict))
	])
end

@logged function joint_constraints_error_vector(
	joints::Dict{Num, <:Real},
	joint_limits::Dict{Num, Tuple{<:Real, <:Real}},
	margin::Real=2,
	cost_factor::Real=100,
	cost_exponent::Int64=2
)::Vector{Float64}
	normalize_deg(d) = d > 180 ? d - 360 : d

	err_vect::Vector{Float64} = []

	for joint ∈ keys(joints)
		if joint_limits[joint][1] + margin >= normalize_deg(joints[key])
			push!(err_vect, cost_factor*(joint_limits[joint][1] - normalize_deg(joints[joint]))^cost_exponent)
		elseif normalize_deg(joints[joint]) + margin >= joint_limits[joint][2]
			push!(err_vect, cost_factor*(normalize_deg(joints[joint]) - joint_limits[joint][2])^cost_exponent)
		end
	end

	return err_vect
end

@logged function find_targets(
	targets::Dict{String, <:RVect},
	trans_mats::Dict{String, Matrix{Num}},
	fixed_parameters::Dict{Num, <:Real},
	dynamic_parameters::Dict{Num, Float64},
	joint_constraints_error_vector_function::Union{Nothing, Function}=nothing,
	time_limit::Float64=0.1
)::Dict{Num, <:Real}
	err_vect = params->[
		[
			(get_coordinate(trans_mats[target], params ∪ fixed_parameters) - targets[target]) .→ Float64
			for target ∈ keys(targets)
		]...,
		(joint_constraints_error_vector_function == nothing ? [] : joint_constraints_error_vector_function(params))...
	]

	return levenberg_marquardt(
		err_vect,
		dynamic_parameters,
		0.0,
		time_limit
	)
end

@END_OF_DEBUG_CATEGORY
