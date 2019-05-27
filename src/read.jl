read_cstring(io) = String(readuntil(io, 0x00))

function read_elem(io::IO)
    T = bson_type[read(io, UInt8)]
    Element(read_cstring(io), read_value(io, T))
end

function read_elist(io::IO)
    head = position(io)
    len = read(io, Int32)
    @assert len >= 0
    tail = head + len - 1
    ret = Element[]
    while position(io) < tail
        push!(ret, read_elem(io))
    end
    @assert position(io) == tail
    @assert read(io, UInt8) == 0x00
    ret
end

read_value(io::IO, ::Type{Missing}) = missing
read_value(io::IO, ::Type{Nothing}) = nothing
read_value(io::IO, ::Type{Maxkey}) = maxkey
read_value(io::IO, ::Type{Minkey}) = minkey
read_value(io::IO, ::Type{Bool}) = Bool(read(io, UInt8))
read_value(io::IO, ::Type{Int32}) = read(io, Int32)
read_value(io::IO, ::Type{Int64}) = read(io, Int64)
read_value(io::IO, ::Type{Float64}) = read(io, Float64)
read_value(io::IO, ::Type{DateTime}) = DateTime(UTM(UNIXEPOCH + read(io, Int64)))
read_value(io::IO, ::Type{BSONSymbol}) = BSONSymbol(read_value(io, String))
read_value(io::IO, ::Type{Timestamp}) = Timestamp(read(io, UInt64))
read_value(io::IO, ::Type{ObjectId}) = ObjectId(read(io, 12))
read_value(io::IO, ::Type{Decimal128}) = Decimal128(read(io, UInt128))
read_value(io::IO, ::Type{DBPointer}) = DBPointer(read_value(io, String), read_value(io, ObjectId))
read_value(io::IO, ::Type{Code}) = Code(read_value(io, String))
read_value(io::IO, ::Type{BSONRegex}) = BSONRegex(read_cstring(io), read_cstring(io))
read_value(io::IO, ::Type{Document}) = Document(read_elist(io))
read_value(io::IO, ::Type{BSONArray})= BSONArray(read_elist(io))

function read_value(io, ::Type{String})
    len = read(io, Int32)
    @assert len >= 0
    ret = String(read(io, len - 1))
    @assert isvalid(ret)
    @assert read(io, UInt8) == 0x00
    ret
end

function read_value(io::IO, ::Type{Binary})
    len = read(io, Int32)
    @assert len >= 0
    subtype = read(io, UInt8)
    if subtype == 0x02
        len = read(io, Int32)
        @assert len >= 0
    end
    ret = Binary(subtype, read(io, len))
end

function read_value(io::IO, ::Type{CodeWithScope})
    head = position(io)
    len = read(io, Int32)
    @assert len >= 0
    tail = head + len
    code = read_value(io, String)
    doc = read_value(io, Document)
    @assert position(io) == tail
    CodeWithScope(code, doc)
end

# high level functions

function read_bson(io::IO; codec::Union{AbstractCodec,Symbol} = :bson)
    codec = codec isa Symbol ? _codec[codec] : codec
    raw = read_value(io, Document)
    @assert(eof(io))
    decode(codec, raw)
end

read_bson(buf::AbstractVector{UInt8}; kwargs...) = read_bson(IOBuffer(buf, read = true, write = false); kwargs...)

read_bson(filename::AbstractString; kwargs...) = open(x -> read_bson(x; kwargs...), filename, "r")
