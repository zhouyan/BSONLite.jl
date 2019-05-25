# BSON encoder

bson_encode(x::BSONType) = x
bson_encode(x::Symbol) = string(x)
bson_encode(x::AbstractVector{UInt8}) = Binary(0x00, x)
bson_encode(x::Union{Int8,UInt8,Int16,UInt16,UInt32}) = Int32(x)
bson_encode(x::AbstractFloat) = Float64(x)
bson_encode(x::Integer) = Int64(x)
bson_encode(x::AbstractDict) = Document([Element(string(k), bson_encode(v)) for (k, v) in x])
bson_encode(x::AbstractVector) = BSONArray([Element(string(k - 1), bson_encode(v)) for (k, v) in enumerate(x)])
