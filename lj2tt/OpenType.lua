--[[
    From the OS/2 table
    Panose values
]]
local Panose = {
    [0] = "FamilyType";
    "SerifStyle",
    "Weight",
    "Proportion",
    "Contrast",
    "StrokeVariation",
    "ArmStyle",
    "LetterForm",
    "Midline",
    "XHeight",
}

-- Enumeration of Panose fields
local Panose_FamilyType = {
    [0] = "any",
    "nofit",
    "textanddisplay",
    "script",
    "decorative",
    "pictorial"
}

--[[
    Lookup flag bit enumeration
    These values apply to the 'lookupFlag' field
    of a lookupList table
]]
local lookupFlagBitfield = {
    [0x0001] = 'rightToLeft',
    [0x0002] = 'ignoreBaseGlyphs',
    [0x0004] = 'ignoreLigatures',
    [0x0008] = 'ignoreMarks',
    [0x0010] = 'useMarkFilteringSet',
    [0x00E0] = 'reserved',
    [0xff00] = 'makrAttachmentType'
}

local PlatformID = {
    [0] = "unicode",
    [1] = 'macintosh',
    [3] = 'windows',
}

local WindowsEncodingID = {
    [0] = "symbol",
    [1] = "unicode bm[",
    [2] = "shiftjis",
    [3] = "prc",
    [4] = "big5",
    [5] = "wansung",
    [6] = "johab",
    [7] = "reserved1",
    [8] = "reserved2",
    [9] = "reserved3",
    [10] = "unicode full",
} 
--[[
    Ideally there would be an easily downloadable form of the 
    following, rather than just the web page.  Need to watch for
    new features being registered.

    https://docs.microsoft.com/en-us/typography/opentype/spec/featurelist
--]]
local RegisteredFeatures = {
['aalt'] = {fName = "Above-base Substitutions"};
['abvf'] = {fName = "Above-base Forms"};
['abvm'] = {fName = "Above-base Mark Positioning"};
['abvs'] = {fName = "Above-base Substitutions"};
['afrc'] = {fName = "Alternative Fractions"};
['akhn'] = {fName = "Akhands"};
['blwf'] = {fName = "Below-base Forms"};
['blwm'] = {fName = "Below-base Mark Positioning"};
['blws'] = {fName = "Below-base Substitutions"};
['calt'] = {fName = "Contextual Alternates"};
['case'] = {fName = "Case-Sensitive Forms"};
['ccmp'] = {fName = "Glyph Composition/Decomposition"};
['cfar'] = {fName = "Conjunct Form After Ro"};
['cjct'] = {fName = "Conjunct Forms"};
['clig'] = {fName = "Contextual Ligatures"};
['cpct'] = {fName = "Centered CJK Punctuation"};
['cpsp'] = {fName = "Capital Spacing"};
['cswh'] = {fName = "Contextual Swash"};
['curs'] = {fName = "Cursive Positioning"};
-- cv01 - cv99
['cv01'] = {fName = ""};
['cv99'] = {fName = ""};
['c2pc'] = {fName = ""};
['c2sc'] = {fName = ""};
['dist'] = {fName = ""};
['dlig'] = {fName = ""};
['dnom'] = {fName = ""};
['dtls'] = {fName = ""};
['expt'] = {fName = ""};
['falt'] = {fName = ""};
['fin2'] = {fName = ""};
['fin3'] = {fName = ""};
['fina'] = {fName = ""};
['flac'] = {fName = ""};
['frac'] = {fName = ""};
['fwid'] = {fName = ""};
['half'] = {fName = ""};
['haln'] = {fName = ""};
['halt'] = {fName = ""};
['hist'] = {fName = ""};
['hkna'] = {fName = ""};
['hlig'] = {fName = ""};
['hngl'] = {fName = ""};
['hojo'] = {fName = ""};
['hwid'] = {fName = ""};
['init'] = {fName = ""};
['isol'] = {fName = ""};
['ital'] = {fName = ""};
['jalt'] = {fName = ""};
['jp78'] = {fName = ""};
['jp83'] = {fName = ""};
['jp90'] = {fName = ""};
['jp04'] = {fName = ""};
['kern'] = {fName = ""};
['lfbd'] = {fName = ""};
['liga'] = {fName = ""};
['ljmo'] = {fName = ""};
['lnum'] = {fName = ""};
['locl'] = {fName = ""};
['ltra'] = {fName = ""};
['ltrm'] = {fName = ""};
['mark'] = {fName = ""};
['med2'] = {fName = ""};
['medi'] = {fName = ""};
['mgrk'] = {fName = ""};
['mkmk'] = {fName = ""};
['mset'] = {fName = ""};
}



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
        entry.scriptTable = readScriptTable(ts)
    end


    return res
