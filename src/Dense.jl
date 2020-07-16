using Flux

"""
    Dense(in::Integer, out::Integer)

Create a traditional `Dense` layer with parameters `W` and `b`. Also omega_0

    y = sin.(W * x .+ b)

The input `x` must be a vector of length `in`, or a batch of vectors represented
as an `in × N` matrix. The out `y` will be a vector or batch of length `out`.

# Examples
```jldoctest; setup = :(using Random; Random.seed!(0)); d = Dense(5, 2)
julia> d = SIREN.Dense(5, 2)
SIREN.Dense(5, 2, omega_0=30)

julia> d(rand(5))
2-element Array{Float64,1}:
 -0.19062824191630165
  0.14516176156652455```
"""
struct Dense{F,S,T}
  W::S
  b::T
  omega_0::F
end

function Dense(in::Integer, out::Integer;
               omega_0 = 30, is_first = false)

    W = uniform(out, in)
    if is_first
        W ./= in
    else
        W .*= sqrt(6/in) / omega_0
    end

    return Dense(W, zeros(out), omega_0)
end

Flux.@functor Dense (W, b,)

function (a::Dense)(x::AbstractArray)
  W, b, omega_0 = a.W, a.b, a.omega_0
  sin.(omega_0 * W * x .+ b)
end

function Base.show(io::IO, l::Dense)
  print(io, "SIREN.Dense(", size(l.W, 2), ", ", size(l.W, 1))
  print(io, ", omega_0=", l.omega_0)
  print(io, ")")
end

# Try to avoid hitting generic matmul in some simple cases
# Base's matmul is so slow that it's worth the extra conversion to hit BLAS
(a::Dense{<:Any,W})(x::AbstractArray{T}) where {T <: Union{Float32,Float64}, W <: AbstractArray{T}} =
  invoke(a, Tuple{AbstractArray}, x)

(a::Dense{<:Any,W})(x::AbstractArray{<:AbstractFloat}) where {T <: Union{Float32,Float64}, W <: AbstractArray{T}} =
  a(T.(x))

"""
    outdims(l::Dense, isize)

Calculate the output dimensions given the input dimensions, `isize`.

```julia
m = Dense(10, 5)
outdims(m, (5, 2)) == (5,)
outdims(m, (10,)) == (5,)
```
"""
outdims(l::Dense, isize) = (size(l.W)[1],)
