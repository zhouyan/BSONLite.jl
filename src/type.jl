struct Element
    key::String
    value::Any
end

struct BSONSymbol
    value::String
end

struct BSONDate
    value::Int64
end

struct Document
    elements::Vector{Element}
end

struct BSONArray
    elements::Vector{Element}
end

struct Binary
    subtype::UInt8
    bytes::Vector{UInt8}
end

struct ObjectId
    value::Vector{UInt8}

    # TODO default constructor

    function ObjectId(bytes::Vector{UInt8})
        @assert length(bytes) == 12
        new(bytes)
    end
end

ObjectId(oid::AbstractString) = ObjectId(hex2bytes(oid))

function show(io::IO, oid::ObjectId)
    write(io, "ObjectId(")
    write(io, bytes2hex(oid.value))
    write(io, ")")
end

struct Decimal128
    value::Vector{UInt8} # 16 bytes

    function Decimal128()
        new(fill(UInt8, 16))
    end

    function Decimal128(bytes::Vector{UInt8})
        @assert length(bytes) == 16
        new(bytes)
    end
end

struct BSONRegex
    pattern::String
    options::String
end

struct DBPointer
    ref::String
    id::ObjectId
end

struct Code
    code::String
end

struct CodeWithScope
    code::String
    scope::Document
end

struct Timestamp
    value::UInt64
end

struct Maxkey end
struct Minkey end

const maxkey = Maxkey()
const minkey = Minkey()

const bson_type = Dict(
                        0x01 => Float64,
                        0x02 => String,
                        0x03 => Document,
                        0x04 => BSONArray,
                        0x05 => Binary,
                        0x06 => Missing, # undefined
                        0x07 => ObjectId,
                        0x08 => Bool,
                        0x09 => BSONDate,
                        0x0A => Nothing, # null
                        0x0B => BSONRegex,
                        0x0C => DBPointer,
                        0x0D => Code,
                        0x0E => BSONSymbol,
                        0x0F => CodeWithScope,
                        0x10 => Int32,
                        0x11 => Timestamp,
                        0x12 => Int64,
                        0x13 => Decimal128,
                        0x7F => Maxkey,
                        0xFF => Minkey,
                       )

for (k, v) in bson_type
    @eval bson_code(::$v) = $k
end
