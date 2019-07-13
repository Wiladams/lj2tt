--[[
This file parses .ttf files (truetype font)
It essentially decodes the file, providing some
convenient access to the information found witin.

This file does not do any glyph rendering.  In fact, 
beyond decoding things like the glyf table, there
is not much more in terms of higher level functions
that are done in here.

The intention is that other code, which needs to do 
things with the low level data, will use this file
to parse into a font object, and do whatever they 
need to elsewhere.
--]]



local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift
local bnot = bit.bnot;
local ttstream = require("ttstream")


local acos = math.acos;
local sqrt = math.sqrt;
local floor = math.floor;
local ceil = math.ceil;


ffi.cdef[[
   // #define your own (u)stbtt_int8/16/32 before including to override this
   typedef uint8_t   stbtt_uint8;
   typedef int8_t   stbtt_int8;
   typedef uint16_t  stbtt_uint16;
   typedef int16_t  stbtt_int16;
   typedef uint32_t    stbtt_uint32;
   typedef int32_t    stbtt_int32;
]]

--[[
    For finding the right font
]]
ffi.cdef[[

enum { // encodingID for STBTT_PLATFORM_ID_UNICODE
   STBTT_UNICODE_EID_UNICODE_1_0    =0,
   STBTT_UNICODE_EID_UNICODE_1_1    =1,
   STBTT_UNICODE_EID_ISO_10646      =2,
   STBTT_UNICODE_EID_UNICODE_2_0_BMP=3,
   STBTT_UNICODE_EID_UNICODE_2_0_FULL=4
};


enum { // encodingID for STBTT_PLATFORM_ID_MAC; same as Script Manager codes
   STBTT_MAC_EID_ROMAN        =0,   STBTT_MAC_EID_ARABIC       =4,
   STBTT_MAC_EID_JAPANESE     =1,   STBTT_MAC_EID_HEBREW       =5,
   STBTT_MAC_EID_CHINESE_TRAD =2,   STBTT_MAC_EID_GREEK        =6,
   STBTT_MAC_EID_KOREAN       =3,   STBTT_MAC_EID_RUSSIAN      =7
};



enum { // languageID for STBTT_PLATFORM_ID_MAC
   STBTT_MAC_LANG_ENGLISH      =0 ,   STBTT_MAC_LANG_JAPANESE     =11,
   STBTT_MAC_LANG_ARABIC       =12,   STBTT_MAC_LANG_KOREAN       =23,
   STBTT_MAC_LANG_DUTCH        =4 ,   STBTT_MAC_LANG_RUSSIAN      =32,
   STBTT_MAC_LANG_FRENCH       =1 ,   STBTT_MAC_LANG_SPANISH      =6 ,
   STBTT_MAC_LANG_GERMAN       =2 ,   STBTT_MAC_LANG_SWEDISH      =5 ,
   STBTT_MAC_LANG_HEBREW       =10,   STBTT_MAC_LANG_CHINESE_SIMPLIFIED =33,
   STBTT_MAC_LANG_ITALIAN      =3 ,   STBTT_MAC_LANG_CHINESE_TRAD =19
};
]]

-- Platform IDs
local TT_PLATFORM_ID_UNICODE   = 0;
local TT_PLATFORM_ID_MAC       = 1;
local TT_PLATFORM_ID_ISO       = 2;
local TT_PLATFORM_ID_MICROSOFT = 3;

-- list of valid values for 'encoding_id' for
-- TT_PLATFORM_MICROSOFT
local TT_MS_ID_SYMBOL_CS    = 0;
local TT_MS_ID_UNICODE_CS   = 1;
local TT_MS_ID_SJIS         = 2;
local TT_MS_ID_PRC          = 3;
local TT_MS_ID_BIG_5        = 4;
local TT_MS_ID_WANSUNG      = 5;
local TT_MS_ID_JOHAB        = 6;
local TT_MS_ID_RESERVED1    = 7;
local TT_MS_ID_RESERVED2    = 8;
local TT_MS_ID_RESERVED3    = 9;
local TT_MS_ID_UCS_4        = 10;

-- languageID for STBTT_PLATFORM_ID_MICROSOFT; same as LCID...
-- problematic because there are e.g. 16 english LCIDs and 16 arabic LCIDs
local TT_MS_LANG_ENGLISH     = 0x0409;  
local TT_MS_LANG_ITALIAN          = 0x0410;
local TT_MS_LANG_CHINESE        = 0x0804;  
local TT_MS_LANG_JAPANESE      = 0x0411;
local TT_MS_LANG_DUTCH          = 0x0413;  
local TT_MS_LANG_KOREAN        = 0x0412;
local TT_MS_LANG_FRENCH         = 0x040c;  
local TT_MS_LANG_RUSSIAN       = 0x0419;
local TT_MS_LANG_GERMAN         = 0x0407;  
local TT_MS_LANG_SPANISH       = 0x0409;
local TT_MS_LANG_HEBREW         = 0x040d;  
local TT_MS_LANG_SWEDISH       = 0x041D



