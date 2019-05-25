module BSONLite

import Base64: base64encode, base64decode
import Base: Vector
import DataStructures: OrderedDict
import Dates: DateTime, UTM, UNIXEPOCH, UTC, now, value

export ObjectId, read_bson, write_bson

include("type.jl")
include("decode.jl")
include("encode.jl")
include("read.jl")
include("write.jl")

end
