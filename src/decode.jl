# BSON decoder

bson_decode(x; kwargs...) = x
bson_decode(x::Binary; kwargs...) = x.subtype == 0x00 ? x.bytes : x
bson_decode(x::BSONDate; kwargs...) = DateTime(UTM(UNIXEPOCH + x.value))
bson_decode(x::BSONSymbol; as_symbol = false, kwargs...) = as_symbol ? Symbol(x.value) : x
bson_decode(x::BSONArray; kwargs...) = [bson_decode(elem.value; kwargs...) for elem in x.elements]

function bson_decode(x::Document; dict = Dict, kwargs...)
    dict(elem.key => bson_decode(elem.value; dict = dict,  kwargs...) for elem in x.elements)
end

# Canonical Extended JSON decoder

extjson_decode(x) = x
extjson_decode(x::Maxkey) = Dict("\$maxKey" => 1)
extjson_decode(x::Minkey) = Dict("\$minKey" => 1)
extjson_decode(x::Missing) = Dict("\$undefined" => true)
extjson_decode(x::ObjectId) = Dict("\$oid" => x.value)
extjson_decode(x::BSONDate) = Dict("\$date" => extjson_decode(x.value))
extjson_decode(x::BSONSymbol) = Dict("\$symbol" => x.value)
extjson_decode(x::Int32) = Dict("\$numberInt" => string(x))
extjson_decode(x::Int64) = Dict("\$numberLong" => string(x))
extjson_decode(x::Code) = Dict("\$code" => x.code)
extjson_decode(x::BSONArray) = [extjson_decode(elem.value) for elem in x.elements]
extjson_decode(x::Document) = Dict(elem.key => extjson_decode(elem.value) for elem in x.elements)
extjson_decode(x::DBPointer) = Dict("\$dbPointer" => Dict("\$ref" => x.ref, "\$id" => extjson_decode(x.id)))

function extjson_decode(x::CodeWithScope)
    Dict("\$code" => x.code, "\$scope" => extjson_decode(x.scope))
end

function extjson_decode(x::BSONRegex)
    Dict("\$regularExpression" => Dict("pattern" => x.pattern, "options" => x.options))
end

function extjson_decode(x::Binary)
    Dict("\$binary" => Dict("base64" => base64encode(x.bytes), "subType" => string(x.subtype, base=16, pad=2)))
end

function extjson_decode(x::Timestamp)
    Dict("\$timestamp" => Dict("t" => UInt32(x.value >> 32), "i" => UInt32(x.value & typemax(UInt32))))
end

function extjson_decode(x::Float64)
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

# Relaxed Extended JSON decoder

json_decode(x) = extjson_decode(x)
json_decode(x::Int32) = x
json_decode(x::Int64) = x
json_decode(x::Float64) = isfinite(x) ? x : extjson_decode(x)

function json_decode(x::BSONDate)
    date = bson_decode(x)
    if DateTime(1970) <= date <= DateTime(9999)
        Dict("\$date" => string(date, "Z"))
    else
        extjson_decode(x)
    end
end
