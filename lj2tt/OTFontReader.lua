--[[
-- Read an individual font
-- Within this file, we do not assume we're reading a OpenType
-- file from the beginning.  We assume we are at the beginning of
-- a font entry within the file.  This allows us to use the same
-- code in a collection.  Something else determines when to call
-- this code, and that thing decides when we're in a collection or not

The reader will generate a OTFont object, it is NOT a OTFont object
itself.  You can call OTFontReader:createFromStream(stream)
and you'll get back a OTFont, or nil.
--]]
local OTTableReader = require("lj2tt.OTTableReader")

local OTFontReader = {}
local OTFontReader_mt = {
    __index = OTFontReader;
}

function OTFontReader.init(self, params)
    params = params or {}
    setmetatable(params, OTFontReader_mt)

    return params
end

function OTFontReader.new(self, params)
    return self:init(params)
end

local function parseTable( font, stream, name, force)
    local toc = font.offsetTable.entries

    local entry = toc[name]
    if not entry then
        return false, 'could not find table in toc'
    end

    local reader = OTTableReader[entry.tag]
    if not reader then
        return false, 'could not find table reader'
    end

    local substream = stream:range(entry.length, entry.offset)

    local res, err = reader(substream, toc, entry)
    entry.PARSED = true;

    return entry
end

function OTFontReader.createFontFromStream(self, stream)
    local font = OTFontReader:new()

    font.offsetTable = self:readOffsetTable(stream)

    -- Now that we have the table of contents, we want to 
    -- parse the data that's in each individual table
    -- as some tables are dependent on others, parse the 
    -- independent tables first
    parseTable(font, stream, 'head', true)
    --parseTable(font, stream, 'maxp', true)
    parseTable(font, stream,  'hhea', true)
    parseTable(font, stream, 'name', true)

    -- Now that we have the independent tables, we can parse
    -- the rest of the tables

    return font
end


local SCALER_TRUETYPE   = 0x00010000;
local SCALER_OTTO       = 0x4F54544F;

function OTFontReader.readOffsetTable(self, bs, res)
    res = res or {}
    
    local startat = bs:tell()
    -- read the version, should be 0x00010000
    -- or 'OTTO' in Tag form
    res.sfntVersion = bs:readUInt32();
    if res.sfntVersion ~= SCALER_TRUETYPE and
        res.sfntVersion ~= SCALER_OTTO then
        return nil, "Unknown sfntVersion: "..string.format("0x%08x",res.sfntVersion)
    end

    res.numTables = bs:readUInt16()
    res.searchRange = bs:readUInt16();
    res.entrySelector = bs:readUInt16();
    res.rangeShift = bs:readUInt16();

    res.entries = self:readOffsetTableEntries(bs, res)

    return res;
end

function OTFontReader.readOffsetTableEntries(self, bs, head, res)
    res = res or {}

    local i = 0;
    while (i < head.numTables) do
        local tag = bs:readTag();
        res[tag] = {
            tag = tag, 
            index = i;
            checksum = bs:readUInt32();
            offset = bs:readOffset32();
            length = bs:readUInt32();
        }
        res[tag].data = bs.data + res[tag].offset;

        i = i + 1;
    end

    return res
end


return OTFontReader
