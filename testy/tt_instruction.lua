local ttstream = require('ttstream')
local opcodes = {}
local actions = {}


function actions.defaultAction(vm, opcode, opentry, ms)
    print(string.format("0x%02X  %8s", opcode, opentry.name))
end


function actions.NPUSHB(vm, opcode, opentry, ms)

    local nbytes = ms:get8();
--print("NPUSHB: ", nbytes)
    if not nbytes then print("UNKNOWN", name) end

    io.write(string.format("%8s(%d) ", opentry.name, nbytes))
    for i=1,nbytes do
        io.write(string.format(" 0x%02x", ms:get8()));
    end
    io.write("\n");
end

function actions.PUSHB(vm, opcode, opentry, ms)

    local opargs = {
        ['PUSHB[0]'] = 1;
        ['PUSHB[1]'] = 2;
        ['PUSHB[2]'] = 3;
        ['PUSHB[3]'] = 4;
        ['PUSHB[4]'] = 5;
        ['PUSHB[5]'] = 6;
        ['PUSHB[6]'] = 7;
        ['PUSHB[7]'] = 8;
    }
    local nbytes = opargs[opentry.name]
    if not nbytes then print("UNKNOWN", name) end

    io.write(string.format("%8s ", opentry.name))
    for i=1,nbytes do
        io.write(string.format(" 0x%2x", ms:get8()));
    end
    io.write("\n");
end

function actions.PUSHW(vm, opcode, opentry, ms)

    local opargs = {
        ['PUSHW[0]'] = 1;
        ['PUSHW[1]'] = 2;
        ['PUSHW[2]'] = 3;
        ['PUSHW[3]'] = 4;
        ['PUSHW[4]'] = 5;
        ['PUSHW[5]'] = 6;
        ['PUSHW[6]'] = 7;
        ['PUSHW[7]'] = 8;
    }
    local nbytes = opargs[opentry.name]
    if not nbytes then print("UNKNOWN", name) end

    io.write(string.format("%8s ", opentry.name))
    for i=1,nbytes do
        io.write(string.format(" 0x%04x", ms:getInt16()));
    end
    io.write("\n");
end

opcodes[0x40] = {name = 'NPUSHB'; action = actions.NPUSHB};
opcodes[0x41] = {name = 'NPUSHW'; action = actions.NPUSHW};
opcodes[0xB0] = {name = 'PUSHB[0]'; action = actions.PUSHB};
opcodes[0xB1] = {name = 'PUSHB[1]'; action = actions.PUSHB};
opcodes[0xB2] = {name = 'PUSHB[2]'; action = actions.PUSHB};
opcodes[0xB3] = {name = 'PUSHB[3]'; action = actions.PUSHB};
opcodes[0xB4] = {name = 'PUSHB[4]'; action = actions.PUSHB};
opcodes[0xB5] = {name = 'PUSHB[5]'; action = actions.PUSHB};
opcodes[0xB6] = {name = 'PUSHB[6]'; action = actions.PUSHB};
opcodes[0xB7] = {name = 'PUSHB[7]'; action = actions.PUSHB};
opcodes[0xB8] = {name = 'PUSHW[0]'; action = actions.PUSHW};
opcodes[0xB9] = {name = 'PUSHW[1]'; action = actions.PUSHW};
opcodes[0xBA] = {name = 'PUSHW[2]'; action = actions.PUSHW};
opcodes[0xBB] = {name = 'PUSHW[3]'; action = actions.PUSHW};
opcodes[0xBC] = {name = 'PUSHW[4]'; action = actions.PUSHW};
opcodes[0xBD] = {name = 'PUSHW[5]'; action = actions.PUSHW};
opcodes[0xBE] = {name = 'PUSHW[6]'; action = actions.PUSHW};
opcodes[0xBF] = {name = 'PUSHW[7]'; action = actions.PUSHW};

