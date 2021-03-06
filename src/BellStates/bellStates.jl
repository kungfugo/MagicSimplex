function createRandomCoordStates(nSamples, d, object="magicSimplex", precision=10, roundToSteps::Int=0, nTriesMax=10000000)::Array{CoordState}
    # Creates an array of uniformly distributed random CoordStates
    # 'object' parameter allows the specification 'enclosurePolytope' to restrict created statesto the enclosure polytope
    productParams = Array{CoordState}(undef, 0)
    nFound = 0

    if object != "enclosurePolytope"

        while (nFound < nSamples)

            # only parameters which build a convex sum relevant
            c = vec(rand(Uniform(0, 1), 1, (d^2 - 1)))

            # If wanted, move random point to nearest step-point
            if roundToSteps > 0
                c = round.(roundToSteps * c) * 1 // roundToSteps
            end

            c = round.(c, digits=precision)

            if sum(c) <= 1
                push!(c, round(1 - sum(c), digits=precision))
                paramState = CoordState(c, "UNKNOWN")
                push!(productParams, paramState)
                nFound += 1
            end

        end

    else

        while (nFound < nSamples)

            c = vec(rand(Uniform(0, 1 / d), 1, (d^2 - 1)))

            if roundToSteps > 0
                c = round.(roundToSteps * d * c) * 1 // (roundToSteps * d)
            end

            c = round.(c, digits=precision)

            if (1 - 1 // d) <= sum(c) <= 1
                push!(c, round(1 - sum(c), digits=precision))
                paramState = CoordState(c, "UNKNOWN")
                push!(productParams, paramState)
                nFound += 1
            end

        end

    end

    return productParams

end

function createBipartiteMaxEntangled(d)
    # Creates maximally entangled pure state of a bipartite system of dimension d*d
    maxE = proj(max_entangled(d * d))
    return maxE

end

function weylOperator(d, k, l)
    # calculated the (d,d) dimensional matrix representation of Weyl operator
    weylKetBra = zeros(Complex{Float64}, d, d)

    for j in (0:d-1)
        #convention: ket(j+1,d) is j-th basis element \ket{j}
        weylKetBra = weylKetBra + exp((2 / d * ?? * im) * j * k) * ketbra(j + 1, mod(j + l, d) + 1, d, d)
    end

    return weylKetBra

end

function getIntertwiner(d, k, l)
    w = weylOperator(d, k, l)
    Id = I(d)
    return w ??? Id
end

function weylTrf(d, ??, k, l)

    if size(??)[1] != d * d
        throw("?? is not a product state of bipartite system of sub-systems with
        equal dimension")
    end
    W = getIntertwiner(d, k, l)

    ??Trf = W * ?? * W'

    return ??Trf

end

function createBasisStateOperators(d, bellStateOperator, precision)

    mIt = Iterators.product(fill(0:(d-1), 2)...)

    basisStates = Array{
        Tuple{
            Int,
            Tuple{Int,Int},
            Array{Complex{Float64},2}
        },
        1}(undef, 0)

    for (index, value) in enumerate(mIt)

        k = value[1]
        l = value[2]

        #Weyl transformation to basis states
        P_kl = Hermitian(round.(weylTrf(d, bellStateOperator, k, l), digits=precision))

        push!(basisStates, (index, value, P_kl))

    end
    return basisStates
end

function createStandardIndexBasis(d, precision)::StandardBasis
    maxEntangled = createBipartiteMaxEntangled(d)
    standardBasis = StandardBasis(createBasisStateOperators(d, maxEntangled, precision))
    return standardBasis
end

#Create state including its density matrix 
function createDensityState(coordState::CoordState, indexBasis::StandardBasis)::DensityState

    basisOps = map(x -> x[3], indexBasis.basis)
    densityState = DensityState(
        coordState.coords,
        Hermitian(myMulti(coordState.coords, basisOps)),
        coordState.eClass)

    return densityState

end

# Weyl Basis for the d*d - dim Matrix space
function createWeylOperatorBasis(d)::Vector{Array{Complex{Float64},2}}
    weylOperatorBasis = []
    for i in (0:(d-1))
        for j in (0:(d-1))
            push!(weylOperatorBasis, weylOperator(d, i, j))
        end
    end

    return weylOperatorBasis

end

# Tensor product Weyl basis for the d^2*d^2 - dim Matrix space
function createBipartiteWeylOpereatorBasis(d)::Vector{Array{Complex{Float64},2}}

    weylOperatorBasis = createWeylOperatorBasis(d)

    bipartiteWeylOperatorBasis = []

    for k in weylOperatorBasis
        for l in weylOperatorBasis
            push!(bipartiteWeylOperatorBasis, k ??? l)
        end
    end

    return bipartiteWeylOperatorBasis

end