local STBTT_ifloor = math.floor
local STBTT_iceil = math.ceil
local STBTT_sqrt =   math.sqrt
local STBTT_pow  =   math.pow
local STBTT_fmod     = math.fmod
local STBTT_cos = math.cos
local STBTT_acos = math.acos
local STBTT_fabs= math.abs

local function STBTT_malloc(x,u)  
    return ffi.new(ct,x)
end

local function STBTT_free(x,u)
    --    ((void)(u),free(x))
end

local STBTT_assert = assert
local function STBTT_strlen(x)
    return #x
--   strlen(x)
end


local function STBTT_memcpy(a,b,c)
    --memcpy
    return nil;
end

local function STBTT_memset(a,b)
    return ffi.set(a, b)
    --define STBTT_memset       memset
end




--[[
//////////////////////////////////////////////////////////////////////////////
//
// FONT LOADING
//
//
--]]

--[=[
ffi.cdef[[
// The following structure is defined publically so you can declare one on
// the stack or as a global or etc, but you should treat it as opaque.
struct stbtt_fontinfo
{
   void           * userdata;
   uint8_t  * data;              // pointer to .ttf file
   int              fontstart;         // offset of start of font

   int numGlyphs;                     // number of glyphs, needed for range checking

   int loca,head,glyf,hhea,hmtx,kern,gpos; // table locations as offset from start of .ttf
   int index_map;                     // a cmap mapping for our chosen character encoding
   int indexToLocFormat;              // format needed to map from glyph index to glyph

   stbtt__buf cff;                    // cff font data
   stbtt__buf charstrings;            // the charstring index
   stbtt__buf gsubrs;                 // global charstring subroutines index
   stbtt__buf subrs;                  // private charstring subroutines index
   stbtt__buf fontdicts;              // array of font dicts
   stbtt__buf fdselect;               // map from glyph to fontdict
};
]]
--]=]

-- commands for path drawing
local STBTT_vmove   = 1;
local STBTT_vline   = 2;
local STBTT_vcurve  = 3;
local STBTT_vcubic  = 4;



ffi.cdef[[
typedef stbtt_int16   stbtt_vertex_type;
typedef struct
{
    stbtt_vertex_type x,y,cx,cy,cx1,cy1;
    unsigned char type,padding;
} stbtt_vertex;
]]

--[[
local STBTT_MAX_OVERSAMPLE  = 8

assert(STBTT_MAX_OVERSAMPLE <= 255,  "STBTT_MAX_OVERSAMPLE cannot be > 255")


--typedef int stbtt__test_oversample_pow2[(STBTT_MAX_OVERSAMPLE & (STBTT_MAX_OVERSAMPLE-1)) == 0 ? 1 : -1];
--]]

--[[
//////////////////////////////////////////////////////////////////////////
//
// stbtt__buf helpers to parse data from file
//
--]]
ffi.cdef[[
// private structure
typedef struct
{
   uint8_t *data;
   size_t cursor;
   size_t size;
} stbtt__buf;
]]




local function stbtt__cff_get_index(b)

    local start = b.cursor;
    local count = stbtt__buf_get16(b);
    if (count > 0) then
        local offsize = stbtt__buf_get8(b);
        STBTT_assert((offsize >= 1) and (offsize <= 4));
        stbtt__buf_skip(b, offsize * count);
        stbtt__buf_skip(b, stbtt__buf_get(b, offsize) - 1);
    end
   
    return stbtt__buf_range(b, start, b.cursor - start);
end


local function stbtt__cff_int(b)

    local b0 = stbtt__buf_get8(b);
    if (b0 >= 32 and b0 <= 246) then       
        return b0 - 139;
    elseif (b0 >= 247 and b0 <= 250) then 
        return (b0 - 247)*256 + stbtt__buf_get8(b) + 108;
    elseif (b0 >= 251 and b0 <= 254) then
        return -(b0 - 251)*256 - stbtt__buf_get8(b) - 108;
    elseif (b0 == 28) then
        return stbtt__buf_get16(b);
    elseif (b0 == 29) then
        return stbtt__buf_get32(b);
    end

    STBTT_assert(false);

    return 0;
end

local function stbtt__cff_skip_operand(b) 

   local b0 = stbtt__buf_peek8(b);
   STBTT_assert(b0 >= 28);
   local v = 0;
   if (b0 == 30) then
      stbtt__buf_skip(b, 1);
      while (b.cursor < b.size) do
         v = stbtt__buf_get8(b);
         if ((bor(v, 0xF) == 0xF) or (rshift(v, 4) == 0xF)) then
            break;
         end
        end
   else 
      stbtt__cff_int(b);
   end
