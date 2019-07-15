--[[
parseTable: 	head    - parsed
parseTable: 	maxp    - parsed
parseTable: 	hhea    - parsed
parseTable: 	name    - parsed
parseTable: 	loca    - parsed

parseTable: 	fpgm
parseTable: 	prep
parseTable: 	cvt 
parseTable: 	cmap
parseTable: 	post
parseTable: 	OS/2
parseTable: 	glyf
parseTable: 	hmtx    - parsed
]]
local ffi = require("ffi")
local bit = require("bit")
local band, bor = bit.band, bit.bor
local lshift, rshift = bit.lshift, bit.rshift

--[[
    Common tables
]]
local function read_ScriptList(bs, res)
    local function readScriptTable(bs, res)
        local function readLangSysRecord(bs, res)
            local function readLanguageSystemTable(bs, res)
                res = res or {}
                res.lookupOrder = bs:readOffset16();
                res.requiredFeatureIndex = bs:readUInt16();
                res.featureIndexCount = bs:readUInt16();
                if res.featureIndexCount > 0 then
                    res.featureIndices = {}
                    for i=1, res.featureIndexCount do
                        local value = bs:readUInt16();
                        table.insert(res.featureIndices, value)
                    end
                end

                return res
            end

            res = res or {}
            res.langSysTag = bs:readTag();
            res.langSysOffset = bs:readOffset16();
            local ls = bs:getRange({position = res.langSysOffset})
            res.langSysTable = readLanguageSystemTable(ls)

            return res;
        end

        res = res or {}
        res.defaultLangSys = bs:readOffset16();
        res.langSysCount = bs:readUInt16();

        if res.langSysCount > 0 then
            res.langSysRecords = {};
            for i=1, res.langSysCount do 
                local rec = readLangSysRecord(bs);
                table.insert(res.langSysRecords, rec);
            end
        end

        return res;
    end

    local function readScriptRecord(bs, res)
        res = res or {}
        res.scriptTag = bs:readTag();
        res.scriptOffset = bs:readOffset16();

        return res;
    end

    -- This starts as a table of contents
    -- for script records, so first read the 
    -- table of contents records
    res = res or {}
    res.scriptCount = bs:readUInt16();
    res.scriptRecords = {}
    for i=1,res.scriptCount do
        local rec = readScriptRecord(bs);
        table.insert(res.scriptRecords, rec)
    end

    -- Now we have table of contents so read
    -- the actual records for each entry 
    for _, entry in ipairs(res.scriptRecords) do 
        local ts, err = bs:getRange({position = entry.scriptOffset})
        --print("TS, err: ", ts, err, bs:remaining())
        entry.scriptTable = readScriptTable(ts)
    end


    return res
end


local OTTableReader = {}

-- Read the contents of the 'cmap' table
-- Although we can read the raw data for the 
-- specified format, what really needs to happen here
-- is a function needs to be created for each format
-- where it will receive the data, and determine the index
-- of a codepoint using whatever the appropriate calculation is
-- look at: stbtt_FindGlyphIndex
--
local function read_cmap_format(cmap, encodingRecord)
    local ms = ttstream(cmap.data, cmap.length);
    bs:seek(encodingRecord.offset)
    
    -- Table of functions for reading formats
    -- The index to the table is the cmap sub-table format
    local formatMapper = {
        [0] = function(er)
            print("CMAP FORMAT 0")
            er.length = bs:readUInt16();
            er.language = bs:readUInt16();
            er.index_map = ffi.new("uint8_t[?]", 256);

            for i=0,255 do
                er.index_map[i] = bs:getUInt8();
            end
        end;

        [4] = function(er)
            print("CMAP FORMAT 4");
            er.length = bs:readUInt16();
            er.language = bs:readUInt16();
            -- and a whole lot more!!
        end;

        [6] = function(er)
            er.length = bs:readUInt16();
            er.language = bs:readUInt16();
            er.firstCode = bs:readUInt16();
            er.entryCount = bs:readUInt16();
            er.index_map = ffi.new("uint16_t[?]", er.entryCount);

            for i=0,er.entryCount-1 do
                index_map[i] = bs:readUInt16();
            end
        end;
    }
    
    -- Get the format of the encoding record
    -- which will determine the remaining fields
    encodingRecord.format = bs:readUInt16();

    local formatter = formatMapper[encodingRecord.format]
    if not formatter then return false end

    -- Execute the formatter
    formatter(encodingRecord);


    return encodingRecord
