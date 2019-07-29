--[[
    Functions specific to reading CFF table
]]
local ffi = require("ffi")
local bit = require("bit")
local lshift, rshift = bit.lshift, bit.rshift
local band, bor = bit.band, bit.bor

local B = string.byte
local C = string.char

-- Meaning of nibbles above 9.
local NibbleAbove9 = {
    kDecimalPoint     = 0xA,
    kPositiveExponent = 0xB,
    kNegativeExponent = 0xC,
    kReserved         = 0xD,
    kMinusSign        = 0xE,
    kEndOfNumber      = 0xF
  }

local floatLookup = {
    [0] = '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    [0xA] = '.',
    [0xB] = 'E',
    [0xC] = 'E-',
    [0xD] = '',     -- reserved
    [0xE] = '-'
    [0xF] = ''      -- end of number
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
]]

function readOperand(bs)
    local b0 = bs:readOctet();

    
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

local function readHeader(bs, res)
    res = res or {}

    res.version = {
        major = bs:readCard8();
        minor = bs:readCard8();
    }
    res.hdrSize = bs:readCard8();
    res.offSize = bs:readOffSize();
    
    return res;
end