opcodes[0x7F] = {name = 'AA'; action = actions.defaultAction};
opcodes[0x64] = {name = 'ABS'; action = actions.defaultAction};
opcodes[0x60] = {name = 'ADD'; action = actions.defaultAction};
opcodes[0x27] = {name = 'ALIGNPTS'; action = actions.defaultAction};
opcodes[0x3C] = {name = 'ALIGNRP'; action = actions.defaultAction};
opcodes[0x5A] = {name = 'AND'; action = actions.defaultAction};
opcodes[0x2B] = {name = 'CALL'; action = actions.defaultAction};
opcodes[0x67] = {name = 'CEILING'; action = actions.defaultAction};
opcodes[0x25] = {name = 'CINDEX'; action = actions.defaultAction};
opcodes[0x22] = {name = 'CLEAR'; action = actions.defaultAction};
opcodes[0x4F] = {name = 'DEBUG'; action = actions.defaultAction};
opcodes[0x73] = {name = 'DELTAC1,'; action = actions.defaultAction};
opcodes[0x74] = {name = 'DELTAC2'; action = actions.defaultAction};
opcodes[0x75] = {name = 'DELTAC3'; action = actions.defaultAction};
opcodes[0x5D] = {name = 'DELTAP1'; action = actions.defaultAction};
opcodes[0x71] = {name = 'DELTAP2'; action = actions.defaultAction};
opcodes[0x72] = {name = 'DELTAP3'; action = actions.defaultAction};
opcodes[0x24] = {name = 'DEPTH'; action = actions.defaultAction};
opcodes[0x62] = {name = 'DIV'; action = actions.defaultAction};
opcodes[0x20] = {name = 'DUP'; action = actions.defaultAction};
opcodes[0x59] = {name = 'EIF'; action = actions.defaultAction};
opcodes[0x1B] = {name = 'ELSE'; action = actions.defaultAction};
opcodes[0x2D] = {name = 'ENDF'; action = actions.defaultAction};
opcodes[0x54] = {name = 'EQ'; action = actions.defaultAction};
opcodes[0x57] = {name = 'EVEN'; action = actions.defaultAction};
opcodes[0x2C] = {name = 'FDEF'; action = actions.defaultAction};
opcodes[0x4E] = {name = 'FLIPOFF'; action = actions.defaultAction};
opcodes[0x4D] = {name = 'FLIPON'; action = actions.defaultAction};
opcodes[0x80] = {name = 'FLIPPT'; action = actions.defaultAction};
opcodes[0x82] = {name = 'FLIPRGOFF'; action = actions.defaultAction};
opcodes[0x81] = {name = 'FLIPRGON'; action = actions.defaultAction};
opcodes[0x66] = {name = 'FLOOR'; action = actions.defaultAction};
--opcodes[0x46 - 0x47] = {name = 'GC[a]'; action = actions.defaultAction};
opcodes[0x88] = {name = 'GETINFO'; action = actions.defaultAction};
opcodes[0x0D] = {name = 'GFV'; action = actions.defaultAction};
opcodes[0x0C] = {name = 'GPV'; action = actions.defaultAction};
opcodes[0x52] = {name = 'GT'; action = actions.defaultAction};
opcodes[0x53] = {name = 'GTEQ'; action = actions.defaultAction};
opcodes[0x89] = {name = 'IDEF'; action = actions.defaultAction};
opcodes[0x58] = {name = 'IF'; action = actions.defaultAction};
opcodes[0x8E] = {name = 'INSTCTRL'; action = actions.defaultAction};
opcodes[0x39] = {name = 'IP'; action = actions.defaultAction};
opcodes[0x0F] = {name = 'ISECT'; action = actions.defaultAction};
opcodes[0x30] = {name = 'IUP[0]'; action = actions.defaultAction};
opcodes[0x31] = {name = 'IUP[1]'; action = actions.defaultAction};
opcodes[0x1C] = {name = 'JMPR'; action = actions.defaultAction};
opcodes[0x79] = {name = 'JROF'; action = actions.defaultAction};
opcodes[0x78] = {name = 'JROT'; action = actions.defaultAction};
opcodes[0x2A] = {name = 'LOOPCALL'; action = actions.defaultAction};
opcodes[0x50] = {name = 'LT'; action = actions.defaultAction};
opcodes[0x51] = {name = 'LTEQ'; action = actions.defaultAction};
opcodes[0X8B] = {name = 'MAX'; action = actions.defaultAction};
--opcodes[0x49 - 0x4A] = {name = 'MD[a]'; action = actions.defaultAction};
opcodes[0x2E] = {name = 'MDAP[0]'; action = actions.defaultAction};
opcodes[0x2F] = {name = 'MDAP[1]'; action = actions.defaultAction};
--opcodes[0xC0 - 0xDF] = {name = 'MDRP[abcde]'; action = actions.defaultAction};
opcodes[0x3E] = {name = 'MIAP[a]'; action = actions.defaultAction};
opcodes[0x3F] = {name = 'MIAP[a]'; action = actions.defaultAction};
opcodes[0X8C] = {name = 'MIN'; action = actions.defaultAction};
opcodes[0x26] = {name = 'MINDEX'; action = actions.defaultAction};
opcodes[0xE0] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xE1] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xE2] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xE3] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xE4] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xE5] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xE6] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xE7] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xE8] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xE9] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xEA] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xEB] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xEC] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xED] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xEE] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xEF] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xF0] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xF1] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xF2] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xF3] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xF4] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xF5] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xF6] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xF7] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xF8] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xF9] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xFA] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xFB] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xFC] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xFD] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xFE] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0xFF] = {name = 'MIRP[abcde]'; action = actions.defaultAction};
opcodes[0x4B] = {name = 'MPPEM'; action = actions.defaultAction};
opcodes[0x4C] = {name = 'MPS'; action = actions.defaultAction};
--opcodes[0x3A - 0x3B] = {name = 'MSIRP[a]'; action = actions.defaultAction};
opcodes[0x63] = {name = 'MUL'; action = actions.defaultAction};
opcodes[0x65] = {name = 'NEG'; action = actions.defaultAction};
opcodes[0x55] = {name = 'NEQ'; action = actions.defaultAction};
opcodes[0x5C] = {name = 'NOT'; action = actions.defaultAction};
--opcodes[0x6C - 0x6F] = {name = 'NROUND[ab]'; action = actions.defaultAction};
opcodes[0x56] = {name = 'ODD'; action = actions.defaultAction};
opcodes[0x5B] = {name = 'OR'; action = actions.defaultAction};
opcodes[0x21] = {name = 'POP'; action = actions.defaultAction};
opcodes[0x45] = {name = 'RCVT'; action = actions.defaultAction};
opcodes[0x7D] = {name = 'RDTG'; action = actions.defaultAction};
opcodes[0x7A] = {name = 'ROFF'; action = actions.defaultAction};
opcodes[0x8a] = {name = 'ROLL'; action = actions.defaultAction};
--opcodes[0x68 - 0x6B] = {name = 'ROUND[ab]'; action = actions.defaultAction};
opcodes[0x43] = {name = 'RS'; action = actions.defaultAction};
opcodes[0x3D] = {name = 'RTDG'; action = actions.defaultAction};
opcodes[0x18] = {name = 'RTG'; action = actions.defaultAction};
opcodes[0x19] = {name = 'RTHG'; action = actions.defaultAction};
opcodes[0x7C] = {name = 'RUTG'; action = actions.defaultAction};
opcodes[0x77] = {name = 'S45ROUND'; action = actions.defaultAction};
opcodes[0x7E] = {name = 'SANGW'; action = actions.defaultAction};
opcodes[0x85] = {name = 'SCANCTRL'; action = actions.defaultAction};
opcodes[0x8D] = {name = 'SCANTYPE'; action = actions.defaultAction};
opcodes[0x48] = {name = 'SCFS'; action = actions.defaultAction};
opcodes[0x1D] = {name = 'SCVTCI'; action = actions.defaultAction};
opcodes[0x5E] = {name = 'SDB'; action = actions.defaultAction};
--opcodes[0x86 - 0x87] = {name = 'SDPVTL[a]'; action = actions.defaultAction};
opcodes[0x5F] = {name = 'SDS'; action = actions.defaultAction};
opcodes[0x0B] = {name = 'SFVFS'; action = actions.defaultAction};
--opcodes[0x04 - 0x05] = {name = 'SFVTCA[a]'; action = actions.defaultAction};
--opcodes[0x08 - 0x09] = {name = 'SFVTL[a]'; action = actions.defaultAction};
opcodes[0x0E] = {name = 'SFVTPV'; action = actions.defaultAction};
--opcodes[0x34 - 0x35] = {name = 'SHC[a]'; action = actions.defaultAction};
--opcodes[0x32 - 0x33] = {name = 'SHP[a]'; action = actions.defaultAction};
opcodes[0x38] = {name = 'SHPIX'; action = actions.defaultAction};
--opcodes[0x36 - 0x37] = {name = 'SHZ[a]'; action = actions.defaultAction};
opcodes[0x17] = {name = 'SLOOP'; action = actions.defaultAction};
opcodes[0x1A] = {name = 'SMD'; action = actions.defaultAction};
opcodes[0x0A] = {name = 'SPVFS'; action = actions.defaultAction};
opcodes[0x02] = {name = 'SPVTCA[a]'; action = actions.defaultAction};
opcodes[0x03] = {name = 'SPVTCA[a]'; action = actions.defaultAction};
--opcodes[0x06 - 0x07] = {name = 'SPVTL[a]'; action = actions.defaultAction};
opcodes[0x76] = {name = 'SROUND'; action = actions.defaultAction};
opcodes[0x10] = {name = 'SRP0'; action = actions.defaultAction};
opcodes[0x11] = {name = 'SRP1'; action = actions.defaultAction};
opcodes[0x12] = {name = 'SRP2'; action = actions.defaultAction};
opcodes[0x1F] = {name = 'SSW'; action = actions.defaultAction};
opcodes[0x1E] = {name = 'SSWCI'; action = actions.defaultAction};
opcodes[0x61] = {name = 'SUB'; action = actions.defaultAction};
opcodes[0x00] = {name = 'SVTCA[0]'; action = actions.defaultAction};
opcodes[0x01] = {name = 'SVTCA[1]'; action = actions.defaultAction};
opcodes[0x23] = {name = 'SWAP'; action = actions.defaultAction};
opcodes[0x13] = {name = 'SZP0'; action = actions.defaultAction};
opcodes[0x14] = {name = 'SZP1'; action = actions.defaultAction};
opcodes[0x15] = {name = 'SZP2'; action = actions.defaultAction};
opcodes[0x16] = {name = 'SZPS'; action = actions.defaultAction};
opcodes[0x29] = {name = 'UTP'; action = actions.defaultAction};
opcodes[0x70] = {name = 'WCVTF'; action = actions.defaultAction};
opcodes[0x44] = {name = 'WCVTP'; action = actions.defaultAction};
opcodes[0x42] = {name = 'WS'; action = actions.defaultAction};


-- Print the indicated instruction stream in human readable form
local function transcodeInstructions(ins, len)
    if not ins then return end

    local ms = ttstream(ins, len)
    while (true) do
        local opcode = ms:get8();
        if not opcode then break; end
--print(string.format("0x%02X", opcode))
        local opentry = opcodes[opcode];
        if opentry then
            if opentry.action then 
                opentry.action('vm', opcode, opentry, ms)
            else
                print(string.format("%8s", opentry.name))
            end
        else
            print(string.format("    0x%02X", opcode)); 
        end
    end
end

local exports = {
    transcode = transcodeInstructions;
}

return exports
