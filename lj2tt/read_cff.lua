--[[
    Functions specific to reading CFF table

    References
    https://github.com/photopea/Typr.js/blob/gh-pages/src/tabs/cff.js

]]
local ffi = require("ffi")
local bit = require("bit")
local lshift, rshift = bit.lshift, bit.rshift
local band, bor = bit.band, bit.bor
local Stack = require("lj2tt.stack")

local B = string.byte
local C = string.char

-- A convenience for creating a set based on 
-- a string
local function setCreate(str)
    local bytes = {string.byte(str,1,#str)}
    local res = {}
    for i=1,#str do
        res[bytes[i]] = true
    end

    return res
end

local function setCreateRange(low, high, res)
    res = res or {}
    for i=low, high do
        res[i] = true
    end

    return res
end

-- Create this operand set so it's much easier 
-- to determine from a single byte whether we've
-- got an operator or not.
local OperandSet = setCreate("\x1C\x1D\x1E")
setCreateRange(32,254, OperandSet)

--[[
    OperatorSet
    A set that allows us to quickly determine whether
    we've got an operator based on a single value
]]
local OperatorSet = setCreateRange(0,21)


local TOPDictionaryOperators = {
    [0x0000] = "version",               -- SID
    [0x0001] = "Notice",                -- SID
    [0x0002] = "FullName",              -- SID
    [0x0003] = "FamilyName",            -- SID
    [0x0004] = "Weight",                -- SID
    [0x0005] = "FontBBox",              -- array
    [0x000D] = "UniqueID",              -- number
    [0x000E] = "XUID",                  -- array
    [0x000F] = "charset",               -- number
    [0x0010] = "Encoding",              -- number
    [0x0011] = "CharStrings",           -- number
    [0x0012] = "Private",               -- number

    [0x0C00] = "Copyright",             -- SID
    [0x0C01] = "isFixedPitch",          -- boolean
    [0x0C02] = "ItalicAngle",           -- number
    [0x0C03] = "UnderlinePosition",     -- number
    [0x0C04] = "UnderlineThickness",    -- number
    [0x0C05] = "PaintType",             -- number
    [0x0C06] = "CharstringType",        -- number
    [0x0C07] = "FontMatrix",            -- array
    [0x0C08] = "StrokeWidth",           -- number



    [0x0C14] = "SyntheticBase",        -- number
    [0x0C15] = "Postscript",           -- SID
    [0x0C16] = "BaseFontName",         -- SID
    [0x0C17] = "BaseFontBlend",        -- delta

    -- CIDFont specific operators
    [0x0C1E] = "ROS",                   -- SID SID number
    [0x0C1F] = "CIDFontVersion",        -- number
    [0x0C20] = "CIDFontRevision",       -- number
    [0x0C21] = "CIDFontType",           -- number
    [0x0C22] = "CIDCount",              -- number
    [0x0C23] = "UIDBase",               -- number
    [0x0C24] = "FDArray",               -- number
    [0x0C25] = "FDSelect",              -- number
    [0x0C26] = "FontName",              -- SID
}


local floatLookup = {
    [0] = '0',
    [1] = '1',
    [2] = '2',
    [3] = '3',
    [4] = '4',
    [5] = '5',
    [6] = '6',
    [7] = '7',
    [8] = '8',
    [9] = '9',
    [0xA] = '.',    -- decimal point
    [0xB] = 'E',    -- positive exponent
    [0xC] = 'E-',   -- negative exponent
    [0xD] = '',     -- reserved
    [0xE] = '-',     -- minus sign
    [0xF] = '',      -- end of number
}
local function parseFloatOperand(bs)
    local eon = 0xF -- End Of Number

    local s = {}
    while true do
        local oc = bs:readOctet();
        local nib1 = rshift(oc,4)
        local nib2 = band(oc,0x0f) 

        --print("OC, nib1, nib2: ", oc, nib1, nib2)
        if nib1 == eon then
            break;
        end

        table.insert(s, floatLookup[nib1])

        if nib2 == eon then
            break;
        end

        table.insert(s, floatLookup[nib2])
    end

    local str = table.concat(s)
    local value = tonumber(str)

    return value
end

--[[
    parseOperand()

    Returns an operand encoding for the CFF table
    First, read a single octet, which tells us what
    size the integer should be.

    b0: 
        operators       0 - 21
        operands        28, 29, 30, 32-254
        reserved        22-27, 255

    operator may be preceded by up to 48 operands
]]


local function readOperand(bs)
    local b0 = bs:readOctet();

--print(string.format("b0: 0x%02x", b0))

    if (b0 == 28) then
        return bs:readInt16();
    elseif (b0 == 29) then
        return bs:readInt32();
    elseif (b0 == 30) then
        return parseFloatOperand(bs)
    elseif (b0 >= 32 and b0 <= 246) then       
        return b0 - 139;
    elseif (b0 >= 247 and b0 <= 250) then
        local b1 = bs:readOctet();
        return ((b0 - 247)*256) + b1 + 108;
    elseif (b0 >= 251 and b0 <= 254) then
        local b1 = bs:readOctet();
        return -(b0 - 251)*256 - b1 - 108;
    end

    return false, "unknown operand size"
end

--[[
    b0 values [0..21] are operators
    a b0 value of 12 indicates an extended operator
]]
local function readOperator(bs, b0)
    b0 = b0 or bs:readOctet();

    if b0 > 21 then return nil, "readOperator, outside valid range" end

    local op = b0
    if b0 == 12 then
        -- read one more byte to form 
        -- an extended operator value
        local b1 = bs:readOctet()
        op = bor(lshift(op,8), b1)
    end

    return op
end


local function stringConverter(bs)
    local value = bs:readString(bs:remaining())
    print("stringConverter: ", value)

    return value 
end




--[[
    readDict

    Read a dictionary.  The operands are turned into their
    name equivalents for easy lookup.
]]
local function readDict(bs, res)
    res = res or {}

    print("readDict - BEGIN")

    local opstack = Stack()

    while not bs:isEOF() do
        local operand = nil
        local operator = nil

        -- peek a byte
        local b0 = bs:peekOctet()
        if OperandSet[b0] then
            -- save an operand on the operand stack
            local op = readOperand(bs)
            opstack:push(op)
        elseif OperatorSet[c] then
            -- it's an operator
            -- get the name of the operator and store
            -- that as a key in the dictionary
            -- using the array of values of operand stack as value
            local op = readOperator(bs)
            local opname = TOPDictionaryOperators[op]
            local value = {opstack:popn(opstack:length())}
            res[opname] = value

            -- clear the operand stack so we can start over
            opstack:clear()
        end
        -- decide whether it's an operand or operator
    end

    return res
end

local function readData(bs, hdr, converter, res)
    res = res or {}

    for i=1,hdr.count do
        local size = hdr.offsets[i]-hdr.offsets[i-1]

        local vbs = bs:range(size)

        if converter then
            value = converter(vbs)
        else
            value = vbs:readBytes(vbs:remaining())
        end

        --print("readIndex, value: ", value)
        --table.insert(res, value)
        res[i] = value

        bs:skip(size)
    end
end

--[[
    readIndex

    Read index values.
]]
local function readIndex(bs, res, converter)
    res = res or {}

    -- keep a sentinel so we remember where we started
    local start = bs:tell();

    -- how many index values are there?
    res.count = bs:readCard16();
    local headerSize = 2

    -- how many bytes are used to indicate offsets?
    res.offsetSize = bs:readOffSize();
    --print("readIndex, offsetSize: ", res.offsetSize)
    headerSize = headerSize + 1;

    local offsetArraySize = res.offsetSize * (res.count + 1)
    local totalIndexSize = headerSize + offsetArraySize;

    print("CFF_readIndex, count, offsetSize, begin: ", res.count, res.offsetSize, res.count*res.offsetSize)

    -- if there's no count, there are no entries
    if res.count == 0 then
        return res;
    end

    --assert(res.offsetSize >=1 and res.offsetSize <= 4)
    --print("START: ", start)
--print("TELL: ", bs:tell())
    -- create array that will hold offsets
    res.offsets = {}

    -- Read all the offsets, and accumulate
    -- data size
    local dataSize = 0;
    for i=0,res.count do
        local offset = bs:readOffset(res.offsetSize)

        --print("offset: ", i, offset)

        if i>0 then
            local size = offset-res.offsets[i-1]
            --print("  SIZE: ", size)
            dataSize = dataSize + size
        end
        res.offsets[i] = offset
    end
    
    --print("DataSize: ", dataSize)
    --print("TELL, after reading indices: ", bs:tell())
    res.objects = readData(bs, res, converter)

--print("TELL, after reading data: ", bs:tell())
end



local function readHeader(bs, res)
    res = res or {}
    
    res.version = {
        major = bs:readCard8();
        minor = bs:readCard8();
    }
    res.headerSize = bs:readCard8();

    --print("cff.readHeader") 
    --print("  version: ", res.version.major, res.version.minor)
    --print("  header size: ", res.headerSize)

    -- If version.major == 1 then
    res.offsetSize = bs:readOffSize();
    
    return res;
end

local function readCFF(bs, toc, res)
    res = res or {}

    local hdr = readHeader(bs)
    res.header = hdr

    -- skip to the position right after the header size.
    -- We're probably already there, but this is the spec
    -- way to do it.
    bs:seek(hdr.headerSize)

    -- Read name index
    print("==== Name Index ====")
    res.nameIndex = readIndex(bs, nil, stringConverter)
    
    -- top dict index
    print("==== TOP DICT ====")
    --res.topDictIndex = readIndex(bs, nil, readDict)
    res.topDictIndex = readIndex(bs)

    -- string index
    print("==== STRING INDEX ====")
    res.stringIndex = readIndex(bs, nil, stringConverter)
--[[
    -- global subrs index
    print("==== GLOBAL SUBRS INDEX")
    res.globalSubrIndex = readIndex(bs)

    -- encodings
    -- charsets
    -- FDSelect

    -- charstrings index
    print("==== Charstrings INDEX ====")
    res.charStringsIndex = readIndex(bs)

    -- fontDict INDEX

    -- private dict
    --print("==== Private DICT ====")
    --res.privateDict = readIndex(bs)
    
    -- LSubR INDEX
    -- Copyright and trademark notices
--]]

    return res
end

local exports = {
    readOperand = readOperand;
    readDictionary = readDict;
    readHeader = readHeader;
    readIndex = readIndex;
    readData = readData;
    readCFF = readCFF;
}

return exports