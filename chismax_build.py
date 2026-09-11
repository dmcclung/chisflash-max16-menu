#!/usr/bin/env python3
"""
Build a 32 MiB ChisFlash-MBC5 MAX (16-in-1) image.

Layout:
    0 MiB   1 MiB   menu ROM
    1 MiB   1 MiB   game 1
    2 MiB   2 MiB   game 2
    4 MiB   2 MiB   game 3
    ...
   30 MiB   2 MiB   game 16

Usage:
    python3 chismax_build.py menu.gbc game1.gb game2.gb ... -o out.gbc
"""

import argparse, os, sys

MB = 1024 * 1024
TOTAL = 32 * MB
FILL = 0xFF


def slots():
    """(index, offset, capacity) for the 16 game slots."""
    yield 1, 1 * MB, 1 * MB
    for i in range(2, 17):
        yield i, (i - 1) * 2 * MB, 2 * MB


def read(path):
    with open(path, "rb") as f:
        return f.read()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("menu")
    ap.add_argument("games", nargs="*")
    ap.add_argument("-o", "--out", default="chismax_32m.gbc")
    a = ap.parse_args()

    if len(a.games) > 16:
        sys.exit(f"error: {len(a.games)} games given, 16 slots available")

    img = bytearray([FILL] * TOTAL)
    errs = []

    menu = read(a.menu)
    if len(menu) > 1 * MB:
        errs.append(f"menu {os.path.basename(a.menu)} is {len(menu)/MB:.2f} MiB, max 1 MiB")
    else:
        img[0:len(menu)] = menu

    print(f"{'slot':>4}  {'offset':>9}  {'cap':>5}  {'size':>8}  file")
    print(f"{'menu':>4}  {'0x000000':>9}  {'1 MiB':>5}  {len(menu)/MB:6.2f}M  {os.path.basename(a.menu)}")

    placed = 0
    for (idx, off, cap), path in zip(slots(), a.games):
        data = read(path)
        name = os.path.basename(path)
        if len(data) > cap:
            errs.append(f"slot {idx}: {name} is {len(data)/MB:.2f} MiB, max {cap//MB} MiB")
            status = "TOO BIG"
        else:
            img[off:off + len(data)] = data
            placed += 1
            status = name
        print(f"{idx:>4}  {'0x%06X' % off:>9}  {str(cap//MB)+' MiB':>5}  {len(data)/MB:6.2f}M  {status}")

    if errs:
        print("\nerrors:", file=sys.stderr)
        for e in errs:
            print("  -", e, file=sys.stderr)
        sys.exit(1)

    assert len(img) == TOTAL
    with open(a.out, "wb") as f:
        f.write(img)
    print(f"\nwrote {a.out}  ({len(img)/MB:.0f} MiB, menu + {placed} game(s))")


if __name__ == "__main__":
    main()
