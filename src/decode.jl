decode_key(codec, k::String) = k

# Minimal decoder

decode(codec::MinimalCodec, x::BSONType) = x

# Default BSON decoder

decode_key(codec::BSONCodec, k::String) = codec.as_symbol ? Symbol(k) : k

decode(codec::BSONCodec, x::BSONType) = x
decode(codec::BSONCodec, x::Binary) = x.subtype == 0x00 ? x.bytes : x
decode(codec::BSONCodec, x::BSONArray) = [decode(codec, elem.value) for elem in x.elist]

function decode(codec::BSONCodec, x::Document)
    codec.dicttype(decode_key(codec, elem.key) => decode(codec, elem.value) for elem in x.elist)
end

# Canonical Extended JSON decoder

decode_key(codec::JSONCodec, k::String) = codec.as_symbol ? Symbol(k) : k

typekey(codec::JSONCodec, t) = decode_key(codec, "\$t")

decode(codec::JSONCodec, x::BSONType) = x
decode(codec::JSONCodec, x::Maxkey) = codec.dicttype(typekey(codec, "maxKey") => 1)
decode(codec::JSONCodec, x::Minkey) = codec.dicttype(typekey(codec, "minKey") => 1)
decode(codec::JSONCodec, x::Missing) = codec.dicttype(typekey(codec, "undefined") => true)
decode(codec::JSONCodec, x::ObjectId) = codec.dicttype(typekey(codec, "oid") => bytes2hex(Vector{UInt8}(x)))
decode(codec::JSONCodec, x::DateTime) = codec.dicttype(typekey(codec, "date" => decode(codec, value(x) - UNIXEPOCH)))
decode(codec::JSONCodec, x::BSONSymbol) = codec.dicttype(typekey(codec, "symbol") => x.value)
decode(codec::JSONCodec, x::Int32) = codec.dicttype(typekey(codec, "numberInt") => string(x))
decode(codec::JSONCodec, x::Int64) = codec.dicttype(typekey(codec, "numberLong") => string(x))
decode(codec::JSONCodec, x::Code) = codec.dicttype(typekey(codec, "code") => x.code)
decode(codec::JSONCodec, x::BSONArray) = [decode(codec, elem.value) for elem in x.elist]

function decode(codec::JSONCodec, x::Document)
    codec.dicttype(decode_key(codec, elem.key) => decode(codec, elem.value) for elem in x.elist)
end

function decode(codec::JSONCodec, x::DBPointer)
    codec.dicttype(typekey(codec, "dbPointer") =>
                   codec.dicttype(typekey(codec, "ref") => x.ref,
                                  typekey(codec, "id") => decode(codec, x.id)))
end

function decode(codec::JSONCodec, x::CodeWithScope)
    codec.dicttype(typekey(codec, "code") => x.code,
                   typekey(codec, "scope") => decode(codec, x.scope))
end

function decode(codec::JSONCodec, x::BSONRegex)
    codec.dicttype(typekey(codec, "regularExpression") =>
                   codec.dicttype(decode_key(codec, "pattern") => x.pattern,
                                  decode_key(codec, "options") => x.options))
end

function decode(codec::JSONCodec, x::Binary)
    codec.dicttype(typekey(codec, "binary") =>
                   codec.dicttype(decode_key(codec, "base64") =>
                                  base64encode(x.bytes),
                                  decode_key(codec, "subType") =>
                                  string(x.subtype, base=16, pad=2)))
end

function decode(codec::JSONCodec, x::Timestamp)
    codec.dicttype(typekey(codec, "timestamp") =>
                   codec.dicttype(decode_key(codec, "t") => UInt32(x.value >> 32),
                                  decode_key(codec, "i") => UInt32(x.value & typemax(UInt32))))
end

function decode(codec::JSONCodec, x::Float64)
    if isfinite(x)
        v = string(x)
    elseif isnan(x)
        v = "NaN"
    elseif x > 0
        v = "Infinity"
    else
        v = "-Infinity"
    end
    codec.dicttype(typekey(codec, "numberDouble") => v)
end
