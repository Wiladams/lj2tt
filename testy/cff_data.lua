--[[
        Adobe Techincal Note #5176
        Compact Font Format Specification

    Various data tables from the Appendices
--]]

local ffi = require("ffi")

--[[
    Appendix A

    This dictionary maps a SID (two byte code) 
    to one of the standard strings, as specified in the 
]]
local standardStrings = {
[0] = '.netdef';
[1] = 'space';
[2] = 'exclam';
[3] = 'quotedbl';
[4] = 'numbersign';
[5] = 'dollar';
[6] = 'percent';
[7] = 'ampersand';
[8] = 'quoteright';
[9] = 'parenleft';
[10] = 'parenright';
[11] = 'asterisk';
[12] = 'plus';
[13] = 'comma';
[14] = 'hyphen';
[15] = 'period';
[16] = 'slash';
[17] = 'zero';
[18] = 'one';
[19] = 'two';
[20] = 'three';
[21] = 'four';
[22] = 'five';
[23] = 'six';
[24] = 'seven';
[25] = 'eight';
[26] = 'nine';
[27] = 'colon';
[28] = 'semicolon';
[29] = 'less';
[30] = 'equal';
[31] = 'greater';
[32] = 'question';
[33] = 'at';
[34] = 'A';
[35] = 'B';
[36] = 'C';
[37] = 'D';
[38] = 'E';
[39] = 'F';
[40] = 'G';
[41] = 'H';
[42] = 'I';
[43] = 'J';
[44] = 'K';
[45] = 'L';
[46] = 'M';
[47] = 'N';
[48] = 'O';
[49] = 'P';
[50] = 'Q';
[51] = 'R';
[52] = 'S';
[53] = 'T';
[54] = 'U';
[55] = 'V';
[56] = 'W';
[57] = 'X';
[58] = 'Y';
[59] = 'Z';
[60] = 'bracketleft';
[61] = 'backlash';
[62] = 'bracketright';
[63] = 'asciicircum';
[64] = 'underscore';
[65] = 'quoteleft';
[66] = 'a';
[67] = 'b';
[68] = 'c';
[69] = 'd';
[70] = 'e';
[71] = 'f';
[72] = 'g';
[73] = 'h';
[74] = 'i';
[75] = 'j';
[76] = 'k';
[77] = 'l';
[78] = 'm';
[79] = 'n';
[80] = 'o';
[81] = 'p';
[82] = 'q';
[83] = 'r';
[84] = 's';
[85] = 't';
[86] = 'u';
[87] = 'v';
[88] = 'w';
[89] = 'x';
[90] = 'y';
[91] = 'z';
[92] = 'braceleft';
[93] = 'bar';
[94] = 'braceright';
[95] = 'asciitilde';
[96] = 'exclamdown';
[97] = 'cent';
[98] = 'sterling';
[99] = 'fraction';
[100] = 'yen';
[101] = 'florin';
[102] = 'section';
[103] = 'currency';
[104] = 'quotestring';
[105] = 'quotedblleft';
[106] = 'guillemotleft';
[107] = 'guilsinglleft';
[108] = 'guilsinglright';
[109] = 'fi';
[110] = 'fl';
[111] = 'endash';
[112] = 'dagger';
[113] = 'daggerdbl';
[114] = 'periodcentered';
[115] = 'paragraph';
[116] = 'bullet';
[117] = 'quotesinglbase';
[118] = 'quotedblbase';
[119] = 'quotedblright';
[120] = 'guillemotright';
[121] = 'ellipsis';
[122] = 'perthousand';
[123] = 'questiondown';
[124] = 'grave';
[125] = 'acute';
[126] = 'circumflex';
[127] = 'tilde';
[128] = 'macron';
[129] = 'breve';
[130] = 'dotaccent';
[131] = 'dieresis';
[132] = 'ring';
[133] = 'cedilla';
[134] = 'hungarumlaut';
[135] = 'ogonek';
[136] = 'caron';
[137] = 'emdash';
[138] = 'AE';
[139] = 'ordfeminine';
[140] = 'Lslash';
[141] = 'Oslash';
[142] = 'OE';
[143] = 'ordmasculine';
[144] = 'ae';
[145] = 'dotlessi';
[146] = 'lslash';
[147] = 'oslash';
[148] = 'oe';
[149] = 'germandbls';
[150] = 'onesuperior';
[151] = 'logicalnot';
[152] = 'mu';
[153] = 'trademark';
[154] = 'Eth';
[155] = 'onehalf';
[156] = 'plusminus';
[157] = 'Thorn';
[158] = 'onequarter';
[159] = 'divide';
[160] = 'brokenbar';
[161] = 'degree';
[162] = 'thorn';
[163] = 'threequarters';
[164] = 'twosuperior';
[165] = 'registered';
[166] = 'minus';
[167] = 'eth';
[168] = 'multiply';
[169] = 'threesuperior';
[170] = 'copyright';
[171] = 'Aacute';
[172] = 'Acircumflex';
[173] = 'Adieresis';
[174] = 'Agrave';
[175] = 'Aring';
[176] = 'Atilde';
[177] = 'Ccedilla';
[178] = 'Eacute';
[179] = 'Ecircumflex';
[180] = 'Edieresis';
[181] = 'Egrave';
[182] = 'lacute';
[183] = 'lcircumflex';
[184] = 'ldieresis';
[185] = 'lgrave';
[186] = 'Ntilde';
[187] = 'Oacute';
[188] = 'Ocircumflex';
[189] = 'Odieresis';
[190] = 'Ograve';
[191] = 'Otilde';
[192] = 'Scaron';
[193] = 'Uacute';
[194] = 'Ucircumflex';
[195] = 'Udieresis';
[196] = 'Ugrave';
[197] = 'Yacute';
[198] = 'Ydieresis';
[199] = 'Zcaron';
[200] = 'aacute';
[201] = 'acircumflex';
[202] = 'adieresis';
[203] = 'agrave';
[204] = 'aring';
[205] = 'atilde';
[206] = 'ccedilla';
[207] = 'eacute';
[208] = 'ecircumflex';
[209] = 'edieresis';
[210] = 'egrave';
[211] = 'iacute';
[212] = 'icircumflex';
[213] = 'idieresis';
[214] = 'igrave';
[215] = 'ntilde';
[216] = 'oacute';
[217] = 'ocircumflex';
[218] = 'odieresis';
[219] = 'ograve';
[220] = 'otilde';
[221] = 'scaron';
[222] = 'uacute';
[223] = 'ucircumflex';
[224] = 'udieresis';
[225] = 'ugrave';
[226] = 'yacute';
[227] = 'ydieresis';
[228] = 'zcaron';
[229] = 'exclamsmall';
[230] = 'Hungarumlautsmall';
[231] = 'dollaroldstyle';
[232] = 'dollarsuperior';
[233] = 'ampersandsmall';
[234] = 'Acutesmall';
[235] = 'parenleftsuperior';
[236] = 'parenrightsuperior';
[237] = 'twodotenleader';
[238] = 'onedotenleader';
[239] = 'zerooldstyle';
[240] = 'oneoldstyle';
[241] = 'twooldstyle';
[242] = 'threeoldstyle';
[243] = 'fouroldstyle';
[244] = 'fiveoldstyle';
[245] = 'sixoldstyle';
[246] = 'sevenoldstyle';
[247] = 'eightoldstyle';
[248] = 'nineoldstyle';
[249] = 'commasuperior';
[250] = 'threequartersemdash';
[251] = 'periodsuperior';
[252] = 'questionsmall';
[253] = 'asuperior';
[254] = 'bsuperior';
[255] = 'csuperior';
[256] = 'dsuperior';
[257] = 'esuperior';
[258] = 'isuperior';
[259] = 'lsuperior';
[260] = 'msuperior';
[261] = 'nsuperior';
[262] = 'osuperior';
[263] = 'rsuperior';
[264] = 'ssuperior';
[265] = 'tsuperior';
[266] = 'ff';
[267] = 'ffi';
[268] = 'ffl';
[269] = 'parenleftinferior';
[270] = 'parenrightinferior';
[271] = 'Circumflexsmall';
[272] = 'hyphensuperior';
[273] = 'Gravesmall';
[274] = 'Asmall';
[275] = 'Bsmall';
[276] = 'Csmall';
[277] = 'Dsmall';
[278] = 'Esmall';
[279] = 'Fsmall';
[280] = 'Gsmall';
[281] = 'Hsmall';
[282] = 'Ismall';
[283] = 'Jsmall';
[284] = 'Ksmall';
[285] = 'Lsmall';
[286] = 'Msmall';
[287] = 'NSmall';
[288] = 'Osmall';
[289] = 'Psmall';
[290] = 'Qsmall';
[291] = 'Rsmall';
[292] = 'Ssmall';
[293] = 'Tsmall';
[294] = 'Usmall';
[295] = 'Vsmall';
[296] = 'Wsmall';
[297] = 'Xsmall';
[298] = 'Ysmall';
[299] = 'Zsmall';
[300] = 'colonmonetary';
[301] = 'onefitted';
[302] = 'rupiah';
[303] = 'Tildesmall';
[304] = 'exclamdownsmall';
[305] = 'centoldstyle';
[306] = 'Lslashsmall';
[307] = 'Scaronsmall';
[308] = 'Zcaronsmall';
[309] = 'Dieresissmall';
[310] = 'Brevesmall';
[311] = 'Caronsmall';
[312] = 'Dotaccentsmall';
[313] = 'Macronsmall';
[314] = 'figuredash';
[315] = 'hypheninferior';
[316] = 'Ogoneksmall';
[317] = 'Ringsmall';
[318] = 'Cedillasmall';
[319] = 'questiondownsmall';
[320] = 'oneeighth';
[321] = 'threeeighths';
[322] = 'fiveeighths';
[323] = 'seveneighths';
[324] = 'onethird';
[325] = 'twothirds';
[326] = 'zerosuperior';
[327] = 'foursuperior';
[328] = 'fivesuperior';
[329] = 'sixsuperior';
[330] = 'sevensuperior';
[331] = 'eightsuperior';
[332] = 'ninesuperior';
[333] = 'zeroinferior';
[334] = 'oneinferior';
[335] = 'twoinferior';
[336] = 'threeinferior';
[337] = 'fourinferior';
[338] = 'fiveinferior';
[339] = 'sixinferior';
[340] = 'seveninferior';
[341] = 'eightinferior';
[342] = 'nineinferior';
[343] = 'centinferior';
[344] = 'dollarinferior';
[345] = 'periodinferior';
[346] = 'commainferior';
[347] = 'Agravesmall';
[348] = 'Aacutesmall';
[349] = 'Acircumflexsmall';
[350] = 'Atildesmall';
[351] = 'Adieresissmall';
[352] = 'Aringsmall';
[353] = 'AEsmall';
[354] = 'Ccedillasmall';
[355] = 'Egravesmall';
[356] = 'Eacutesmall';
[357] = 'Ecircumflexsmall';
[358] = 'Edieresissmall';
[359] = 'lgravesmall';
[360] = 'lacutesmall';
[361] = 'lcircumflexsmall';
[362] = 'ldieresissmall';
[363] = 'Ethsmall';
[364] = 'Ntildesmall';
[365] = 'Ogravesmall';
[366] = 'Oacutesmall';
[367] = 'Ocircumflexsmall';
[368] = 'Otildesmall';
[369] = 'Odieresissmall';
[370] = 'OEsmall';
[371] = 'Oslashsmall';
[372] = 'Ugravesmall';
[373] = 'Uacutesmall';
[374] = 'Ucircumflexsmall';
[375] = 'Udieresissmall';
[376] = 'Yacutesmall';
[377] = 'Thornsmall';
[378] = 'Ydieresissmall';
[379] = '001.000';
[380] = '001.001';
[381] = '001.002';
[382] = '001.003';
[383] = 'Black';
[384] = 'Bold';
[385] = 'Book';
[386] = 'Light';
[387] = 'Medium';
[388] = 'Regular';
[389] = 'Roman';
[390] = 'Semibold';
}

