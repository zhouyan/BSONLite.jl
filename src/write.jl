function write_cstring(io, str::String)
    write(io, string(str), 0x00)
end

function write_elem(io::IO, elem::Element)
    ret = 0
    ret += write(io, bson_code(elem.value), elem.key, 0x00)
    ret += write_value(io, elem.value)
    ret
end

function write_elist(io::IO, elist::Vector{Element})
    ret = 0
    head = position(io)
    ret += write(io, Int32(0))
    [write_elem(io, x) for x in elist]
    ret += write(io, 0x00)
    tail = position(io)
    seek(io, head)
    ret += write(io, Int32(tail - head))
    seek(io, tail)
    ret
end

write_value(io::IO, x::Missing) = 0
write_value(io::IO, x::Nothing) = 0
write_value(io::IO, x::Maxkey) = 0
write_value(io::IO, x::Minkey) = 0
write_value(io::IO, x::Bool) = write(io, x)
write_value(io::IO, x::Int32) = write(io, x)
write_value(io::IO, x::Int64) = write(io, x)
write_value(io::IO, x::Float64) = write(io, x)
write_value(io::IO, x::DateTime) = write(io, value(x) - UNIXEPOCH)
write_value(io::IO, x::BSONSymbol) = write_value(io, x.value)
write_value(io::IO, x::Timestamp) = write(io, x.value)
write_value(io::IO, x::ObjectId) = write(io, x.value)
write_value(io::IO, x::Decimal128) = write(io, x.value)
write_value(io::IO, x::DBPointer) = write_value(io, x.ref) + write_value(io, x.id)
write_value(io::IO, x::Code) = write_value(io, x.code)
write_value(io::IO, x::BSONRegex) = write_cstring(io, x.pattern) + write_cstring(io, x.options)
write_value(io::IO, x::Document) = write_elist(io, x.elist)
write_value(io::IO, x::BSONArray) = write_elist(io, x.elist)

function write_value(io::IO, x::String)
    @assert isvalid(x)
    write(io, Int32(sizeof(x) + 1), x, 0x00)
end

function write_value(io::IO, x::Binary)
    len = Int32(length(x.bytes))
    ret = 0
    if x.subtype == 0x02
        ret += write(io, Int32(len + sizeof(len)), x.subtype, len)
    else
        ret += write(io, len, x.subtype)
    end
    ret += write(io, x.bytes)
    ret
end

function write_value(io::IO, x::CodeWithScope)
    ret = 0
    head = position(io)
    ret += write(io, Int32(0))
    ret += write_value(io, x.code)
    ret += write_value(io, x.scope)
    tail = position(io)
    seek(io, head)
    ret += write(io, Int32(tail - head))
    seek(io, tail)
    ret
end

# high level functions

function write_bson(io::IO, doc; codec::Union{AbstractCodec,Symbol} = :bson)
    codec = codec isa Symbol ? _codec[codec] : codec
    write_value(io, encode(codec, doc))
end

function write_bson(doc; kwargs...)
    io = IOBuffer(read = false, write = true)
    write_bson(io, doc; kwargs...)
    take!(io)
end

write_bson(filename::AbstractString, doc; kwargs...) = open(x -> write_bson(x, doc; kwargs...), filename, "w")
