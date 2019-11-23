package.path = "../?.lua;"..package.path;

--[[
    Test cases for CFF operand decoding
]]

local cff = require("lj2tt.read_cff")
local binstream = require("lj2tt.binstream")

--[[
    
    PASS_ENTRY("\xE2\xA2\x5F"            ,-2.25       ),
    PASS_ENTRY("\x0A\x14\x05\x41\xC3\xFF", 0.140541e-3),
    PASS_ENTRY("\x0F"                    , 0          ),
    PASS_ENTRY("\x00\x0F"                , 0          ),
    PASS_ENTRY("\x00\x0A\x1F"            , 0.1        ),
    PASS_ENTRY("\x1F"                    , 1          ),
    PASS_ENTRY("\x10\x00\x0F"            , 10000      ),
    PASS_ENTRY("\x12\x34\x5F"            , 12345      ),
    PASS_ENTRY("\x12\x34\x5A\xFF"        , 12345      ),
    PASS_ENTRY("\x12\x34\x5A\x00\xFF"    , 12345      ),
    PASS_ENTRY("\x12\x34\x5A\x67\x89\xFF", 12345.6789 ),
    PASS_ENTRY("\xA1\x23\x45\x67\x89\xFF", .123456789 ),
]]
local function test_operand_int()
    local vectors = {
        {"\x8b", "\\x8b", 0},
        {"\x1f", "\\x1f", 1},
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
        {"\x1e\xe2\xa2\x5f", "\\x1e\\xe2\\xa2\\x5f",-2.25},
        {"\x1E\x0A\x14\x05\x41\xC3\xFF", "\\x1E\\x0A\\x14\\x05\\x41\\xC3\\xFF", 0.140541E-3},
    }

    for _, vec in ipairs(vectors) do 
        local bs = binstream(vec[1])
        local val = cff.readOperand(bs)
        print("decode real: ", val == vec[3], vec[2], val, vec[3])
    end 

end

test_operand_int()
test_operand_real()


