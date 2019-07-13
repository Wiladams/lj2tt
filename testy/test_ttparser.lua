--[[
    Testing the truetype file parser
]]
package.path = "../?.lua;"..package.path;

local ffi = require("ffi")
local tt = require("lj2tt.truetype_parser")
local mmap = require("lj2tt.mmap_win32")
local ttinstruct = require("lj2tt.tt_instruction")


local function print_table_head(info)
    print("==== print_table_head ====")
    print(string.format("magicNumber: 0x%8X", info.tables['head'].magicNumber))
    print("macStyle: ", info.tables['head'].macStyle)
    print("unitsPerEm: ", info.tables['head'].unitsPerEm)
    print("fontDirectionHint: ", info.tables['head'].fontDirectionHint)
    print("indexToLocFormat: ", info.tables['head'].indexToLocFormat)
    print("glyphDataFormat: ", info.tables['head'].glyphDataFormat)
end

local function print_table_cmap(font)
    print("==== print_table_cmap ====")
    local cmap = font.tables['cmap']
    if not cmap then print("NO CMAP TABLE") end

    print(string.format("         Version: 0x%08x", cmap.version))
    print("Number of Tables: ", cmap.numTables)
    print("ENCODINGS")
    for i, platform in pairs(cmap.encodings) do
        for j, encoding in pairs(platform) do
            print(string.format("  PlatformID: %d  EncodingID: %d  Offset: %d  Format: %d",
                encoding.platformID, encoding.encodingID, encoding.offset, encoding.format))
        end
    end
end

local function printInstructions(ins, len)
    print("== INSTRUCTIONS ==")
    if not ins then print ("- NONE -") return false end
    
    len = len or #ins

    ttinstruct.transcode(ins,len);
--    if len < 1 then return false end
--    for i=0,len-1 do
        --print(ins[i])
--        print(string.format("0x%02X", ins[i]))
--    end
end

local function print_table_glyf(info)
    local glyf = info.tables['glyf']
    --local glyphs = glyf.glyphs

    local numGlyphs = info.numGlyphs;
    print("==== glyf table")
    local i = 0;
    while (i < info.numGlyphs-2) do
        local glyph = glyf.glyphs[i]
        --print(string.format("Contours: %d", glyph.numberOfContours))
        print("==== GLYPH : ", i, glyph.index)
        print("         Simple: ", glyph.simple or false)
        print("       Contours: ",glyph.numberOfContours)  
        print("      Num Flags: ", glyph.numFlags)      
        print(string.format("  Bounds: {%d %d %d %d}", glyph.xMin, glyph.yMin, glyph.xMax, glyph.yMax))


        -- Print out the actual points on the glyph
        if glyph.numberOfContours > 0 and glyph.coords then
            -- group printing of coordinates by contours
            local lastPoint = 0
            local nextLastPoint = 0
            local contourCount = 1;
            while contourCount <= glyph.numberOfContours do
                nextLastPoint = glyph.contourEnds[contourCount]
                print("CONTOUR: ", contourCount, nextLastPoint)
                local ptCounter = lastPoint
                while (ptCounter <= nextLastPoint) do
                    print(string.format("    Point: %5d %5d %5d", ptCounter, glyph.coords[ptCounter].x, glyph.coords[ptCounter].y))
                    ptCounter = ptCounter + 1;
                end
                lastPoint = nextLastPoint+1;
                contourCount = contourCount + 1;
            end
        end

        printInstructions(glyph.instructions, glyph.instructionLength)

        i = i + 1;
    end
end

local function print_table_loca(info)
    local offsets = info.tables['loca'].offsets

    for i=0, info.numGlyphs do
        print(i, offsets[i])
    end
end

local function print_table_name(info)
    local name = info.tables['name']
    print("==== print_table_name ====")
    print("format: ", name.format)
    print("count: ", name.count)
    print("stringoffset: ", name.stringOffset)
    for i, rec in ipairs(name.names) do
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
end

local function printTables(info)
    print("==== TABLES ====")
    print("Tag    Order   Offset   Length")
    if info.tables then
        for k, v in pairs(info.tables) do
            print(k, v.index, v.offset, v.length)
        end
    end

    print_table_head(info)
    --print_table_name(info)
    --print_table_loca(info)
    --print_table_cmap(info)
    print_table_glyf(info)
end

local function printFontInfo(info)
    local SCALER_TRUETYPE = 0x10000

    print("==== FONT INFO ====")
    print("        True Type: ", info.scalerType == SCALER_TRUETYPE or 'false')
    print("       Scaler Tag: ", info.scalerTag)
    print("       Num Glyphs: ", info.numGlyphs)
    print("       Num Tables: ", info.numTables)
    print(" indexToLocFormat: ", info.indexToLocFormat)
    print("           ascent: ", info.ascent)
    print("          descent: ", info.descent)
    
    printTables(info)
end

-- memory map the file so we have a pointer to start with
--local ffile = mmap("c:\\windows\\fonts\\calibri.ttf")
local ffile = mmap("c:\\windows\\fonts\\trebuc.ttf")
local data = ffi.cast("uint8_t *", ffile:getPointer());

--print("DATA: ", data)

-- initialize a font info so we can start parsing
local finfo = tt.Font {data = data, length = ffile.size}

--print("InitFont: ", res)

printFontInfo(finfo)