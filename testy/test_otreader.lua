package.path = "../?.lua;"..package.path;

local OTReader = require("lj2tt.OTReader")
local mmap = require("lj2tt.mmap_win32")

--local ffile = mmap("resources/FontAwesome.ttf")
local ffile = mmap("resources/exo.extra-light-italic.otf")

local function printFontOffsetTables(font)
    for key, tbl in pairs(font.offsetTable.entries) do
        print(string.format("{tag='%s', offset = 0x%04x, length = %d};", 
            key, tbl.offset, tbl.length))
    end
end

local function printFont(font)
    print("numTables: ", font.offsetTable.numTables)
    printFontOffsetTables(font)
end

local function test_reader()
    local collection, err = OTReader:new({data = ffile:getPointer(), length = #ffile})

    if not collection then 
        print("test_reader, ERROR: ", err)
        return nil 
    end

    print("sfntVersionTag: ", collection.sfntVersionTag)
    print("sfntVersion: ", string.format("0x%08x", collection.sfntVersion))

    for _, font in ipairs(collection.fonts) do
        printFont(font)
    end
end

test_reader()


