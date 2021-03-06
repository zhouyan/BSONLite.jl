abstract type AbstractBSONCodec end

struct MinimalCodec <: AbstractBSONCodec end

struct BSONCodec <: AbstractBSONCodec
    dicttype::Type
    as_symbol::Bool
    as_string::Bool
end

function BSONCodec(dicttype = Dict; as_symbol = true, as_string = true)
    BSONCodec(dicttype, as_symbol, as_string)
end

struct JSONCodec <: AbstractBSONCodec
    dicttype::Type
    as_symbol::Bool
    as_string::Bool
end

function JSONCodec(dicttype = Dict; as_symbol = true, as_string = true)
    JSONCodec(dicttype, as_symbol, as_string)
end

const _codec = Dict(
                    :minimal => MinimalCodec(),
                    :bson => BSONCodec(),
                    :json => JSONCodec()
                   )

struct Element
    key::String
    value::Any

    function Element(k::AbstractString, v)
        ('\0' in k) && throw(ArgumentError("Element key cannot have embbeded null"))
        new(k, v)
    end
end

struct Maxkey end
struct Minkey end

const maxkey = Maxkey()
const minkey = Minkey()

struct ObjectId
    value::String

    function ObjectId(bytes::Vector{UInt8})
        length(bytes) == 12 || throw(ArgumentError("ObjectId buffer shall be 12 bytes"))
        new(String(bytes))
    end
end

function _generate_oid_time(buf::Vector{UInt8})
    io = IOBuffer()
    write(io, hton(UInt32(div(value(now(UTC)) - UNIXEPOCH, 1000))))
    append!(buf, take!(io))
end

function _generate_oid_counter(buf::Vector{UInt8})
    global _oid_context

    counter = UInt32(_oid_context[:counter] + 1)
    _oid_context[:counter] = counter

    io = IOBuffer()
    write(io, hton(counter))
    append!(buf, take!(io)[2:end])
end

function ObjectId()

    ret = Vector{UInt8}()
    sizehint!(ret, 12)
    _generate_oid_time(ret)
    append!(ret, _oid_context[:rand])
    _generate_oid_counter(ret)

    ObjectId(ret)
end

ObjectId(str::AbstractString) = ObjectId(hex2bytes(str))

string(oid::ObjectId) = bytes2hex(Vector{UInt8}(oid))

show(io::IO, oid::ObjectId) = write(io, "ObjectId($(string(oid)))")

Vector{UInt8}(oid::ObjectId) = Vector{UInt8}(oid.value)

struct Binary
    subtype::UInt8
    bytes::Vector{UInt8}

    function Binary(t::UInt8, b::Vector{UInt8})
        t <= 0x05 || t >= 0x80 || throw(ArgumentError("Invalid Binary subtype $t"))
        new(t, b)
    end
end

struct BSONSymbol
    value::String
end

struct Timestamp
    value::UInt64
end

struct Decimal128
    value::UInt128
end

struct BSONRegex
    pattern::String
    options::String

    function BSONRegex(p::AbstractString, o::AbstractString)
        ('\0' in p) && throw(ArgumentError("BSON regex pattern cannot have embbeded null"))
        ('\0' in o) && throw(ArgumentError("BSON regex options cannot have embbeded null"))
        new(p, o)
    end
end

struct DBPointer
    ref::String
    id::ObjectId
end

struct Document
    elist::Vector{Element}
end

function getindex(doc::Document, key::AbstractString)
    for kv in doc.elist
        if kv.key == key
            return kv.value
        end
    end
    throw(KeyError("$key not found"))
end

struct BSONArray
    elist::Vector{Element}
end

getindex(doc::Document, key::Integer) = doc.elist[key].value

struct Code
    code::String
end

struct CodeWithScope
    code::String
    scope::Document
end

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

const BSONType = Union{
                       Float64,
                       String,
                       Document,
                       BSONArray,
                       Binary,
                       Missing, # undefined
                       ObjectId,
                       Bool,
                       DateTime,
                       Nothing, # null
                       BSONRegex,
                       DBPointer,
                       Code,
                       BSONSymbol,
                       CodeWithScope,
                       Int32,
                       Timestamp,
                       Int64,
                       Decimal128,
                       Maxkey,
                       Minkey,
                      }