end

function OTTableReader.cmap(bs, toc, res)
    res = res or {}

    res.version = bs:readUInt16();
    res.numTables = bs:readUInt16();     -- Number of encoding tables
    res.encodings = {};

    -- Read 'numTables' worth of encoding records
    for i=1, res.numTables do
        local platformID = bs:readUInt16();

        local encodingRecord = {
            platformID = platformID;
            encodingID = bs:readUInt16();
            offset = bs:readUInt32();
        };
--[[
        -- Now that we have an offset
        -- we can read the details of the encoding
        read_cmap_format(tbl, encodingRecord);

        if not tbl.encodings[platformID] then
            print("NEW PLATFORM ID: ", platformID)
            tbl.encodings[platformID] = {}
        end

        table.insert(tbl.encodings[platformID], encodingRecord);
--]]
    end

    return res;
end





--[[
    the glyf table contains the contours associated with each glyf
    This is by far the most important and challenging table to read.
    First, the table depends on the 'loca' table to know where the
    offset is for a given glyph, so that must have already been read in.

    Each glyph has contours, or composit information, and/or
    hinting instructions.

    Step by step, bit by bit
]]
-- FLAG values for glyph
local TT_GLYF_ON_CURVE  = 1;
local TT_GLYF_X_IS_BYTE = 2;
local TT_GLYF_Y_IS_BYTE = 4;
local TT_GLYF_REPEAT    = 8;
local TT_GLYF_X_DELTA   = 16;
local TT_GLYF_Y_DELTA   = 32;



