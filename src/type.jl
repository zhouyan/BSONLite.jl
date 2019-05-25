struct Element
    key::String
    value::Any
end

struct BSONSymbol
    value::String
end

struct Document
    elements::Vector{Element}
end

struct BSONArray
    elements::Vector{Element}
end

struct ObjectId
    value::String

    function ObjectId(bytes::Vector{UInt8})
        @assert length(bytes) == 12
        new(String(bytes))
    end
end

ObjectId(str::AbstractString) = ObjectId(hex2bytes(str))

string(oid::ObjectId) = bytes2hex(Vector{UInt8}(oid))

show(io::IO, oid::ObjectId) = write(io, "ObjectId($(string(oid))")

Vector{UInt8}(oid::ObjectId) = Vector{UInt8}(oid.value)

struct Decimal128
    lower::UInt64
    upper::UInt64
end

struct Binary
    subtype::UInt8
    bytes::Vector{UInt8}

    function Binary(t::UInt8, b::Vector{UInt8})
        @assert t <= 0x05 || t >= 0x80
        new(t, b)
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
                        0x09 => DateTime,
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
