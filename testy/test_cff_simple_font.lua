local data = require("cff_simple_font")

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

hex_dump(data)