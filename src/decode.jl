# Raw decoder

minimal_decode(x) = x

# Default BSON decoder

bson_decode(x) = x
bson_decode(x::Binary) = x.subtype == 0x00 ? x.bytes : x
bson_decode(x::Document) = Dict(elem.key => bson_decode(elem.value) for elem in x.elements)
bson_decode(x::BSONArray) = [bson_decode(elem.value) for elem in x.elements]

# Canonical Extended JSON decoder

json_decode(x) = x
json_decode(x::Maxkey) = Dict("\$maxKey" => 1)
json_decode(x::Minkey) = Dict("\$minKey" => 1)
json_decode(x::Missing) = Dict("\$undefined" => true)
json_decode(x::ObjectId) = Dict("\$oid" => bytes2hex(Vector{UInt8}(x)))
json_decode(x::DateTime) = Dict("\$date" => json_decode(value(x) - UNIXEPOCH))
json_decode(x::BSONSymbol) = Dict("\$symbol" => x.value)
json_decode(x::Int32) = Dict("\$numberInt" => string(x))
json_decode(x::Int64) = Dict("\$numberLong" => string(x))
json_decode(x::Code) = Dict("\$code" => x.code)
json_decode(x::BSONArray) = [json_decode(elem.value) for elem in x.elements]
json_decode(x::Document) = Dict(elem.key => json_decode(elem.value) for elem in x.elements)
json_decode(x::DBPointer) = Dict("\$dbPointer" => Dict("\$ref" => x.ref, "\$id" => json_decode(x.id)))
json_decode(x::CodeWithScope) = Dict("\$code" => x.code, "\$scope" => json_decode(x.scope))

function json_decode(x::BSONRegex)
    Dict("\$regularExpression" => Dict("pattern" => x.pattern, "options" => x.options))
end

function json_decode(x::Binary)
    Dict("\$binary" => Dict("base64" => base64encode(x.bytes), "subType" => string(x.subtype, base=16, pad=2)))
end

function json_decode(x::Timestamp)
    Dict("\$timestamp" => Dict("t" => UInt32(x.value >> 32), "i" => UInt32(x.value & typemax(UInt32))))
end

function json_decode(x::Float64)
    if isfinite(x)
        v = string(x)
    elseif isnan(x)
        v = "NaN"
    elseif x > 0
        v = "Infinity"
    else
        v = "-Infinity"
    end
    Dict("\$numberDouble" => v)
end
