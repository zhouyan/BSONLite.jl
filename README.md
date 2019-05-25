# BSONLite

BSONLite.jl is a lightweight package for working with
[BSON](http://bsonspec.org) data.

There is an existing [BSON.jl](https://github.com/MikeInnes/BSON.jl) package.
This package differ in a few ways.

* It support all BSON types
* It separate the IO of raw BSON data from how they are encoding of Julia types.

The BSON.jl package is more suitable for use as a general serialization for
Julia data structures while this package aims to work better in multi-languages
context.

## Basic Usage

```julia
using BSONLite
using Dates

x = Dict(:a => "abc", :b => 10, :c => now(UTC))

write_bson("test.bson", x) # write to file
@show read_bson("test.bson")

io = IOBuffer()
write_bson(io, x) # write to IO
seek(io, 0)
@show read_bson(io)

buf = write_bson(x) # equivalent to io = IOBuffer(); write_bson(io, x); take!(io)
@show read_bson(buf)
```

## Decoding BSON data

### Minimal

```julia
read_bson("test.bson", codec = :minimal)
```

The `minimal` codec make minimal parsing of the results. The following type
mapping is used.

| BSON type  | Type id | Julia type             |
|------------|---------|------------------------|
| Double     | 0x01    | Float64                |
| String     | 0x02    | String                 |
| Document   | 0x03    | BSONLite.Document      |
| Array      | 0x04    | BSONLite.BSONArray     |
| Binary     | 0x05    | BSONLite.Binary        |
| Undefined  | 0x06    | Missing                |
| Object id  | 0x07    | BSONLite.ObjectId      |
| Bool       | 0x08    | Bool                   |
| Date time  | 0x09    | Dates.DateTime         |
| Null       | 0x0A    | Nothing                |
| Regex      | 0x0B    | BSONLite.BSONRegex     |
| DBPointer  | 0x0C    | BSONLite.DBPointer     |
| Code       | 0x0D    | BSONLite.Code          |
| Symbol     | 0x0E    | BSONLite.BSONSymbol    |
| Code W/S   | 0x0F    | BSONLite.CodeWithScope |
| Int32      | 0x10    | Int32                  |
| Timestamp  | 0x11    | BSONLite.Timestamp     |
| Int64      | 0x12    | Int64                  |
| Decimal128 | 0x13    | BSONLite.Decimal128    |
| Max key    | 0x7F    | BSONLite.Maxkey        |
| Min key    | 0xFF    | BSONLite.Minkey        |

All all the BSONLite defined types only `ObjectId` is exported.

The main purpose of the `minimal` codec is to ensure round trip equivalency. For
example,

```julia
@assert read("test.bson") == write_bson(read_bson("test.bson"), codec = :minimal)
```

shall always success.

### BSON (default codec)

This codec make additional decoding of the data for the following types,

| Minimal type           | Julia type                              |
|------------------------|-----------------------------------------|
| BSONLite.Document      | Dict                                    |
| BSONLite.BSONArray     | Vector                                  |
| BSONLite.Binary        | Vector{UInt8} for default subtype (x00) |

Note that the following test might fail due to reordering or elements in a
document.

```julia
@assert read("test.bson") == write_bson(read_bson("test.bson"), codec = :bson)
```

### JSON

This codec decode the data to a structure that is ready to be serialized as
[Canonical Extended JSON](https://github.com/mongodb/specifications/blob/master/source/extended-json.rst),
for example by the [JSON.jl](https://github.com/JuliaIO/JSON.jl) package.

```julia
using JSON

println(json(read_bson("test.bson", codec = :json)))
```

```
{"c":{"$date":{"$numberLong":"1558808687620"}},"b":{"$numberLong":"10"},"a":"abc"}
```

Again note that the following may fail due to reordering of elements in a
document.

```julia
@assert read("test.bson") == write_bson(read_bson("test.bson"), codec = :json)
```

### Custom

One can define custom decoding functions and pass it to `read_bson`. For example
the `:bson` codec is defined as the following,

```julia
bson_decode(x) = x
bson_decode(x::Binary) = x.subtype == 0x00 ? x.bytes : x
bson_decode(x::Document) = Dict(elem.key => bson_decode(elem.value) for elem in x.elist)
bson_decode(x::BSONArray) = [bson_decode(elem.value) for elem in x.elist]
```

Or one can extend an existing codec via Julia's usual method dispatch mechanism.

For example, the following will provide round-trip equivalency

```julia
using DataStructures

ordered_decode(x) = x
ordered_decode(x::Document) = OrderedDict(elem.key => ordered_decode(elem.value) for elem in x.elist)
ordered_decode(x::BSONArray) = [ordered_decode(elem.value) for elem in x.elist]

@assert read("test.bson") == write_bson(read_bson("test.bson"), codec = ordered_decode)
```

## Encoding data

Not all Julia types can be encoded as BSON by default. The default encoder
`:bson` support the following types,

* `BSONLite` types are encoded as-is
* `Symbol` is encoded as string instead of the deprecated BSON symbol
* `AbstractVector{UInt8}` is encoded as `Binary` with default subtype
* Integers are encoded as `Int32` if they have less than or equal to 32 bits.
* Other integers encoded as `Int64`
* `AbstractFloat` is encoded as `Flaot64`
* `AbstractDict` is encoded as `Document`
* `AbstractVector` is encoded as `BSONArray`

If one want to encode other data types, one can overload the `encode_bson`
function to convert general Julia type to one of the supported type listed in
the Minimal section earlier.

## Testing

The package is tested against the [BSON corpus](https://github.com/mongodb/specifications/blob/master/source/bson-corpus/bson-corpus.rst) with a few minor modifications

Two test cases in `double` are modified to account to small difference in how
Julia convert `Float64` to string for numbers with more than 15 digits after
decimals.

## LICENSE

## TODO

* Support `Decimal128` for Canonical Extended JSON
