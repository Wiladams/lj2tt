package.path = "../?.lua;"..package.path;

--[[
    Test turning a hex string into 
    a binary string.

    As long as the string has 2 valid
    hex digits, it will be interpreted as
    byte values.
]]


local hutil = require("hexutil")
local binstream = require("lj2tt.binstream")

local vectors = {
    "01 02 03 04 05 06",
    "41 42 43 44 45 46",
    "464748495951",
}

local function printBin(bin)
    for i=1,#bin do
        io.write(bin:sub(i,i),' ')
    end
    print()
end

local function test_convert()
for _, vec in ipairs(vectors) do 
    local bin = hutil.hexToBin(vec)
    print(vec, #vec, #bin)
    printBin(bin)
end
end

local function test_roundtrip()
    local bin = hutil.hexToBin("01 02 03 04")
    local bs = binstream(bin)

    while not bs:EOF() do 
        local c = bs:readOctet()
        print(string.format("0x%02x", c))
    end
end

--test_convert()
test_roundtrip()