end

local function stbtt__dict_get(b, key)

    stbtt__buf_seek(b, 0);
    while (b.cursor < b.size) do
        local start = b.cursor; 
        local ending=0; 
        local op=0;
        while (stbtt__buf_peek8(b) >= 28) do
         stbtt__cff_skip_operand(b);
        end
        ending = b.cursor;
        op = stbtt__buf_get8(b);
        if (op == 12)  then 
            op = bor(stbtt__buf_get8(b), 0x100); 
        end
        
        if (op == key) then
            return stbtt__buf_range(b, start, ending-start);
        end
    end
    
    return stbtt__buf_range(b, 0, 0);
end

local function stbtt__dict_get_ints(b, key, outcount, out)

    local operands = stbtt__dict_get(b, key);
    local  i=0;
    while (i < outcount and operands.cursor < operands.size) do
        out[i] = stbtt__cff_int(operands);
        i = i + 1;
    end
end

local function stbtt__cff_index_count(b)
   stbtt__buf_seek(b, 0);
   return stbtt__buf_get16(b);
end

local function stbtt__cff_index_get(b, i)
   stbtt__buf_seek(b, 0);
   local count = stbtt__buf_get16(b);
   local offsize = stbtt__buf_get8(b);
   STBTT_assert((i >= 0) and (i < count));
   STBTT_assert(offsize >= 1 and offsize <= 4);
   stbtt__buf_skip(b, i*offsize);
   local start = stbtt__buf_get(b, offsize);
   local ending = stbtt__buf_get(b, offsize);
   return stbtt__buf_range(b, 2+(count+1)*offsize+start, ending - start);
end


-- BUGBUG - need to mind the signed versions
local function ttUSHORT(p) return ffi.cast('uint16_t',lshift(p[0],8) + p[1]); end
local function ttSHORT(p)  return ffi.cast('int16_t', lshift(p[0],8) + p[1]); end
local function ttULONG(p)  return ffi.cast('uint32_t', lshift(p[0],24) + lshift(p[1],16) + lshift(p[2],8) + p[3]); end
local function ttLONG(p)   return ffi.cast('int32_t',lshift(p[0],24) + lshift(p[1],16) + lshift(p[2],8) + p[3]); end


local function stbtt_tag4(p,c0,c1,c2,c3) 
    return (p[0] == c0 and p[1] == c1 and p[2] == c2 and p[3] == c3)
end

local function stbtt_tag(p,str)           
    return stbtt_tag4(p,str[0],str[1],str[2],str[3])
end

local function stbtt__isfont(font)
   -- check the version number
   if (stbtt_tag4(font, '1',0,0,0))  then return 1; end -- TrueType 1
   if (stbtt_tag(font, "typ1"))   then return true; end -- TrueType with type 1 font -- we don't support this!
   if (stbtt_tag(font, "OTTO"))   then return true; end -- OpenType with CFF
   if (stbtt_tag4(font, 0,1,0,0)) then return true; end -- OpenType 1.0
   if (stbtt_tag(font, "true"))   then return true; end -- Apple specification for TrueType fonts
   
   return false;
end







local function stbtt_GetFontOffsetForIndex_internal(font_collection, index)
    -- if it's just a font, there's only one valid index
    if (stbtt__isfont(font_collection)) then
        if index == 0 then return 0 end
        return -1;  
    end
    
    -- check if it's a TTC
    if (stbtt_tag(font_collection, "ttcf")) then
      -- version 1?
      if ((ttULONG(font_collection+4) == 0x00010000) or (ttULONG(font_collection+4) == 0x00020000)) then
         local n = ttLONG(font_collection+8);
         if (index >= n) then
            return -1;
         end
         return ttULONG(font_collection+12+index*4);
      end
    end
    
    return -1;
end

local function stbtt_GetNumberOfFonts_internal(font_collection)

   -- if it's just a font, there's only one valid font
   if (stbtt__isfont(font_collection)) then
      return 1;
   end

   -- check if it's a TTC
   if (stbtt_tag(font_collection, "ttcf")) then
      -- version 1?
      if (ttULONG(font_collection+4) == 0x00010000 or ttULONG(font_collection+4) == 0x00020000) then
         return ttLONG(font_collection+8);
      end
    end
   return 0;
end




local function stbtt_FindGlyphIndex(self, unicode_codepoint)
    -- use whatever cmap object is 
    -- attached to the font
end


local function stbtt_GetCodepointShape(info, unicode_codepoint, vertices)
   return stbtt_GetGlyphShape(info, stbtt_FindGlyphIndex(info, unicode_codepoint), vertices);
