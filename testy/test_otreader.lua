package.path = "../?.lua;"..package.path;

local OTReader = require("lj2tt.OTReader")
local mmap = require("lj2tt.mmap_win32")

--local ffile = mmap("resources/FontAwesome.ttf")
local ffile = mmap("resources/exo.extra-light-italic.otf")

local function printFontTOC(font)
    print("    tableOfContents = {")
    print(string.format("        numTables = %d;", font.offsetTable.numTables))

    print("        entries = {")
    for key, tbl in pairs(font.offsetTable.entries) do
        print(string.format("            {tag='%s', offset = 0x%04x, length = %d};", 
            key, tbl.offset, tbl.length))
    end
    print("        };")
    print("    };")
    print("};")
end

local function print_table_head(tbl)
    print("==== print_table_head ====", tbl)
    print(string.format("magicNumber: 0x%8X", tbl.magicNumber))
    print("flags: ", string.format("0x%04x", tbl.flags))
    print("macStyle: ", tbl.macStyle)
    print("unitsPerEm: ", tbl.unitsPerEm)
    print("fontDirectionHint: ", tbl.fontDirectionHint)
    print("indexToLocFormat: ", tbl.indexToLocFormat)
    print("glyphDataFormat: ", tbl.glyphDataFormat)
end

local function print_table_name(tbl)
    print(string.format("names = {"))
    print(string.format("    format = %d, ", tbl.format))
    print(string.format("    count = %d,", tbl.count))
    print(string.format("    stringoffset = 0x%04x,", tbl.stringOffset))

    for i, rec in ipairs(tbl.names) do
        if ((rec.platformID == 1) or (rec.platformID == 3)) and rec.platformSpecificID == 0 then
        print(string.format("%4d    %4d    %4d    %4d    %4d    %4d    %s",
            rec.platformID, rec.platformSpecificID,
            rec.languageID, rec.nameID,
            rec.length, rec.offset, rec.value))
        else
            print(string.format("%4d    %4d    %4d    %4d    %4d    %4d",
            rec.platformID, rec.platformSpecificID,
            rec.languageID, rec.nameID,
            rec.length, rec.offset))
        end
    end
    print("};")
end

local function printFont(font)
    print("font = {")
    printFontTOC(font)

    -- print tables
    print_table_head(font.offsetTable.entries['head'])
    print_table_name(font.offsetTable.entries['name'])
end

local function test_reader()
    local collection, err = OTReader:new({data = ffile:getPointer(), length = #ffile})

    if not collection then 
        print("test_reader, ERROR: ", err)
        return nil 
    end

    print("    sfntVersionTag = ", collection.sfntVersionTag)
    print("    sfntVersion = ", string.format("0x%08x", collection.sfntVersion))

    for _, font in ipairs(collection.fonts) do
        printFont(font)
    end
end

test_reader()


