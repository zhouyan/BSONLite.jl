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

Simple usage

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
