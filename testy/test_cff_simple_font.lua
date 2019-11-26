package.path = "../?.lua;"..package.path;

local font = require("cff_simple_font")
local binstream = require("lj2tt.binstream")
local OTTableReader = require("lj2tt.OTTableReader")

local cff_parser = OTTableReader['CFF ']
local hutil = require("hexutil")

local hex_dump = hutil.hex_dump

print("Parsing Simple Font")
local bs = binstream(font.binString, #font.binString)

hex_dump(font.binString)

--print("cff parser: ", cff_parser)
local font = cff_parser(bs)