--[[
    Appendix B
    Predefined Encodings

]]
--[[
    Standard Encoding
    The position within the array is the code
    The value at that position is the SID

    So, given an encoding [0..255], you can find the SID 
    with a simple lookup

    local SID = standardEncoding[code]
    local name = standardStrings[SID]
]]
local standardEncoding = ffi.new("uint8_t[256]", {
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,                    --   0 .. 15
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,                    --  16 .. 31
     1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,16,    --  32 .. 47
    17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,    --  48 .. 63
    33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,    --  64 .. 79
    49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,    --  80 .. 95
    65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,    --  96 .. 111
    81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,0,      -- 112 .. 127

     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                    -- 128 .. 143
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                    -- 144 .. 159
      0, 96, 97, 98, 99,100,101,102,103,104,105,106,107,108,109,110,    -- 160 .. 175
      0,111,112,113,114,  0,115,116,117,118,119,120,121,122,  0,123,    -- 176 .. 191
      0,124,125,126,127,128,129,130,131,  0,132,133,  0,134,135,136,    -- 192 .. 207
    137,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,    -- 208 .. 223
      0,138,  0,139,  0,  0,  0,  0,140,141,142,143,  0,  0,  0,  0,    -- 224 .. 239
      0,144,  0,  0,  0,145,  0,  0,146,147,148,149,  0,  0,  0,  0

})

return {
    standardStrings = standardStrings;
    standardEncoding = standardEncoding;
}

