local cffdata = require("cff_data")

print("cffdata: ", cffdata.standardEncoding)

local codes = {
    40,
    41,
}

for _, code in ipairs(codes) do
    local SID = cffdata.standardEncoding[code]
    local name = cffdata.standardStrings[SID]

    print(string.format("%3d %3d %s", code, SID, name))
end 


