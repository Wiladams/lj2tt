


local binstream = require("lj2tt.binstream")
local OTFontReader = require("lj2tt.OTFontReader")

local OTReader = {}
local OTReader_mt = {
    __index = OTReader;
}

-- construct and read
function OTReader.init(self, params)
    params.bs = binstream(params.data, params.length, 0, false)

    setmetatable(params, OTReader_mt)
    local success, err = params:parseData()
    if not success then
        return nil, err
    end

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
    self.sfntVersionTag = self.bs:readTag()

    -- rewind and read it as a 32-bit unsigned int
    self.bs:seek(0)
    self.sfntVersion = self.bs:readUInt32();

    -- now that we have this opening tag/value
    -- we can decide what kind of file we have.
    if self.sfntVersion == 0x00010000 then
        self.hasTTOutlines = true;
    elseif self.sfntVersionTag == "OTTO" then
        self.hasCFFData = true;
    end

    --print(string.format("0x%08x", self.sfntVersion))
    if (not self.hasTTOutlines) and (not self.hasCFFData) then
        -- we can not deal with collections yet
        return false, "unknown file signature";
    end

    -- We have a single font in the file, so get it by 
    -- using the OTFontReader.  Need to seek back to zero
    -- again, and hand the stream to the reader
    self.bs:seek(0)

    self.fonts = {}
    local font, err = OTFontReader:createFontFromStream(self.bs)

    if not font then
        return false, err
    end

    table.insert(self.fonts, font)


    return true;
end

return OTReader