end

local function stbtt_setvertex(v, typ, x, y, cx, cy)
   v.type = typ;
   v.x = x;
   v.y = y;
   v.cx = cx;
   v.cy = cy;
end




local function stbtt_GetGlyphHMetrics(info, glyph_index)
    local advanceWidth = 0;
    local leftSideBearing = 0;

    local numOfLongHorMetrics = info.tables['hhea'].numOfLongHorMetrics; -- ttUSHORT(info.data+info.hhea + 34);
    if (glyph_index < numOfLongHorMetrics) then
      advanceWidth    = ttSHORT(info.data + info.hmtx + 4*glyph_index);
      leftSideBearing = ttSHORT(info.data + info.hmtx + 4*glyph_index + 2);
    else 
      advanceWidth    = ttSHORT(info.data + info.hmtx + 4*(numOfLongHorMetrics-1));
      leftSideBearing = ttSHORT(info.data + info.hmtx + 4*numOfLongHorMetrics + 2*(glyph_index - numOfLongHorMetrics));
    end

    return advanceWidth, leftSideBearing;
end


local function  stbtt_GetGlyphKernAdvance(info, g1, g2)
    local xAdvance = 0;

    if (info.gpos ~= 0) then
      xAdvance = xAdvance + stbtt__GetGlyphGPOSInfoAdvance(info, g1, g2);
    end

    if (info.kern ~= 0) then
      xAdvance = xAdvance + stbtt__GetGlyphKernInfoAdvance(info, g1, g2);
    end

    return xAdvance;
end

local function  stbtt_GetCodepointKernAdvance(info, ch1, ch2)

   if (info.kern == 0 and info.gpos~=0) then -- if no kerning table, don't waste time looking up both codepoint.glyphs
      return nil;
   end

   return stbtt_GetGlyphKernAdvance(info, stbtt_FindGlyphIndex(info,ch1), stbtt_FindGlyphIndex(info,ch2));
end

-- return : advance, leftSideBearing
local function stbtt_GetCodepointHMetrics(info, codepoint)
   return stbtt_GetGlyphHMetrics(info, stbtt_FindGlyphIndex(info,codepoint));
end

local function stbtt_GetFontVMetrics(info)
    -- ascent, descent, lineGap
    return ttSHORT(info.data+info.hhea + 4),
        ttSHORT(info.data+info.hhea + 6),
        ttSHORT(info.data+info.hhea + 8)
end

local function  stbtt_GetFontVMetricsOS2(font)
    local tab = font.tables["OS/2"]
    if not tab then return false; end

    return tab.typeAscent, typeDescent, typeLineGap;
end

--[[
local function stbtt_GetFontBoundingBox(info )
    -- int *x0, int *y0, int *x1, int *y1
    return ttSHORT(info.data + info.head + 36),
        ttSHORT(info.data + info.head + 38),
        ttSHORT(info.data + info.head + 40),
        ttSHORT(info.data + info.head + 42);
end
--]]

local function stbtt_ScaleForPixelHeight(info, height)

   local fheight = ttSHORT(info.data + info.hhea + 4) - ttSHORT(info.data + info.hhea + 6);
   return height / fheight;
end


local function stbtt_ScaleForMappingEmToPixels(info, pixels)
   local unitsPerEm = ttUSHORT(info.data + info.head + 18);
   return pixels / unitsPerEm;
end
--[[
local function stbtt_FreeShape(info, v)
   STBTT_free(v, info.userdata);
end
--]]

local function stbtt_GetFontOffsetForIndex(data, index)

   return stbtt_GetFontOffsetForIndex_internal(data, index);   
end

local function stbtt_GetNumberOfFonts(data)

   return stbtt_GetNumberOfFonts_internal(data);
end


-- The fontinfo object
local Font = {}
-- Create a default constructor
setmetatable(Font, {
	__call = function(self, ...)
		return self:new(...);
	end,
})
local Font_mt = {
    __index = stbtt_fointinfo;
}

--[[
    Required headers
    cmap
    head
    hhea
    hmtx
    maxp
    name
    OS/2
    post

    TrueType outlines
    cvt
    fpgm
    glyf
    loca
    prep
    gasp
]]
local function hasRequiredHeaders(self)
    -- first check all required headers are in place
    if not (self.tables["cmap"] and 
        self.tables["head"] and 
        self.tables["hhea"] and
        self.tables["hmtx"]) then
            return false;
        end

    return true;
end

