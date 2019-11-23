--[[
    Functions specific to reading CFF table
]]
local ffi = require("ffi")
local bit = require("bit")
local lshift, rshift = bit.lshift, bit.rshift
local band, bor = bit.band, bit.bor

local B = string.byte
local C = string.char


local TOPDictionaryOperators = {
    [0x0000] = "Version",
    [0x0001] = "Notice",
    [0x0002] = "FullName",
    [0x0003] = "FamilyName",
    [0x0004] = "Weight",
    [0x0005] = "FontBBox",
    [0x000D] = "UniqueID",
    [0x000E] = "XUID",
    [0x000F] = "Charset",
    [0x0010] = "Encoding",
    [0x0011] = "CharStrings",
    [0x0012] = "Private",

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
    local eon = 0xF

    local s = {}
    while true do
        local oc = bs:readOctet();
        local nib1 = rshift(oc,4)
        local nib2 = band(oc,0x0f) 

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

    if b0 < 22 then
        -- values [0..21] are operators
        -- a value of 12 indicates an extended operator
        local op = b0
        if b0 == 12 then
            -- read one more byte to form 
            -- an extended operator value
            local b1 = bs:readOctet()
            op = bor(lshift(op,8), b1)
        end

        return op
    elseif (b0 == 28) then
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



local function readIndex(bs, res, converter)
    res = res or {}

    local start = bs:tell();

    res.count = bs:readCard16();
    local headerSize = 2

    res.offsetSize = bs:readOffSize();
    print("readIndex, offsetSize: ", res.offsetSize)

    headerSize = headerSize + 1;
    local offsetArraySize = res.offsetSize * (res.count + 1)
    local totalIndexSize = headerSize + offsetArraySize;

    --print("CFF_readIndex, count, offsetSize, begin: ", res.count, res.offsetSize, res.count*res.offsetSize)

    -- if there's no count, there are no entries
    if res.count == 0 then
        return res;
    end

    --assert(res.offsetSize >=1 and res.offsetSize <= 4)
    --print("START: ", start)
--print("TELL: ", bs:tell())

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
    res.objects = {}
    for i=1,res.count do
        local size = res.offsets[i]-res.offsets[i-1]

        local value = bs:readBytes(size)
        
        if converter then
            value = converter(value, size)
        end

        --print("readIndex, value: ", value)
        table.insert(res.objects, value)
    end
--print("TELL, after reading data: ", bs:tell())
end


local function readHeader(bs, res)
    res = res or {}
    
    res.version = {
        major = bs:readCard8();
        minor = bs:readCard8();
    }
    res.headerSize = bs:readCard8();

    print("cff.readHeader") 
    print("  version: ", res.version.major, res.version.minor)
    print("  header size: ", res.headerSize)

    -- If version.major == 1 then
    res.offsetSize = bs:readOffSize();
    
    return res;
end


local exports = {
    readOperand = readOperand;
    readHeader = readHeader;
    readIndex = readIndex;
}

return exports