function OTTableReader.readSimpleGlyph(self, glyph, ms)
    local function debugit(idx, glyph, fmt, ...)
        if glyph.index ~= idx then
            return;
        end
        local sfmt = string.format("%d = ",idx)..fmt
        print(string.format(sfmt, ...))
    end
    
    -- Knowing it's a simple glyph, load in the contour data
    glyph.simple = true;
    glyph.contourEnds = {}
    glyph.coords = {}

    -- grab the endpoints for each contour
    --debugit(26, glyph, "CONTOURS: %d", glyph.numberOfContours)
    for cnt=1, glyph.numberOfContours do
        glyph.contourEnds[cnt] = bs:readUInt16()
        --debugit(26, glyph, "END: %d",glyph.contourEnds[cnt])
    end

    -- We now know how many bytes of instruction there are, so load that 
    glyph.instructionLength = bs:readUInt16();
    --print("INSTRUCTIONLENGTH: ", glyph.instructionLength)
    --glyph.instructions = bs:getString(glyph.instructionLength);
    glyph.instructions = bs:getBytes(glyph.instructionLength);

    local noc  = glyph.contourEnds[glyph.numberOfContours]+1;
    glyph.numFlags = noc;
    glyph.numCoords = noc;
    glyph.flags = {};
    local flags = glyph.flags;


    -- First, read all the flags
    local i = 0;
    local offset = 0;
    --debugit(26, glyph, "Number of Coords: %d", noc)
    while ( i < noc) do
        local flag = bs:getUInt8();
        assert(flag)
        --debugit(26, glyph, "FLAG: %d  0x%04x", i, flag)

        glyph.flags[offset] = flag;     
        glyph.coords[offset] = {onCurve = band(flag,TT_GLYF_ON_CURVE) ~= 0 }
        offset = offset + 1;

        -- repeat only applies to the
        -- flags themselves, so we do the expansion
        -- and increment the loop counter accordingly
        if band(flag, TT_GLYF_REPEAT) > 0 then
            local repeatCount = bs:get8();
            i = i + repeatCount;
            --debugit(26, glyph, "  Repeat: 0x%04x  %d", flag, repeatCount)
            --assert(repeatCount > 0);
            local j = 0;
            while ( j < repeatCount) do
                flags[offset] = flag;   
                glyph.coords[offset] = {onCurve = band(flag,TT_GLYF_ON_CURVE) ~= 0 }
                offset = offset + 1;
                j = j + 1;
            end
        end

        i=i+1;
    end


    -- This function helps us convert from the currently stored
    -- delta values, into absolute coordinate values
    function readCoords(name, byteFlag, deltaFlag, min, max) 
        local value = 0;
        local i = 0;
        while( i < noc) do
            local flag = flags[i];
            local is8 = band(flag, byteFlag) ~= 0
            local same = band(flag, deltaFlag) ~= 0

            if is8 then
                -- in the case of using a byte to designate a delta
                -- if 'same' is true, that means it's a positive value
                -- otherwise, it's negative.  Essentially the sign bit
                -- is represented by the deltaFlag
                if same  then
                    value = value + bs:getUInt8();
                else
                    value = value - bs:getUInt8();
                end
            elseif same then
                -- value is unchanged.
            else
                --print("DELTA")
                value = value + bs:readInt16();
            end

            glyph.coords[i][name] = value;
            i = i + 1;
        end
    end

    --print("I: Points: ", glyph.index, numPoints)
    readCoords("x", TT_GLYF_X_IS_BYTE, TT_GLYF_X_DELTA, glyph.xMin, glyph.xMax);
    readCoords("y", TT_GLYF_Y_IS_BYTE, TT_GLYF_Y_DELTA, glyph.yMin, glyph.yMax);
end

function OTTableReader.glyf(bs, toc, res)
    res = res or {}

    local numGlyphs = toc['maxp'].numGlyphs

    local offsets = toc['loca'].offsets

--[[
    res.glyphs = {}
    local glyphs = res.glyphs

    local i = 0;
    while i < numGlyphs-2 do
        --local offset = offsets[i];
        --print("OFFSET: ", offsets[i])
        bs:seek(offsets[i])

        local glyph = {
            index = i;
            numberOfContours = bs:readInt16();
            xMin = bs:readInt16();
            yMin = bs:readInt16();
            xMax = bs:readInt16();
            yMax = bs:readInt16();
            };

        -- Based on the number of contours, we can figure out if 
        -- this is a simple glyph, or a compound glyph (combo of glyphs)
        -- contours < 0    glyph comprised of components
        -- contours == 0    has no glyph data, could be components (-1 recommended)
        -- contours > 1
        local contourCount = glyph.numberOfContours
        if contourCount > 0 then
            OTTableReader.readSimpleGlyph(self, glyph, ms)
        elseif contourCount < 0 then
            -- composite glyph
        end

        glyphs[i] = glyph;
        --table.insert(glyphs, glyph)
        
        i = i + 1;
    end
--]]
    --print("readTabke_glyf: FINISHED")
    return res
end