local function stbtt_InitFont_internal(self)
   --self.cff = stbtt__new_buf(nil, 0);

   if (self.tables["glyf"]) then
      -- required for truetype
      if (not self.tables["loca"]) then 
        return false;
      end
    else
      -- initialization for CFF / Type2 fonts (OTF)
      local b = ffi.new('stbtt__buf');
      local topdict = ffi.new('stbtt__buf');
      local topdictidx = ffi.new('stbtt__buf');
      local cstype = 2;
      local charstrings = 0;
      local fdarrayoff = 0; 
      local fdselectoff = 0;
      local cff=0;

      local cff = self.tables["CFF "]
      if (not cff) then 
        return false;
      end

      self.fontdicts = stbtt__new_buf(nil, 0);
      self.fdselect = stbtt__new_buf(nil, 0);
  
      -- @TODO this should use size from table (not 512MB)
      self.cff = stbtt__new_buf(self.data+cff, 512*1024*1024);
      b = self.cff;

      -- read the header
      stbtt__buf_skip(b, 2);
      stbtt__buf_seek(b, stbtt__buf_get8(b)); -- hdrsize

      -- @TODO the name INDEX could list multiple fonts,
      -- but we just use the first one.
      stbtt__cff_get_index(b);  -- name INDEX
      topdictidx = stbtt__cff_get_index(b);
      topdict = stbtt__cff_index_get(topdictidx, 0);
      stbtt__cff_get_index(b);  -- string INDEX
      self.gsubrs = stbtt__cff_get_index(b);
  --[[
      stbtt__dict_get_ints(topdict, 17, 1, &charstrings);
      stbtt__dict_get_ints(topdict, 0x100 | 6, 1, &cstype);
      stbtt__dict_get_ints(topdict, 0x100 | 36, 1, &fdarrayoff);
      stbtt__dict_get_ints(topdict, 0x100 | 37, 1, &fdselectoff);
      info.subrs = stbtt__get_subrs(b, topdict);

      // we only support Type 2 charstrings
      if (cstype != 2) return 0;
      if (charstrings == 0) return 0;

      if (fdarrayoff) {
         // looks like a CID font
         if (!fdselectoff) return 0;
         stbtt__buf_seek(b, fdarrayoff);
         info.fontdicts = stbtt__cff_get_index(b);
         info.fdselect = stbtt__buf_range(b, fdselectoff, b.size-fdselectoff);
      }
--]]
      stbtt__buf_seek(b, charstrings);
      self.charstrings = stbtt__cff_get_index(b);
    end

   local cmap = self.tables['cmap'];

    self.index_map = 0;
    local i = 0;
    while (i < self.numTables) do
        local encoding_record = cmap.offset + 4 + 8 * i;
        -- find an encoding we understand:
        local enc = ttUSHORT(self.data+encoding_record);
        if enc == TT_PLATFORM_ID_MICROSOFT then
            local msfteid = ttUSHORT(self.data+encoding_record+2)
            if msfteid == TT_MS_ID_UNICODE_CS or
                msfteid == TT_MS_ID_UNICODE_FULL then
                    -- MS/Unicode
                self.index_map = cmap.offset + ttULONG(self.data+encoding_record+4);
            end

        elseif enc == TT_PLATFORM_ID_UNICODE then
                -- Mac/iOS has these
                -- all the encodingIDs are unicode, so we don't bother to check it
                self.index_map = cmap.offset + ttULONG(self.data+encoding_record+4);
        end

        i = i + 1;
    end

    if (self.index_map == 0) then
        return false;
    end

    return true;
end


function Font.new(self, params)
	local obj = params or {}

    obj.data = obj.data or nil;
    obj.userdata = obj.userdata or nil;
    obj.fontstart = obj.fontstart or 0;
    obj.numGlyphs = obj.numGlyphs or 0;
    obj.index_map = obj.index_map or 0;
    obj.indexToLocFormat = obj.indexToLocFormat or 0;

    -- offsets from start of file to a few tables
    if obj.data ~= nil then
        obj.tables = Font.readTableDirectory(obj);
 
        -- check to make sure the font has the required headers
        assert(hasRequiredHeaders(obj))

        -- parse the non-dependent tables here
        Font.readTable_maxp(obj.tables['maxp'])
        Font.readTable_head(obj.tables['head'])
        Font.readTable_hhea(obj, obj.tables['hhea'])
        Font.readTable_name(obj.tables['name'])
    end

    
    -- After reading table directory, set some values
    local maxp = obj.tables["maxp"];
    local head = obj.tables['head'];
    local hhea = obj.tables['hhea'];

    if hhea then
        obj.ascent = hhea.ascent
        obj.descent = hhea.descent
        obj.lineGap = hhea.lineGap
    end

    if (maxp) then
        obj.numGlyphs = maxp.numGlyphs;
     else
        obj.numGlyphs = 0;
     end
     
    if head then
        obj.indexToLocFormat = head.indexToLocFormat;
    end


    -- parse required tables
    -- this MUST happen after we've lifted some values up 
    -- into the obj as they are dependent
    Font.readTable_cmap(obj, obj.tables['cmap'])
    Font.readTable_loca(obj, obj.tables['loca'])     -- depends on 'head'
    Font.readTable_glyf(obj, obj.tables['glyf'])     -- depends on 'loca'


    stbtt_InitFont_internal(obj)

