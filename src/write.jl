write_cstring(io, str::String) = write(io, string(str), 0x00)

function write_elem(io::IO, elem::Element)
    write(io, bson_code(elem.value), elem.key, 0x00)
    write_value(io, elem.value)
end

function write_elist(io::IO, elist::Vector{Element})
    head = position(io)
    write(io, Int32(0))
    [write_elem(io, x) for x in elist]
    write(io, 0x00)
    tail = position(io)
    seek(io, head)
    write(io, Int32(tail - head))
    seek(io, tail)
end

write_value(io::IO, x::Missing) = nothing
write_value(io::IO, x::Nothing) = nothing
write_value(io::IO, x::Maxkey) = nothing
write_value(io::IO, x::Minkey) = nothing
write_value(io::IO, x::Bool) = write(io, x)
write_value(io::IO, x::Int32) = write(io, x)
write_value(io::IO, x::Int64) = write(io, x)
write_value(io::IO, x::Float64) = write(io, x)
write_value(io::IO, x::DateTime) = write(io, value(x) - UNIXEPOCH)
write_value(io::IO, x::String) = write(io, Int32(sizeof(x) + 1), x, 0x00)
write_value(io::IO, x::BSONSymbol) = write_value(io, x.value)
write_value(io::IO, x::Timestamp) = write(io, x.value)
write_value(io::IO, x::ObjectId) = write(io, x.value)
write_value(io::IO, x::Decimal128) = write(io, x.value)
write_value(io::IO, x::DBPointer) = write_value(io, x.ref), write_value(io, x.id)
write_value(io::IO, x::Code) = write_value(io, x.code)
write_value(io::IO, x::BSONRegex) = write_cstring(io, x.pattern), write_cstring(io, x.options)
write_value(io::IO, x::Document) = write_elist(io, x.elist)
write_value(io::IO, x::BSONArray) = write_elist(io, x.elist)

function write_value(io::IO, x::Binary)
    len = Int32(length(x.bytes))
    if x.subtype == 0x02
        write(io, Int32(len + sizeof(len)))
        write(io, x.subtype)
        write(io, len)
    else
        write(io, len)
        write(io, x.subtype)
    end
    write(io, x.bytes)
end

function write_value(io::IO, x::CodeWithScope)
    head = position(io)
    write(io, Int32(0))
    write_value(io, x.code)
    write_value(io, x.scope)
    tail = position(io)
    seek(io, head)
    write(io, Int32(tail - head))
    seek(io, tail)
end

# high level functions

function write_bson(io::IO, doc; codec::Union{Function,Symbol} = bson_encode)
    if codec isa Symbol
        encode = eval(Symbol("$(codec)_encode"))
    else
        encode = codec
    end
    write_value(io, encode(doc))
    io
end

write_bson(doc; kwargs...) = take!(write_bson(IOBuffer(read = false, write = true), doc; kwargs...))

write_bson(file::AbstractString, doc; kwargs...) = open(x -> write_bson(doc; kwargs...), "w")
