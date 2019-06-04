module BSONLite

import Base64: base64encode, base64decode
import Base: Vector, show, string, getindex
import Dates: DateTime, UTC, UTM, UNIXEPOCH, value, now
import Random: rand

export AbstractBSONCodec, BSONCodec, JSONCodec
export BSONType, Element, ObjectId, Document, Binary, BSONArray
export read_bson, write_bson

const _oid_context = Dict{Symbol,Any}()

function __init__()
    global _oid_context

    io = IOBuffer()
    write(io, rand(UInt64))
    _oid_context[:rand] = take!(io)[1:5]
    _oid_context[:counter] = rand(UInt32)
end

include("type.jl")
include("decode.jl")
include("encode.jl")
include("read.jl")
include("write.jl")

end