--[[
    stbtt__buf cff;                    // cff font data
    stbtt__buf charstrings;            // the charstring index
    stbtt__buf gsubrs;                 // global charstring subroutines index
    stbtt__buf subrs;                  // private charstring subroutines index
    stbtt__buf fontdicts;              // array of font dicts
    stbtt__buf fdselect;               // map from glyph to fontdict
--]] 

    setmetatable(obj, Font_mt);
    return obj;
end


-- function used to calculate a table's checksum
-- This is useful to confirm the integrity of the
-- table data
local function CalcTableChecksum(tbl, numberOfBytesInTable)
    local sum = ffi.cast('uint32_t',0);
    local tblptr = ffi.cast('uint32_t *', tbl)
    local nLongs = (numberOfBytesInTable + 3) / 4;
    while (nLongs > 0) do
        sum = sum + table[0];
        tableptr = tblptr + 1;
        nLongs = nLongs - 1;
    end

    return sum;
end

--[[
    readTableDirectory(data, fontstart)

    Get the offset and length information
    for all of the tables that are in a font

    The offset subtable is the first thing in the font.
    We'll fill in all the attributes, including the
    offsets table.
]]
function Font.readTableDirectory(self)
    local ms = ttstream(self.data, self.length);

    self.scalerTag = ms:getString(4);  -- ms:getUInt32();
    ms:seek(0);
    self.scalerType = ms:getUInt32();
    self.numTables = ms:getUInt16();
    self.searchRange = ms:getUInt16();
    self.entrySelector = ms:getUInt16();
    self.rangeShift = ms:getUInt16();
    
    if self.numTables < 1 then return nil end
    
    local res = {}
    local i = 0;
    while (i < self.numTables) do
        local tag = ms:getString(4);
        res[tag] = {
            tag = tag, 
            index = i;
            checksum = ms:getUInt32();
            offset = ms:getUInt32();
            length = ms:getUInt32();
        }
        res[tag].data = self.data + res[tag].offset;

        i = i + 1;
    end

    return res;
end

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
    ms:seek(encodingRecord.offset)
    
    -- Table of functions for reading formats
    -- The index to the table is the cmap sub-table format
    local formatMapper = {
        [0] = function(er)
            print("CMAP FORMAT 0")
            er.length = ms:getUInt16();
            er.language = ms:getUInt16();
            er.index_map = ffi.new("uint8_t[?]", 256);

            for i=0,255 do
                er.index_map[i] = ms:getUInt8();
            end
        end;

        [4] = function(er)
            print("CMAP FORMAT 4");
            er.length = ms:getUInt16();
            er.language = ms:getUInt16();
            -- and a whole lot more!!
        end;

        [6] = function(er)
            er.length = ms:getUInt16();
            er.language = ms:getUInt16();
            er.firstCode = ms:getUInt16();
            er.entryCount = ms:getUInt16();
            er.index_map = ffi.new("uint16_t[?]", er.entryCount);

            for i=0,er.entryCount-1 do
                index_map[i] = ms:getUInt16();
            end
        end;
    }
    
    -- Get the format of the encoding record
    -- which will determine the remaining fields
    encodingRecord.format = ms:getUInt16();

    local formatter = formatMapper[encodingRecord.format]
    if not formatter then return false end

    -- Execute the formatter
    formatter(encodingRecord);


    return encodingRecord
end

function Font.readTable_cmap(self, tbl)
    local ms = ttstream(tbl.data, tbl.length);

    tbl.version = ms:getUInt16();
    tbl.numTables = ms:getUInt16();     -- Number of encoding tables
    tbl.encodings = {};

    -- Read 'numTables' worth of encoding records
    for i=1, tbl.numTables do
        local platformID = ms:getUInt16();

        local encodingRecord = {
            platformID = platformID;
            encodingID = ms:getUInt16();
            offset = ms:getUInt32();
        };

        -- Now that we have an offset
        -- we can read the details of the encoding
        read_cmap_format(tbl, encodingRecord);

        if not tbl.encodings[platformID] then
            print("NEW PLATFORM ID: ", platformID)
            tbl.encodings[platformID] = {}
        end

        table.insert(tbl.encodings[platformID], encodingRecord);
    end
end