-- This is a fairly complex table
-- bit by bit
function OTTableReader.GSUB(bs, toc, res)
    res = res or {}

    -- Header fields are cumulative, depending on the 
    -- major.minor number
    -- Start with common
    res.majorVersion = bs:readUInt16();
    res.minorVersion = bs:readUInt16();
    res.scriptListOffset = bs:readOffset16();
    res.featureListOffset = bs:readOffset16();
    res.lookupListOffset = bs:readOffset16();

    local scriptSize = res.featureListOffset - res.scriptListOffset;
    local featureSize = res.lookupListOffset - res.featureListOffset;
    local lookupListSize = bs:remaining() - res.lookupListOffset;
    local featurVariationSize = 0

    if res.majorVersion == 1 and res.minorVersion == 1 then
        res.featureVariationsOffset = bs:readOffset32();
        lookupListSize = res.featureVariationsOffset - res.lookupListOffset;
        featureVariationSize = bs:remaining() - res.featureVariationsOffset;
    end

    --print("majorVersion: ", res.majorVersion)
    --print("minorVersion: ", res.minorVersion)
    --print("scriptListOffset: ", res.scriptListOffset)

    -- Now that we have offsets, we can read each type of thing
    res.scriptList = read_ScriptList(bs:getRange({position = res.scriptListOffset}))
    --res.featureList = read_FeatureList(bs:getRange({position = res.featureListOffset}))
    --res.lookupList = read_lookupList(bs:getRange({position = res.lookupListOffset}))

    return res
end


function OTTableReader.head(bs, toc, res)
    res = res or {}
    
    res.version = bs:readFixed();
    res.fontRevision = bs:readFixed();
    res.checksumAdjustment = bs:readUInt32();
    res.magicNumber = bs:readUInt32();
    res.flags = bs:readUInt16();
    res.unitsPerEm = bs:readUInt16();
    res.created = bs:readDate();
    res.modified = bs:readDate(); 
    res.xMin = bs:readFWord();
    res.yMin = bs:readFWord();
    res.xMax = bs:readFWord();
    res.yMax = bs:readFWord();
    res.macStyle = bs:readUInt16();
    res.lowestRecPPEM = bs:readUInt16();
    res.fontDirectionHint = bs:readInt16();
    res.indexToLocFormat = bs:readInt16();
    res.glyphDataFormat = bs:readInt16();

    return res;
end

function OTTableReader.hhea(bs, toc, res)
    res = res or {}

    res.version = bs:readFixedVersion();
    res.ascent = bs:readFWord();
    res.descent = bs:readFWord();
    res.lineGap = bs:readFWord();
    res.advanceWidthMax = bs:readUFWord();
    res.minLeftSideBearing = bs:readFWord();
    res.minRightSideBearing = bs:readFWord();
    res.xMaxExtent = bs:readFWord();
    res.caretSlopeRise = bs:readInt16();
    res.caretSlopeRun = bs:readInt16();
    res.caretOffset = bs:readInt16();
    --reserved - ttSHORT
    --reserved - ttSHORT
    --reserved - ttSHORT
    --reserved - ttSHORT
    bs:skip(8);
    res.metricDataFormat = bs:readInt16();       
    res.numberOfHMetrics = bs:readUInt16();    

    return res
end

function OTTableReader.hmtx(bs, toc, res)
    res = res or {}

    local numberOfHMetrics = toc['hhea'].numberOfHMetrics;
    local numGlyphs = toc['maxp'].numGlyphs;


    local function readLongHorMetric(bs, rec)
        rec = rec or {}
        rec.advanceWidth = bs:readUInt16(); -- advance witdh, in font design units
        rec.lsb = bs:readInt16();

        return rec
    end

    res.hMetrics = {}
    for i=1, numberOfHMetrics do
        local rec = readLongHorMetric(bs)
        table.insert(res.hMetrics, rec)
    end

    local lsbCount = numGlyphs - numberOfHMetrics;
    if lsbCount > 0 then
        res.leftSideBearings = {}
        for i=0,lsbCount-1 do
            local rec = bs:readInt16();
            table[numberOfHMetrics+i] = rec;
        end
    end

    return res
end

function OTTableReader.loca(bs, toc, res)
    res = res or {}

    local numGlyphs = toc['maxp'].numGlyphs
    local locFormat = toc['head'].indexToLocFormat;

    res.offsets = {}

    if locformat == 0 then
        for i = 0, numGlyphs-1 do
            res.offsets[i] = bs:readUInt16()*2;
        end
    elseif locformat == 1 then
        for i = 0, numGlyphs-1 do
            res.offsets[i] = bs:readUInt32();
        end
    end

    return res
