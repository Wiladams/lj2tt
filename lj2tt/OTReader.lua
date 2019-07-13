


local binstream = require("lj2tt.binstream")

local OTReader = {}
local OTReader_mt = {
    __index = OTReader;
}

-- construct and read
function OTReader.init(self, params)
    params.bs = binstream(params.data, params.length, 0, false)

    setmetatable(params, OTReader_mt)
    params:parseData()

    return params
end

function OTReader.new(self, params)
    if not params then return nil end
    if not params.data then return nil end

    params.length = params.length or #params.data

    return self:init(params)
end

function OTReader.parseData(self)
    -- read tag
    self.fileTag = self.bs:readTag()


    -- rewind and read it as a 32-bit unsigned int
    self.bs:seek(0)
    self.sfntVersion = self.bs:readUInt32();

    -- now that we have this opening tag/value
    -- we can decide what kind of file we have.
    if self.sfntVersion == 0x00010000 then
        self.hasTTOutlines = true;
    elseif self.fileTag == "OTTO" then
        self.hasCFFData = true;
    end

    -- Additionally check to see if we have a 
    -- collection
    -- 'ttcf'

    
    self.offsetTable = self:readOffsetTable(self.bs)
    self.offsetTable.entries = self:readOffsetTableEntries(self.bs, self.offsetTable)

    return true;
end

--[[

]]
function OTReader.readOffsetTable(self, bs, res)
    res = res or {}

    res.numTables = bs:readUInt16()
    res.searchRange = bs:readUInt16();
    res.entrySelector = bs:readUInt16();
    res.rangeShift = bs:readUInt16();

    return res;
end

function OTReader.readOffsetTableEntries(self, bs, head, res)
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

return OTReader
