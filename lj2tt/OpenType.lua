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