end

-- Read the contents of the 'maxp' table
function OTTableReader.maxp(bs, toc, res)

    local CFFVersion = 0x00005000;
    local TTVersion  = 0x00010000;


    res.version = bs:readFixedVersion() -- ttULONG(self.data+0);
    res.numGlyphs = bs:readUInt16(); -- tonumber(ttUSHORT(self.data+4));

    --print("maxp, version: ", string.format("0x%08x", res.version))

    if res.version == CFFVersion then
        return res;
    end
    
    -- assume TTVersion
    res.maxPoints = bs:readUInt16(); -- ttUSHORT(self.data+6);
    res.maxContours = bs:readUInt16(); -- ttUSHORT(self.data+8);
    res.maxComponentPoints = bs:readUInt16(); -- ttUSHORT(self.data+10);
    res.maxComponentContours = bs:readUInt16(); -- ttUSHORT(self.data+12);
    res.maxZones = bs:readUInt16(); -- ttUSHORT(self.data+14);
    res.maxTwilightPoints = bs:readUInt16(); -- ttUSHORT(self.data+16);
    res.maxStorage = bs:readUInt16(); -- ttUSHORT(self.data+18);
    res.maxFunctionDefs = bs:readUInt16(); -- ttUSHORT(self.data+20);
    res.maxInstructionDefs = bs:readUInt16(); -- ttUSHORT(self.data+22);
    res.maxStackElements = bs:readUInt16();  -- ttUSHORT(self.data+24);
    res.maxSizeOfInstructions = bs:readUInt16(); -- ttUSHORT(self.data+26);
    res.maxComponentElements = bs:readUInt16(); -- ttUSHORT(self.data+28);
    res.maxComponentDepth = bs:readUInt16(); -- ttUSHORT(self.data+30);


    return res;
end

--[[
    Reading the name table

    Name values can be in various encodings (not necessarily ASCII), but
    that's ok because Lua is byte agnostic with respect to 'string' values.
    As long as we know the length of the 'string' (which we do), there's 
    no problem encapsulating it in a lua string.
]]
function OTTableReader.name(bs, toc, res)
    res = res or {}
    
    local startOfTable = bs:tell()

    res.format = bs:readUInt16();

    -- format can be either 0 or 1, so read fields
    -- specific to the format.  Both formats still have the 
    -- count, stringOffset, and nameRecord fields
    res.count = bs:readUInt16();
    res.stringOffset = bs:readUInt16();
    res.names = {}

    --print("==== readTable_name: ", tbl, tbl.name, tbl.count)
    
    -- for the number of name record entries...
    local i=0
    while (i < res.count ) do
        local rec = {
            platformID = bs:readUInt16();
            platformSpecificID = bs:readUInt16();
            languageID = bs:readUInt16();
            nameID = bs:readUInt16();
            length = bs:readUInt16();
            offset = bs:readUInt16();
        }
        
        rec.value = ffi.string(bs:getPositionPointer(res.stringOffset+rec.offset), rec.length)
        --rec.value = ffi.string(tbl.data+tbl.stringOffset+rec.offset, rec.length)

        table.insert(res.names, rec)
        
        i = i + 1;
    end

    -- If format == 1, then we have more to do
    -- there are the langTagRecords to be read in



    return res
end


