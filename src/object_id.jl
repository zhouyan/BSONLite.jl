struct ObjectId
    value::String

    function ObjectId(bytes::Vector{UInt8})
        @assert length(bytes) == 12
        new(bytes2hex(bytes))
    end
end

ObjectId(str::AbstractString) = ObjectId(hex2bytes(str))

Vector{UInt8}(oid::ObjectId) = hex2bytes(oid.value)
