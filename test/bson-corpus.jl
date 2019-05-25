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
                bson_str = v["canonical_bson"]
                json_str = v["canonical_extjson"]

                bson_bin = hex2bytes(bson_str)
                json_dat = JSON.parse(json_str)

                result = read_bson(bson_bin, codec = :json)
                @test result == json_dat

                result = bytes2hex(write_bson(read_bson(bson_bin, codec = :minimal)))
                @test uppercase(result) == uppercase(bson_str)
            end
        end

        if haskey(case, "decodeErrors")
            @testset "Decode errors" begin
                for v in case["decodeErrors"]
                    err = v["description"]
                    @testset "$err" begin
                        @test_throws Exception read_bson(hex2bytes(v["bson"]))
                    end
                end
            end
        end
    end
end

@testset "bson-corpus" begin
    test_corpus.(test_names)
end