function Font.readTable_head(self)
    if not self then return false end

    local ms = ttstream(self.data, self.length);

    self.version = ms:getFixed();
    self.fontRevision = ms:getFixed();
    self.checksumAdjustment = ms:getUInt32();
    self.magicNumber = ms:getUInt32();
    self.flags = ms:getUInt16();
    self.unitsPerEm = ms:getUInt16();
    -- self.created = ms:getLongDateTime();
    -- self.modified = ms:getLongDateTime();
    ms:skip(16); 
    self.xMin = ms:getFWord();
    self.yMin = ms:getFWord();
    self.xMax = ms:getFWord();
    self.yMax = ms:getFWord();
    self.macStyle = ms:getUInt16();
    self.lowestRecPPEM = ms:getUInt16();
    self.fontDirectionHint = ms:getInt16();
    self.indexToLocFormat = ms:getInt16();
    self.glyphDataFormat = ms:getInt16();

    return self;
end

function Font.readTable_hhea(self, tbl)
    local ms = ttstream(tbl.data, tbl.length);

    tbl.version = ms:getFixed(); -- ttULONG(tbl.data+0);
    tbl.ascent = ms:getFWord();    -- tonumber(ttSHORT(tbl.data+4));
    tbl.descent = ms:getFWord();    -- tonumber(ttSHORT(tbl.data+6));
    tbl.lineGap = ms:getFWord();    -- ttSHORT(tbl.data+8);
    tbl.advanceWidthMax = ms:getUFWord();   -- ttSHORT(tbl.data+10);
    tbl.minLeftSideBearing = ms:getFWord();  -- ttSHORT(tbl.data+12);
    tbl.minRightSideBearing = ms:getFWord();    -- ttSHORT(tbl.data+14);
    tbl.xMaxExtent = ms:getFWord(); -- ttSHORT(tbl.data+16);
    tbl.caretSlopeRise = ms:getInt16();     -- tonumber(ttSHORT(tbl.data+18));
    tbl.caretSlopeRun = ms:getInt16();      -- tonumber(ttSHORT(tbl.data+20));
    tbl.caretOffset = ms:getInt16();        -- tonumber(ttSHORT(tbl.data+22));
    --reserved - ttSHORT
    --reserved - ttSHORT
    --reserved - ttSHORT
    --reserved - ttSHORT
    ms:skip(8);
    tbl.metricDataFormat = ms:getInt16();       
    tbl.numOfLongHorMetrics = ms:getUInt16();    

    return tbl
end

function Font.readTable_loca(self, tbl)
    local numGlyphs = self.numGlyphs
    local locformat = self.indexToLocFormat
    local ms = ttstream(tbl.data, tbl.length);

    tbl.offsets = {}

    if locformat == 0 then
        for i = 0, numGlyphs-1 do
            tbl.offsets[i] = ms:getUInt16()*2;
        end
    elseif locformat == 1 then
        for i = 0, numGlyphs-1 do
            tbl.offsets[i] = ms:getUInt32();
        end
    end

    return tbl
end

-- Read the contents of the 'maxp' table
function Font.readTable_maxp(self)
    if not self then return false end

    local ms = ttstream(self.data, self.length);

    self.version = ms:getFixed() -- ttULONG(self.data+0);
    self.numGlyphs = ms:getUInt16(); -- tonumber(ttUSHORT(self.data+4));
    self.maxPoints = ms:getUInt16(); -- ttUSHORT(self.data+6);
    self.maxContours = ms:getUInt16(); -- ttUSHORT(self.data+8);
    self.maxComponentPoints = ms:getUInt16(); -- ttUSHORT(self.data+10);
    self.maxComponentContours = ms:getUInt16(); -- ttUSHORT(self.data+12);
    self.maxZones = ms:getUInt16(); -- ttUSHORT(self.data+14);
    self.maxTwilightPoints = ms:getUInt16(); -- ttUSHORT(self.data+16);
    self.maxStorage = ms:getUInt16(); -- ttUSHORT(self.data+18);
    self.maxFunctionDefs = ms:getUInt16(); -- ttUSHORT(self.data+20);
    self.maxInstructionDefs = ms:getUInt16(); -- ttUSHORT(self.data+22);
    self.maxStackElements = ms:getUInt16();  -- ttUSHORT(self.data+24);
    self.maxSizeOfInstructions = ms:getUInt16(); -- ttUSHORT(self.data+26);
    self.maxComponentElements = ms:getUInt16(); -- ttUSHORT(self.data+28);
    self.maxComponentDepth = ms:getUInt16(); -- ttUSHORT(self.data+30);

    return self;
end

--[[
    the glyf table contains the contours associated with each glyf
    This is by far the most important and challenging table to read.
    First, the table depends on the 'loca' table to know where the
    offset is for a given glyph, so that must have already been read in.

    Each glyph has contours, or composit information, and/or
    hinting instructions.

    Step by step, but by bit
]]
-- FLAG values for glyph
local TT_GLYF_ON_CURVE  = 1;
local TT_GLYF_X_IS_BYTE = 2;
local TT_GLYF_Y_IS_BYTE = 4;
local TT_GLYF_REPEAT    = 8;
local TT_GLYF_X_DELTA   = 16;
local TT_GLYF_Y_DELTA   = 32;



