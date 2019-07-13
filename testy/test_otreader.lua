package.path = "../?.lua;"..package.path;

local OTReader = require("lj2tt.OTReader")
local mmap = require("lj2tt.mmap_win32")

local ffile = mmap("FontAwesome.ttf")

local reader, err = OTReader:new({data = ffile:getPointer(), length = #ffile})

if not reader then return nil end


    print("sfntVersionTag: ", reader.sfntVersionTag)
    print("sfntVersion: ", string.format("0x%08x", reader.sfntVersion))

for k,v in pairs(reader.offsetTable.entries) do
    print(k, v)
end


