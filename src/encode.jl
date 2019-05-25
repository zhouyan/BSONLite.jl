# BSON encoder

bson_encode(x; kwargs...) = x
bson_encode(x::AbstractVector{UInt8}; kwargs...) = Binary(0x00, x)
bson_encode(x::DateTime; kwargs...) = BSONDate(value(x) - UNIXEPOCH)
bson_encode(x::Union{Float32,Float64}) = Float64(x)
bson_encode(x::Union{Int8,UInt8,Int16,UInt16,Int32,UInt32}) = Int32(x)
bson_encode(x::Union{Int64,UInt64}) = Int64(x)

function bson_encode(x::Symbol; as_string = true, kwargs...)
    as_string ? string(x) : BSONSymbol(string(x))
end

function bson_encode(x::AbstractDict; kwargs...)
    Document([Element(string(k), bson_encode(v; kwargs...)) for (k, v) in x])
end

function bson_encode(x::AbstractVector; kwargs...)
    BSONArray([Element(string(k - 1), bson_encode(v; kwargs...)) for (k, v) in enumerate(x)])
end
