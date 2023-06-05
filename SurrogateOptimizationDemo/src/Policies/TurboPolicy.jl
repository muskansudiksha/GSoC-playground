"""
A policy from TuRBO algorithm for deciding where to sample next.

TODO: if we cannot implement it generally for all types of local surrogates,
     we can consider TuRBO{T} and constraint T to some abstract type
"""
mutable struct TurboPolicy <: Policy
    # for each TR use candidate_size many points to approximate a sample function
    # drawn from the posterior (Thompson sample)
    # default from the paper: min(100 * dimension, 5000)
    candidate_size::Int
end

# TODO
#
# function TurboPolicy(dimension, candidate_size = nothing)
#     # default value from the TuRBO paper
#     candidate_size_default = min(100 * dimension, 5000)
#     candidate_size = candidate_size == nothing ? candidate_size_default : candidate_size
#     TurboPolicy(candidate_size)
# end

# note: policies are callable objects
function (policy::TurboPolicy)(dcm::Turbo)
    next_points = Vector{Float64}(undef, dcm.batch_size)
    for i 1:dcm.batch_size
        #    sample a function from the posterior for each TR (discretized version on
        #    candidate_size many points generated by modified Sobol sequence)
        combined_xs = []
        combined_ys = []
        for j in 1:dcm.n_surrogates
            tr_xs = turbo_policy_seq(dcm, policy.candidate_size, j)
            # calculate approximation function values at tr_xs via the j-th surrogate
            tr_ys = (dcm.surrogates[j]).(tr_xs)
            append!(combined_xs, tr_xs)
            append!(combined_ys, tr_ys)
        end
        next_points[i] = combined_xs[argmax(combined_ys)]
    end
    next_points
end

# TODO: modified Sobol sequence at the intersection of [0,1]^d and j-th TR
function turbo_policy_seq(dcm::Turbo, candidate_size, j)
    xs = []
    # following the construction from the paper: supplement material part D; and python implementation
    prob_of_perturbation = min(20.0 / dcm.dimension, 1)
    # TODO: scrambled Sobol?
    for pertubation in ScaledSobolIterator(dcm.trs[j].lb , dcm.trs[j].ub, candidate_size)
        x = dcm.trs[j].center .* ones(dsm.dimension)
        # TODO: use seed for reproducibility?
        # each index between 1:dsm.dimension is chosen with prob. prob_of_perturbation
        inds = [i for i in 1:dsm.dimension if rand() <= prob_of_perturbation ]
        x[inds] = perturbations[inds]
        push!(xs, x)
    end
    xs
end