end

local function read_FeatureList(bs, res)
    
    local function readFeatureTable(bs, res)
        res = res or {}
        res.featureParams = bs:readOffset16();
        res.lookupIndexCount = bs:readUInt16();
        res.lookupListIndices = {}

        if res.lookupIndexCount > 0 then
            for i=0, res.lookupIndexCount-1 do
                res.lookupListIndices[i] = bs:readUInt16();
            end
        end

        return res;
    end

    local function readFeatureRecord(bs, res)
        res = res or {}
        res.tag = bs:readTag();
        res.featureOffset = bs:readOffset16();

        return res;
    end

    
    res = res or {}

    -- First create the table of contents
    res.featureCount = bs:readUInt16();
    res.featureRecords = {}

    if res.featureCount > 0 then
        for i=0, res.featureCount - 1 do
            res.featureRecords[i] = readFeatureRecord(bs)
        end
    end

    -- Now use the table of contents to read the actual records
    for _, entry in ipairs(res.featureRecords) do 
        local fts = bs:getRange({position = entry.featureOffset})
        entry.featureTable = readFeatureTable(fts)
    end

    return res;
end

local function read_LookupList(bs, res)

    local function readCoverageTable(bs, res)
        res = res or {}
        res.coverageFormat = bs:readUInt16();
        if res.coverageFormat == 1 then
            res.glyphCount = bs:readUInt16();
            res.glyphArray = {}
            if res.glyphCount > 0 then
                for i=0,res.glyphCount-1 do
                    res.glyphArray[i] = bs:readUInt16();
                end
            end
        elseif res.coverageFormat == 2 then
            res.rangeCount = bs:readUInt16();
            res.rangeRecords = {}
            if res.rangeCount > 0 then
                for i=0,res.rangeCount-1 do
                    -- read a range record
                    local rec = {
                        startGlyphID = bs:readUInt16();
                        endGlyphID = bs:readUInt16();
                        startCoverageIndex = bs:readUInt16();
                    }
                    res.rangeRecords[i] = rec;
                end
            end
        end

        return res;
    end

    local function readLookupTable(bs, res)
        res = res or {}
        res.lookupType = bs:readUInt16();
        res.lookupFlag = bs:readUInt16();
        res.subtableCount = bs:readUInt16();
        res.subtableOffsets = {}

        if res.subtableCount > 0 then
            for i=0,res.subtableCount-1 do
                res.subtableOffsets[i] = bs:readOffset16();
            end
        end

        -- if lookupFlag has GDEF flag set, then the
        -- fillowing field exists
        -- BUGBUG
        --res.markFilteringSet = bs:readUInt16();

        -- now we have table of contents, go read
        -- the actual subtables

        return res
    end


    res = res or {}

    -- create the table of contents
    res.lookupCount = bs:readUInt16();
    res.lookups = {}
    if res.lookupCount > 0 then
        for i=0,res.lookupCount-1 do 
            res.lookups[i] = {offset = bs:readOffset16()}
        end
    end

    -- Now read individual lookup tables
    for _, entry in ipairs(res.lookups) do
        local lts = bs:getRange({position = entry.offset})
        entry.lookup = readLookupTable(lts)
    end


    return res
end


return {
    read_ScriptList = read_ScriptList;
    read_FeatureList = read_FeatureList;
    read_LookupList = read_LookupList;
}