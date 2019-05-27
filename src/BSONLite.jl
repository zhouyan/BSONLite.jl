module BSONLite

import Base64: base64encode, base64decode
import Base: Vector, show, string
import Dates: DateTime, UTM, UNIXEPOCH, value

export BSONCodec, JOSNCodec, BSONType, ObjectId, read_bson, write_bson

include("type.jl")
include("decode.jl")
include("encode.jl")
include("read.jl")
include("write.jl")

end
