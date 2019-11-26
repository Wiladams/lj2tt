package.path = "../?.lua;"..package.path;

--[[
    Test cases for CFF operand decoding
]]

local cff = require("lj2tt.read_cff")
local binstream = require("lj2tt.binstream")
local hutil = require("hexutil")

--[[
    

    PASS_ENTRY("\x0F"                    , 0          ),
    PASS_ENTRY("\x00\x0F"                , 0          ),
    PASS_ENTRY("\x00\x0A\x1F"            , 0.1        ),
    PASS_ENTRY("\x1F"                    , 1          ),
    PASS_ENTRY("\x10\x00\x0F"            , 10000      ),
    PASS_ENTRY("\x12\x34\x5F"            , 12345      ),
    PASS_ENTRY("\x12\x34\x5A\xFF"        , 12345      ),
    PASS_ENTRY("\x12\x34\x5A\x00\xFF"    , 12345      ),

    PASS_ENTRY("\xA1\x23\x45\x67\x89\xFF", .123456789 ),
]]
local function test_operand_int()
    local vectors = {
        {"\x8b", "\\x8b", 0},
        {"\xef", "\\xef",100},
        {"\x27", "\\x27",-100},
        {"\xfa\x7c", "\\xfa\\x7c",1000},
        {"\xfe\x7c", "\\xfe\\x7c",-1000},
        {"\x1c\x27\x10", "\\x1c\\x27\\x10",10000},
        {"\x1c\xd8\xf0", "\\x1c\\xd8\\xf0",-10000},
        {"\x1d\x00\x01\x86\xa0", "\\x1d\\x00\\x01\\x86\\xa0",100000},
        {"\x1d\xff\xfe\x79\x60", "\\x1d\\xff\\xfe\\x79\\x60",-100000},
    }

    for _, vec in ipairs(vectors) do 
        local bs = binstream(vec[1])
        local val = cff.readOperand(bs)
        print("decode: ", val == vec[3], vec[2], val, vec[3])
    end 
end

local function test_operand_real()
    print("==== test_operand_real ====")

    local vectors = {
        {"1e 1f", 1},
        {"1e 00 0A 1F", 0.1},
        {"1e e2 a2 5f",-2.25},
        {"1E 0A 14 05 41 C3 FF", 0.140541E-3},
        {"1e 12 34 5A 67 89 FF", 12345.6789},
        {"10 00 0f", 10000}

    }

    for _, vec in ipairs(vectors) do
        local bin = hutil.hexToBin(vec[1])
        local bs = binstream(bin)
        local val = cff.readOperand(bs)
        print("decode real: ", val == vec[2], vec[1], val, vec[2])
    end 

end

--test_operand_int()
test_operand_real()


