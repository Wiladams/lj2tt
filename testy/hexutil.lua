
local function hex_dump(buf, len)
    len = len or #buf

    for byte=1, #buf, 16 do
       local chunk = buf:sub(byte, byte+15)
       io.write(string.format('%08X  ',byte-1))
       chunk:gsub('.', function (c) io.write(string.format('%02X ',string.byte(c))) end)
       io.write(string.rep(' ',3*(16-#chunk)))
       io.write(' ',chunk:gsub('%c','.'),"\n") 
    end
end

--[[
    return a binary representation of a hex encoded string
]]

local function stringToBinary(str)
    local function tobin(frag)
        --print("tobin: ", frag)
        return string.char(tonumber(frag,16))
    end

    str = str:gsub("%s+","")    -- remove whitespace
    local hex = str:gsub('(%x%x)', tobin)   -- turn hex pairs into numbers

    return hex
end

return {
    hex_dump = hex_dump;
    hexToBin = stringToBinary;
}