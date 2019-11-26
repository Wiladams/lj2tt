--[[
        Adobe Techincal Note #5176
        Compact Font Format Specification

    Appendix D
    Example CFF Font

    In binary format, ready for parsing.

    This appendix illustrates the CFF format with an example font.
    The font shown is a subset with just the .notdef and space
    glyphs of the Times* font program that has been renamed.  This
    font has no subrs and uses predefined encoding and charset.
]]


local data = ""
.."\x01\x00\x04\x01\x00\x01\x01\x01\x13\x41\x42\x43\x44\x45\x46\x2b"
.."\x54\x69\x6d\x65\x73\x2d\x52\x6f\x6d\x61\x6e\x00\x01\x01\x01\x1f"
.."\xf8\x1b\x00\xf8\x1c\x02\xf8\x1d\x03\xf8\x19\x04\x1c\x6f\x00\x0d"
.."\xfb\x3c\xfb\x6e\xfa\x7c\xfa\x16\x05\xe9\x11\xb8\xf1\x12\x00\x03"
.."\x01\x01\x08\x13\x18\x30\x30\x31\x2e\x30\x30\x37\x54\x69\x6d\x65"
.."\x73\x20\x52\x6f\x6d\x61\x6e\x54\x69\x6d\x65\x73\x00\x00\x00\x02"
.."\x01\x01\x02\x03\x0e\x0e\x7c\x99\xf9\x2a\x99\xfb\x76\x95\xf7\x73"
.."\x8b\x06\xf7\x9a\x93\xfc\x7c\x8c\x07\x7d\x99\xf8\x56\x95\xf7\x5e"
.."\x99\x08\xfb\x6e\x8c\xf8\x73\x93\xf7\x10\x8b\x09\xa7\x0a\xdf\x0b"
.."\xf7\x8e\x14"


local hexString = [[
 0100 0401 0001 0101 1341 4243 4445 462b
 5469 6d65 732d 526f 6d61 6e00 0101 011f
 f81b 00f8 1c02 f81d 03f8 1904 1c6f 000d
 fb3c fb6e fa7c fa16 05e9 11b8 f112 0003
 0101 0813 1830 3031 2e30 3037 5469 6d65
 7320 526f 6d61 6e54 696d 6573 0000 0002
 0101 0203 0e0e 7c99 f92a 99fb 7695 f773
 8b06 f79a 93fc 7c8c 077d 99f8 5695 f75e
 9908 fb6e 8cf8 7393 f710 8b09 a70a df0b
 f78e 14
]]

return {
    binString = data;
    hexString = hexString;
}