--[[
        local fields = {
        {name = "version", kind = "uint16"};
        {name = "xAvgCharWidth", kind = "int16"};
        {name = "usWeightClass", kind = "uint16"};
        {name = "usWidthClass", kind = "uint16"};
        {name = "fsType", kind = "uint16"};
        {name = "ySubscriptXSize", kind = "int16"};
        {name = "ySubscriptYSize", kind = "int16"};
        {name = "ySubscriptXOffset", kind = "int16"};
        {name = "ySubscriptYOffset", kind = "int16"};
        {name = "ySuperscriptXSize", kind = "int16"};
        {name = "ySuperscriptYSize", kind = "int16"};
        {name = "ySuperscriptXOffset", kind = "int16"};
        {name = "ySuperscriptYOffset", kind = "int16"};
        {name = "yStrikeoutSize", kind = "int16"};
        {name = "yStrikeoutPosition", kind = "int16"};
        {name = "sFamilyClass", kind = "int16"};
        {name = "panose", kind = "uint8", size=10};
        {name = "ulUnicodeRange1", kind = "uint32"};
        {name = "ulUnicodeRange2", kind = "uint32"};
        {name = "ulUnicodeRange3", kind = "uint32"};
        {name = "ulUnicodeRange4", kind = "uint32"};
        {name = "achVendID", kind = "Tag"};
        {name = "fsSelection", kind = "uint16"};
        {name = "usFirstCharIndex", kind = "uint16"};
        {name = "usLastCharIndex", kind = "uint16"};
        {name = "sTypoAscender", kind = "int16"};
        {name = "sTypoDescender", kind = "int16"};
        {name = "sTypoLineGap", kind = "int16"};
        {name = "usWinAscent", kind = "uint16"};
        {name = "usWinDescent", kind = "uint16"};
    }

local function readFields(bs, fields, res)
    res = res or {}
    
    for _, field in iparis(fields) do 
        
    end

    return res;
end
--]]

OTTableReader['OS/2'] = function(bs, toc, res)
    res = res or {}

    res.version = bs:readUInt16();

    -- Use the version to figure out how much more
    -- we should be reading.  
    -- All versions at least
    -- start with the version 0 fields, so read them first
    res.xAvgCharWidth = bs:readInt16();
    res.usWeightClass = bs:readUInt16();
    res.usWidthClass = bs:readUInt16();
    res.fsType = bs:readUInt16();
    res.ySubscriptXSize = bs:readInt16();
    res.ySubscriptYSize = bs:readInt16();
    res.ySubscriptXOffset = bs:readInt16();
    res.ySubscriptYOffset = bs:readInt16();
    res.ySuperscriptXSize = bs:readInt16();
    res.ySuperscriptYSize = bs:readInt16();
    res.ySuperscriptXOffset = bs:readInt16();
    res.ySuperscriptYOffset = bs:readInt16();
    res.yStrikeoutSize = bs:readInt16();
    res.yStrikeoutPosition = bs:readInt16();
    res.yFamilyClass = bs:readInt16();
    res.panose = bs:readBytes(10);
    res.ulUnicodeRange1 = bs:readUInt32();
    res.ulUnicodeRange2 = bs:readUInt32();
    res.ulUnicodeRange3 = bs:readUInt32();
    res.ulUnicodeRange4 = bs:readUInt32();
    res.achVendID = bs:readTag();
    res.fsSelection = bs:readUInt16();
    res.usFirstCharIndex = bs:readUInt16();
    res.usLastCharIndex = bs:readUInt16();
    res.sTypoAscender = bs:readInt16();
    res.sTypoDescender = bs:readInt16();
    res.sTypoLineGap = bs:readInt16();
    res.usWinAscent = bs:readUInt16();
    res.usWinDescent = bs:readUInt16();

    -- Subsequent versions are cumulative, so 
    -- we can add fields as we go
    -- At least version 1
    if res.version > 0 then
        res.ulCodePageRange1 = bs:readUInt32();
        res.ulCodePageRange2 = bs:readUInt32();
    end

    -- Versions 2, 3 and 4 are the same
    if res.version > 1 then
        res.sxHeight = bs:readInt16();
        res.sCapHeight = bs:readInt16();
        res.usDefaultChar = bs:readUInt16();
        res.usMaxContext = bs:readUInt16();
    end

    -- version 5 and above
    if res.version > 4 then
        res.usLowerOpticalPointSize = bs:readUInt16();
        res.usUpperOpticalPointSize = bs:readUInt16();
    end

    return res
end


return OTTableReader
