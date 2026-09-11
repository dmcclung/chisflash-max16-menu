#!/usr/bin/env python3
"""
Convert a Game Boy ROM's mapper to MBC5 using lesserkuma's patch database.

The GBMem-Menu_256M builder ships 387 BPS patches keyed by source ROM CRC32
that rewrite MBC1/MBC2/MBC3 bank-switching code to MBC5 equivalents. This
script applies one to a single ROM so it can be flashed to an MBC5-only cart.

Usage:
    python3 mbc5_patch.py game.gb                    # look up only
    python3 mbc5_patch.py game.gb -o game_mbc5.gb    # patch
    python3 mbc5_patch.py game.gb --patches mapper_patches_b64.js -o out.gb

Get the database with:
    curl -O https://raw.githubusercontent.com/Lesserkuma/GBMem-Menu_256M/main/res/mapper_patches_b64.js
"""

import argparse, base64, re, struct, sys, zlib, os

MBC_NAMES = {
    0x00: "ROM only", 0x01: "MBC1", 0x02: "MBC1", 0x03: "MBC1",
    0x05: "MBC2", 0x06: "MBC2",
    0x0F: "MBC3", 0x10: "MBC3", 0x11: "MBC3", 0x12: "MBC3", 0x13: "MBC3",
    0x19: "MBC5", 0x1A: "MBC5", 0x1B: "MBC5",
    0x1C: "MBC5", 0x1D: "MBC5", 0x1E: "MBC5",
}


def read_varint(b, p):
    """BPS variable-width integer."""
    data, shift = 0, 1
    while True:
        x = b[p]; p += 1
        data += (x & 0x7F) * shift
        if x & 0x80:
            return data, p
        shift <<= 7
        data += shift


def apply_bps(patch, source):
    if len(patch) < 16 or patch[:4] != b"BPS1":
        raise ValueError("not a BPS patch")
    end = len(patch) - 12
    p = 4
    src_size, p = read_varint(patch, p)
    tgt_size, p = read_varint(patch, p)
    meta_len, p = read_varint(patch, p)
    p += meta_len

    if len(source) != src_size:
        raise ValueError(f"source is {len(source)} bytes, patch expects {src_size}")

    target = bytearray(tgt_size)
    out = 0
    src_rel = 0
    tgt_rel = 0

    while p < end:
        data, p = read_varint(patch, p)
        cmd = data & 3
        length = (data >> 2) + 1

        if cmd == 0:                                    # SourceRead
            target[out:out + length] = source[out:out + length]
            out += length
        elif cmd == 1:                                  # TargetRead
            target[out:out + length] = patch[p:p + length]
            p += length
            out += length
        elif cmd == 2:                                  # SourceCopy
            data, p = read_varint(patch, p)
            src_rel += (-1 if data & 1 else 1) * (data >> 1)
            for _ in range(length):
                target[out] = source[src_rel]
                out += 1; src_rel += 1
        else:                                           # TargetCopy
            data, p = read_varint(patch, p)
            tgt_rel += (-1 if data & 1 else 1) * (data >> 1)
            for _ in range(length):
                target[out] = target[tgt_rel]
                out += 1; tgt_rel += 1

    if out != tgt_size:
        raise ValueError(f"output size mismatch: {out} != {tgt_size}")

    want_src, want_tgt, _ = struct.unpack("<III", patch[-12:])
    if zlib.crc32(source) & 0xFFFFFFFF != want_src:
        raise ValueError("source CRC32 mismatch")
    got = zlib.crc32(target) & 0xFFFFFFFF
    if got != want_tgt:
        raise ValueError(f"target CRC32 mismatch: {got:08X} != {want_tgt:08X}")
    return bytes(target)


def load_patches(path):
    for cand in ([path] if path else ["mapper_patches_b64.js", "res/mapper_patches_b64.js"]):
        if cand and os.path.exists(cand):
            text = open(cand, encoding="utf-8", errors="replace").read()
            return dict(re.findall(r'"([0-9A-Fa-f]{8})":\s*"([^"]+)"', text)), cand
    sys.exit("error: mapper_patches_b64.js not found (see --patches / docstring)")


def describe(rom, label):
    ct = rom[0x147] if len(rom) > 0x147 else None
    title = bytes(rom[0x134:0x143]).decode("ascii", "replace").rstrip("\x00 ")
    print(f"  {label:9} {len(rom)//1024:>5} KiB  cart type 0x{ct:02X} "
          f"({MBC_NAMES.get(ct, 'unknown')})  {title!r}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rom")
    ap.add_argument("-o", "--out")
    ap.add_argument("--patches", default=None)
    a = ap.parse_args()

    patches, src_path = load_patches(a.patches)
    rom = open(a.rom, "rb").read()
    crc = zlib.crc32(rom) & 0xFFFFFFFF

    print(f"database: {src_path} ({len(patches)} patches)")
    print(f"CRC32:    {crc:08X}")
    describe(rom, "input")

    key = next((k for k in patches if k.upper() == f"{crc:08X}"), None)
    if key is None:
        print("\nNo patch for this ROM. The database covers specific dumps only —")
        print("a different region or revision will have a different CRC32.")
        sys.exit(2)

    print("\nPatch found.")
    if not a.out:
        print("Re-run with -o OUTPUT to apply it.")
        return

    patched = apply_bps(base64.b64decode(patches[key]), rom)
    describe(patched, "output")
    with open(a.out, "wb") as f:
        f.write(patched)
    print(f"\nwrote {a.out}  (CRC32 verified against patch)")


if __name__ == "__main__":
    main()
