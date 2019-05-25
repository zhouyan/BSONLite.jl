using BSONLite
using DataStructures
using JSON
using Test

test_names = [
              "array",
              "binary",
              "boolean",
              "code",
              "code_w_scope",
              "datetime",
              "dbpointer",
              "dbref",
              "document",
              "double",
              "int32",
              "int64",
              "maxkey",
              "minkey",
              "null",
              "oid",
              "regex",
              "string",
              "symbol",
              "timestamp",
              "undefined",

              # "decimal128-1",
              # "decimal128-2",
              # "decimal128-3",
              # "decimal128-4",
              # "decimal128-5",
              # "decimal128-6",
              # "decimal128-7",
              # "multi-type-deprecated",
              # "multi-type",
             ]

function test_corpus(name)
    path = joinpath(@__DIR__, "bson-corpus/tests", "$name.json")
    case = JSON.parse(String(read(path)))
    @testset "$(case["description"])" begin

        for v in case["valid"]
            @testset "$(v["description"])" begin
                bson = uppercase(v["canonical_bson"])
                bytes = hex2bytes(bson)
                extjson = JSON.parse(v["canonical_extjson"])

                result = read_bson(bytes; codec = :extjson)
                @test result == extjson

                doc = read_bson(bytes, codec = x -> x)
                result = uppercase(bytes2hex(write_bson(doc)))
                @test result == bson

                doc = read_bson(bytes, dict = OrderedDict)
                result = uppercase(bytes2hex(write_bson(doc)))
                @test result == bson
            end
        end

        if haskey(case, "decodeErrors")
            @testset "Decode errors" begin
                for v in case["decodeErrors"]
                    err = v["description"]
                    @testset "$err" begin
                        bson = hex2bytes(v["bson"])
                        @test_throws Exception read_bson(bson)
                    end
                end
            end
        end
    end
end

@testset "bson-corpus" begin
    test_corpus.(test_names)
end