function Font.readSimpleGlyph(self, glyph, ms)
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
        glyph.contourEnds[cnt] = ms:getUInt16()
        --debugit(26, glyph, "END: %d",glyph.contourEnds[cnt])
    end

    -- We now know how many bytes of instruction there are, so load that 
    glyph.instructionLength = ms:getUInt16();
    --print("INSTRUCTIONLENGTH: ", glyph.instructionLength)
    --glyph.instructions = ms:getString(glyph.instructionLength);
    glyph.instructions = ms:getBytes(glyph.instructionLength);

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
        local flag = ms:getUInt8();
        assert(flag)
        --debugit(26, glyph, "FLAG: %d  0x%04x", i, flag)

        glyph.flags[offset] = flag;     
        glyph.coords[offset] = {onCurve = band(flag,TT_GLYF_ON_CURVE) ~= 0 }
        offset = offset + 1;

        -- repeat only applies to the
        -- flags themselves, so we do the expansion
        -- and increment the loop counter accordingly
        if band(flag, TT_GLYF_REPEAT) > 0 then
            local repeatCount = ms:get8();
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
                    value = value + ms:getUInt8();
                else
                    value = value - ms:getUInt8();
                end
            elseif same then
                -- value is unchanged.
            else
                --print("DELTA")
                value = value + ms:getInt16();
            end

            glyph.coords[i][name] = value;
            i = i + 1;
        end
    end

    --print("I: Points: ", glyph.index, numPoints)
    readCoords("x", TT_GLYF_X_IS_BYTE, TT_GLYF_X_DELTA, glyph.xMin, glyph.xMax);
    readCoords("y", TT_GLYF_Y_IS_BYTE, TT_GLYF_Y_DELTA, glyph.yMin, glyph.yMax);
end

function Font.readTable_glyf(self, tbl)
    local numGlyphs = self.numGlyphs

    local offsets = self.tables['loca'].offsets
    local tbldata = tbl.data;
    local ms = ttstream(tbl.data, tbl.length);

    --print("readTable_glyf.NUMGLYPHS: ", numGlyphs, tbldata, offsets)

    tbl.glyphs = {}
    local glyphs = tbl.glyphs

    local i = 0;
    while i < numGlyphs-2 do
        --local offset = offsets[i];
        --print("OFFSET: ", offsets[i])
        ms:seek(offsets[i])

        local glyph = {
            index = i;
            numberOfContours = ms:getInt16();
            xMin = ms:getInt16();
            yMin = ms:getInt16();
            xMax = ms:getInt16();
            yMax = ms:getInt16();
            };

        -- Based on the number of contours, we can figure out if 
        -- this is a simple glyph, or a compound glyph (combo of glyphs)
        -- contours < 0    glyph comprised of components
        -- contours == 0    has no glyph data, could be components (-1 recommended)
        -- contours > 1
        local contourCount = glyph.numberOfContours
        if contourCount > 0 then
            Font.readSimpleGlyph(self, glyph, ms)
        elseif contourCount < 0 then
            -- composite glyph
        end

        glyphs[i] = glyph;
        --table.insert(glyphs, glyph)
        
        i = i + 1;
    end

    --print("readTabke_glyf: FINISHED")
    return tbl
end


--[[
    Reading the name table

    Name values can be in various encodings (not necessarily ASCII), but
    that's ok because Lua is byte agnostic with respect to 'string' values.
    As long as we know the length of the 'string' (which we do), there's 
    no problem encapsulating it in a lua string.
]]
function Font.readTable_name(tbl)
    local ms = ttstream(tbl.data, tbl.length);
    tbl.format = ms:getUInt16();
    tbl.count = ms:getUInt16();
    tbl.stringOffset = ms:getUInt16();
    tbl.names = {}

    --print("==== readTable_name: ", tbl, tbl.name, tbl.count)
    
    -- for the number of name record entries...
    local i=0
    while (i < tbl.count ) do
        --local base = tbl.data+6 + 12*(i);
        local rec = {
            platformID = ms:getUInt16();
            platformSpecificID = ms:getUInt16();
            languageID = ms:getUInt16();
            nameID = ms:getUInt16();
            length = ms:getUInt16();
            offset = ms:getUInt16();
        }
        
        rec.value = ffi.string(tbl.data+tbl.stringOffset+rec.offset, rec.length)

        table.insert(tbl.names, rec)
        
        i = i + 1;
    end

    return tbl
end

local exports = {
    Font = Font;
}

return exports