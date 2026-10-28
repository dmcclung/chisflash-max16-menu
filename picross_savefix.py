#!/usr/bin/env python3
"""
Make the MBC5-patched Mario's Picross keep its save on carts with no
power-fail protection on SRAM (e.g. the ChisFlash MBC5 MAX 16-in-1).

Picross enables SRAM once at boot and uses bank 0 as live work RAM, so it is
writable when the console is switched off.  Brown-out writes can then break
both of the game's checksummed copies ($A000 primary, $AD04 backup) and the
save gets wiped on the next boot.

This moves the backup copy into SRAM bank 1, which is only mapped while the
game commits or validates its save:

  commit ($1B1F): after the primary checksum is written, copy $A000-$AD03
                  (bank 0, incl. checksum) to $A000-$AD03 in bank 1
  load   ($1ADA): if bank 1's checksum and signature are valid, copy it back
                  into bank 0; otherwise fall back to the game's own primary
                  check at $1B06

Interrupts are held off by clearing IE (the game's own idiom, see $0488)
while bank 1 is mapped.  The header's RAM size becomes 32 KiB.

Input must be the MBC5-patched ROM (CRC32 3CC63AC6, from mbc5_patch.py).

Usage:
    python3 picross_savefix.py mario_picross.gb -o mario_picross_savefix.gb
"""

import argparse, sys, zlib

SRC_CRC  = 0x3CC63AC6
CODE_ORG = 0x0068          # free bytes between the IRQ vectors and $00E0
CODE_END = 0x00E0


def assemble(org, prog):
    """Tiny two-pass assembler: prog is a list of bytes/ints, ('label', name),
    ('jr', cond_opcode, name) or ('abs', opcode, name|int)."""
    labels, out = {}, []
    for pass_ in (0, 1):
        pc, out = org, []
        for item in prog:
            if isinstance(item, tuple) and item[0] == "label":
                labels[item[1]] = pc
                continue
            if isinstance(item, tuple) and item[0] == "jr":
                tgt = labels.get(item[2], pc) if pass_ else pc
                off = tgt - (pc + 2)
                if pass_ and not -128 <= off <= 127:
                    raise ValueError(f"jr to {item[2]} out of range")
                out += [item[1], off & 0xFF]
                pc += 2
                continue
            if isinstance(item, tuple) and item[0] == "abs":
                v = item[2] if isinstance(item[2], int) else labels.get(item[2], 0)
                out += [item[1], v & 0xFF, v >> 8]
                pc += 3
                continue
            out += list(item) if isinstance(item, (bytes, list)) else [item]
            pc += len(item) if isinstance(item, (bytes, list)) else 1
    return bytes(out), labels


SEL0   = [0xAF, 0xEA, 0x00, 0x40]              # xor a / ld [$4000],a
SEL1   = [0x3E, 0x01, 0xEA, 0x00, 0x40]        # ld a,1 / ld [$4000],a
IE_OFF = [0xF0, 0xFF, 0xF5, 0xAF, 0xE0, 0xFF]  # ldh a,[IE] / push af / xor a / ldh [IE],a
IE_ON  = [0xF1, 0xE0, 0xFF]                    # pop af / ldh [IE],a
COPY_SETUP = [0x21, 0x00, 0xA0,                # ld hl,$A000
              0x01, 0x04, 0x0D]                # ld bc,$0D04  (data + 2 checksum bytes)
COPY_STEP  = [0x23, 0x0B, 0x78, 0xB1]          # inc hl / dec bc / ld a,b / or c

