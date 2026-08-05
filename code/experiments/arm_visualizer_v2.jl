struct ArmLink
	trans_mat::Matrix{Num}
	name::Union{String}
	children::Vector{ArmLink}
end

Base.:*(a::ArmLink, b::ArmLink)::ArmLink = ArmLink(a.trans_mat * b.trans_mat, b.name, b.children)

@logged function global_trans_mats(link::ArmLink)::Vector{Pair{String, Matrix{Num}}}
	children::Vector{Pair{String, Matrix{Num}}} = []
	if !isempty(link.children)
		children = ∪([chain_trans_mats(link * l) for l ∈ link.children]...)
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
	arm_chains(link, [String[]])
end

@logged function arm_cad_model(link::ArmLink, trans_mats::Dict{String, Matrix{Num}}, chains::Vector{Vector{String}})::Function
	return (parameters::Dict{Num, <:Number}, tentacle_funs::Vector{<:Function})->union(
		[
			tentacle_funs[i](
				[
					(substitute(trans_mats[node], parameters) * [0,0,0,1])[1:3] .→ Float64
					for node ∈ chains[i]
				]
			)
			for i ∈ 1:length(chains)
		]...
	)::String
end

@logged function arm_cad_model(arm::ArmLink)::Function
	return arm_cad_model(arm, Dict(global_trans_mats(arm)), arm_chains(arm))
end
