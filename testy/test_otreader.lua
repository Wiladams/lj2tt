package.path = "../?.lua;"..package.path;

local OTReader = require("lj2tt.OTReader")
local mmap = require("lj2tt.mmap_win32")

--local ffile = mmap("resources/FontAwesome.ttf")
local ffile = mmap("resources/exo.extra-light-italic.otf")

local function printIntValue(tbl, name)
    local value = tbl[name]
    if not value then
        return false, "field not found";
    end

    print(string.format("    %s = %d,", name, value))
    return true;
end

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

local function print_table_GSUB(tbl)
    if not tbl then return false end

    print("GSUB = {")
    printIntValue(tbl, "majorVersion");
    printIntValue(tbl, "minorVersion");
    --printIntValue(tbl, "scriptListOffset");
    --printIntValue(tbl, "featureListOffset");
    --printIntValue(tbl, "lookupListOffset");

    -- scriptList
    -- featureList
    print("    featureList = {")
    for _, entry in ipairs(tbl.featureList.featureRecords) do
        print(string.format("        '%s',",entry.tag))
    end
    print("    };")
    -- lookupList

    print("};")
end

local function print_table_head(tbl)
    print("head = {")
    print(string.format("    magicNumber = 0x%8X", tbl.magicNumber))
    print("    flags = ", string.format("0x%04x", tbl.flags))
    print("    macStyle = ", tbl.macStyle)
    print("    unitsPerEm = ", tbl.unitsPerEm)
    print("    fontDirectionHint = ", tbl.fontDirectionHint)
    print("    indexToLocFormat = ", tbl.indexToLocFormat)
    print("    glyphDataFormat = ", tbl.glyphDataFormat)
    print("};")
end



local function print_table_hhea(tbl)
 
    local intFields = {
        "ascent",
        "descent",
        "lineGap",
        "advanceWidthMax",
        "minLeftSideBearing",
        "minRightSideBearing",
        "xMaxExtent",

        "caretSlopeRise",
        "caretSlopeRun",
        "caretOffset",
        "metricDataFormat",
        "numberOfHMetrics"
    }
    print("hhea = {")
    print(string.format("    version =  0x%08x;", tbl.version))

    for _, fieldName in ipairs(intFields) do
        printIntValue(tbl, fieldName)
    end

    print("};")
end

local CFFVersion = 0x00005000;
local TTVersion  = 0x00010000;

local function print_table_maxp(tbl)
    print("maxp = {")
    print(string.format("    version =  0x%08x;", tbl.version))
    print(string.format("    numGlyphs = %d;", tbl.numGlyphs))


    local intFields = {
        "maxPoints",
        "maxContours",
        "maxComponentPoints",
        "maxComponentContours",
        "maxZones",
        "maxTwilightPoints",
        "maxStorage",
        "maxFunctionDefs",
        "maxInstructionDefs",
        "maxStackElements",
        "maxSizeOfInstructions",
        "maxComponentElements",
        "maxComponentDepth"
    }

    if tbl.version == TTVersion then
        for _, fieldName in ipairs(intFields) do
            printIntValue(tbl, fieldName)
        end
    end

    print("};")
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

local function print_table_os2(tbl)
    for k,v in pairs(tbl) do
        print(k,v)
    end
end

local function printFont(font)
    print("font = {")
    --printFontTOC(font)

    -- print tables
    --print_table_head(font.offsetTable.entries['head'])
    --print_table_hhea(font.offsetTable.entries['hhea'])
    --print_table_name(font.offsetTable.entries['name'])
    --print_table_maxp(font.offsetTable.entries['maxp'])
    --print_table_os2(font.offsetTable.entries['OS/2'])
    print_table_GSUB(font.offsetTable.entries['GSUB'])

    print("};")
end

local function test_reader()
    local collection, err = OTReader:new({data = ffile:getPointer(), length = #ffile})

    if not collection then 
        print("test_reader, ERROR: ", err)
        return nil 
    end

    --print("    sfntVersionTag = ", collection.sfntVersionTag)
    --print("    sfntVersion = ", string.format("0x%08x", collection.sfntVersion))

    for _, font in ipairs(collection.fonts) do
        printFont(font)
    end
end

test_reader()