PROG = [
    # ---- load: replaces the backup check at $1AE6 ----
    ("label", "load"),
    IE_OFF, SEL1,
    0x21, 0x00, 0xA0,                          # ld hl,$A000
    ("abs", 0xCD, 0x1B83),                     # call checksum -> d,e
    ("abs", 0xFA, 0xAD02), 0xBA,               # ld a,[$AD02] / cp d
    ("jr", 0x20, "load_bad"),
    ("abs", 0xFA, 0xAD03), 0xBB,               # ld a,[$AD03] / cp e
    ("jr", 0x20, "load_bad"),
    ("abs", 0xCD, 0x1B60),                     # call signature check (reads bank 1)
    ("jr", 0x20, "load_bad"),
    COPY_SETUP,
    ("label", "load_loop"),
    SEL1, 0x56,                                # ld d,[hl]
    SEL0, 0x72,                                # ld [hl],d
    COPY_STEP,
    ("jr", 0x20, "load_loop"),
    IE_ON,
    ("abs", 0xC3, 0x1B18),                     # jp $1B18 (signature check, ret z)
    ("label", "load_bad"),
    SEL0, IE_ON,
    ("abs", 0xC3, 0x1B06),                     # jp $1B06 (game's primary check)

    # ---- commit: replaces the backup write at $1B45 ----
    ("label", "commit"),
    IE_OFF,
    COPY_SETUP,
    ("label", "commit_loop"),
    SEL0, 0x56,                                # ld d,[hl]
    SEL1, 0x72,                                # ld [hl],d
    COPY_STEP,
    ("jr", 0x20, "commit_loop"),
    SEL0, IE_ON,
    ("abs", 0xFA, 0xAD02), 0x57,               # ld a,[$AD02] / ld d,a
    ("abs", 0xFA, 0xAD03), 0x5F,               # ld a,[$AD03] / ld e,a
    0xC9,                                      # ret  (d,e,a as the original returned)
]

# (offset, expected original bytes) -> must match before patching
HOOKS = {
    0x1AE6: bytes.fromhex("2104adcd831b"),     # ld hl,$AD04 / call $1B83
    0x1B45: bytes.fromhex("2100a01104ad"),     # ld hl,$A000 / ld de,$AD04
}


def fix_checksums(rom):
    x = 0
    for b in rom[0x134:0x14D]:
        x = (x - b - 1) & 0xFF
    rom[0x14D] = x
    g = (sum(rom) - rom[0x14E] - rom[0x14F]) & 0xFFFF
    rom[0x14E], rom[0x14F] = g >> 8, g & 0xFF


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rom")
    ap.add_argument("-o", "--out", required=True)
    a = ap.parse_args()

    rom = bytearray(open(a.rom, "rb").read())
    crc = zlib.crc32(rom) & 0xFFFFFFFF
    if crc != SRC_CRC:
        sys.exit(f"error: CRC32 {crc:08X}, expected {SRC_CRC:08X} "
                 "(the MBC5-patched Mario's Picross)")

    code, labels = assemble(CODE_ORG, PROG)
    if CODE_ORG + len(code) > CODE_END:
        sys.exit(f"error: patch is {len(code)} bytes, only {CODE_END - CODE_ORG} free")
    if any(rom[CODE_ORG:CODE_ORG + len(code)]):
        sys.exit("error: patch area is not empty")
    for off, want in HOOKS.items():
        if rom[off:off + len(want)] != want:
            sys.exit(f"error: unexpected bytes at ${off:04X}")

    rom[CODE_ORG:CODE_ORG + len(code)] = code
    for off, name in ((0x1AE6, "load"), (0x1B45, "commit")):
        rom[off:off + 3] = bytes([0xC3, labels[name] & 0xFF, labels[name] >> 8])
    rom[0x149] = 0x03                          # RAM size: 32 KiB (4 banks)
    fix_checksums(rom)

    with open(a.out, "wb") as f:
        f.write(rom)
    print(f"patch: {len(code)} bytes at ${CODE_ORG:04X} "
          f"(load ${labels['load']:04X}, commit ${labels['commit']:04X})")
    print(f"wrote {a.out}  CRC32 {zlib.crc32(rom) & 0xFFFFFFFF:08X}")


if __name__ == "__main__":
    main()
