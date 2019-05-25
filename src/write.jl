function write_cstring(io, str::String)
    if isempty(str)
        write(io, 0x00)
    elseif str[end] == '\0'
        @assert '\0' ∉ str[1:(end - 1)]
        write(io, str)
    else
        @assert '\0' ∉ str
        write(io, str)
        write(io, 0x00)
    end
end

function write_element(io::IO, elem::Element)
    write(io, bson_code(elem.value))
    write_cstring(io, elem.key)
    write_value(io, elem.value)
end

function write_document(io::IO, elist::Vector{Element})
    head = position(io)
    write(io, Int32(0))

    for x in elist
        write_element(io, x)
    end

    write(io, 0x00)
    tail = position(io)
    seek(io, head)
    write(io, Int32(tail - head))
    seek(io, tail)
end

write_value(io::IO, x::Missing) = nothing
write_value(io::IO, x::Nothing) = nothing
write_value(io::IO, x::Minkey) = nothing
write_value(io::IO, x::Maxkey) = nothing
write_value(io::IO, x::Int32) = write(io, x)
write_value(io::IO, x::Int64) = write(io, x)
write_value(io::IO, x::Float64) = write(io, x)
write_value(io::IO, x::BSONDate) = write(io, x.value)
write_value(io::IO, x::BSONSymbol) = write_value(io, x.value)
write_value(io::IO, x::Timestamp) = write(io, x.value)
write_value(io::IO, x::ObjectId) = write(io, hex2bytes(x.value))
write_value(io::IO, x::Decimal128) = write(io, x.lower), write(io.upper)
write_value(io::IO, x::DBPointer) = write_value(io, x.ref), write_value(io, x.id)
write_value(io::IO, x::Code) = write_value(io, x.code)
write_value(io::IO, x::BSONRegex) = write_cstring(io, x.pattern), write_cstring(io, x.options)
write_value(io::IO, x::Document) = write_document(io, x.elements)
write_value(io::IO, x::BSONArray) = write_document(io, x.elements)
write_value(io::IO, x::Bool) = write(io, x ? 0x01 : 0x00)

function write_value(io::IO, x::String)
    write(io, Int32(sizeof(x) + 1))
    write(io, x)
    write(io, 0x00)
end

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

function write_bson(io::IO, doc; codec::Union{Function,Symbol} = bson_encode, kwargs...)
    if codec isa Symbol
        encode = eval(Symbol("$(codec)_encode"))
    else
        encode = codec
    end
    write_value(io, encode(doc; kwargs...))
    nothing
end

function write_bson(doc; kwargs...)
    io = IOBuffer()
    write_bson(io, doc; kwargs...)
    take!(io)
end
