ChisFlash Menu
==============

# Overview

A custom menu ROM for the **ChisFlash MBC5 "MAX 16-in-1"** Game Boy / Game Boy Color
multicart. Lists all 16 game slots on one screen, reads each game's name straight
from its header, and can auto-boot the last game you played (with a short,
cancellable countdown) using the cart's own CPLD multicart registers.

Written in RGBDS assembly; builds to a plain 32 KB `.gb`/`.gbc` ROM.

# Features

* 16-game menu, one line per slot, no scrolling — arrow-key navigation with wrap-around
* Game names read live from each flashed ROM's header; empty slots are marked
* Auto-boot the last played game on power-on, with a ~3s on-screen countdown;
  any button cancels, holding **Select** at boot skips it entirely
* Menu remembers the last-highlighted slot across power cycles (uses the cart's
  battery-backed SRAM)
* Game launch and slot selection go through the ChisFlash CPLD's own registers —
  see the comments in `main.asm` for the full register map

# Building

Requires [RGBDS](https://rgbds.gbdev.io) and `make`.

```
make
```

produces `multicartldr-0.9.gb` and `multicartldr-0.9.gbc`.

# Acknowledgements

This started as a fork of **[NekoCart-GB](https://ncgb.zephray.me)** by Wenting Zhang
(zephray) — an open-source Game Boy flash cartridge with its own Xilinx CPLD design,
licensed GPLv3. NekoCart's `MultiCartLoader` (this repo's origin) supplied the
overall structure of the menu — the bank-switching approach, the IBM-PC character
set macros, and the low-level memory/VRAM helpers, themselves credited in the
source file headers to Jeff Frohwein / "GABY" (devrs.com). NekoCart's own CPLD and
PCB design are not part of this repository, since this project targets different
(ChisFlash) hardware; see the upstream project linked above for that original
cartridge design.

This menu's game-launch and multi-slot logic targets the **ChisFlash** MBC5
"MAX 16-in-1" cartridge's CPLD specifically — its register protocol (ROM/RAM
banking, game selection, and the reset sequence used to boot into a selected
game) was reverse-engineered from that cart's own CPLD design. ChisFlash is an
independent third-party hardware product; this repository is not affiliated
with, endorsed by, or officially supported by its maker.

# License

GNU GPLv3, inherited from the NekoCart-GB project this was forked from.

# Legalese

This project is an independent, unofficial piece of software. It is not
affiliated with, endorsed by, or sponsored by **Nintendo** or by **ChisFlash**
in any way.

Game Boy® and Game Boy Color® are registered trademarks of Nintendo. All other
trademarks are the property of their respective owners.
