# BSON encoder

bson_encode(x) = x
bson_encode(x::Symbol) = string(x)
bson_encode(x::AbstractVector{UInt8}) = Binary(0x00, x)
bson_encode(x::Union{Int8,UInt8,Int16,UInt16,Int32,UInt32}) = Int32(x)
bson_encode(x::Union{AbstractFloat}) = Float64(x)
bson_encode(x::Union{Integer}) = Int64(x)
bson_encode(x::AbstractDict) = Document([Element(Symbol(k), bson_encode(v)) for (k, v) in x])
bson_encode(x::AbstractVector) = BSONArray([Element(Symbol(k - 1), bson_encode(v)) for (k, v) in enumerate(x)])
