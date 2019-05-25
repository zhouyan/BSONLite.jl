module BSONLite

import Base: Vector
import Base64: base64encode, base64decode
import Dates: DateTime, UTM, UNIXEPOCH, UTC, now, value
import Random: rand

export ObjectId, read_bson, write_bson

include("type.jl")
include("decode.jl")
include("encode.jl")
include("read.jl")
include("write.jl")

end
