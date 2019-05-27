# Minimal encoder

encode(codec::MinimalCodec, x) = x

# BSON encoder

encode(codec::BSONCodec, x::BSONType) = x
encode(codec::BSONCodec, x::Symbol) = codec.as_string ? string(x) : BSONSymbol(x)
encode(codec::BSONCodec, x::AbstractVector{UInt8}) = Binary(0x00, x)
encode(codec::BSONCodec, x::Union{Int8,UInt8,Int16,UInt16,UInt32}) = Int32(x)
encode(codec::BSONCodec, x::AbstractFloat) = Float64(x)
encode(codec::BSONCodec, x::Integer) = Int64(x)

function encode(codec::BSONCodec, x::AbstractDict)
    Document([Element(string(k), encode(codec, v)) for (k, v) in x])
end

function encode(codec::BSONCodec, x::AbstractVector)
    BSONArray([Element(string(k - 1), encode(codec, v)) for (k, v) in enumerate(x)])
end
