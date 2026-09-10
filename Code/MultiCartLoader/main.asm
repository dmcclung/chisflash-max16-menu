; MultiCart Loader for NCGB-Standard
; Copyright 2018 Wenting Zhang (zephray@outlook.com)
; Acknowledgement:
; Based on John Harrison's starter template
;
; Reworked for the ChisFlash MBC5 "MAX 16-in-1" cartridge:
;  - 16-entry single-line menu (one game per row, no scrolling)
;  - game launch uses the ChisFlash CPLD multicart registers

INCLUDE "gbhw.inc" ; standard hardware definitions from devrs.com
INCLUDE "ibmpc1.inc" ; ASCII character set from devrs.com

; WRAM scratch
DEF wRowBuf EQU _RAM         ; $C000  20-byte row build buffer
DEF wSel    EQU _RAM + 20    ; $C014  current selection (0..15)
DEF wIndex  EQU _RAM + 21    ; $C015  scratch loop counter

DEF NUM_GAMES EQU 16

; IRQs
SECTION    "Vblank", ROM0[$0040]
    reti
SECTION    "LCDC", ROM0[$0048]
    reti
SECTION    "Timer_Overflow", ROM0[$0050]
    reti
SECTION    "Serial", ROM0[$0058]
    reti
SECTION    "p1thru4", ROM0[$0060]
    reti

; ****************************************************************************************
; boot loader jumps to here.
; ****************************************************************************************
SECTION    "start", ROM0[$0100]
nop
jp    begin

; ****************************************************************************************
; ROM HEADER and ASCII character set
; ****************************************************************************************
; ROM header
    ROM_HEADER    ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE
INCLUDE "memory.asm"
TileData:
    chr_IBMPC1    1,8 ; LOAD ENTIRE CHARACTER SET

; ****************************************************************************************
; Main code Initialization:
; set the stack pointer, enable interrupts, set the palette, set the screen relative to
; the window, copy the ASCII character table, clear the screen
; ****************************************************************************************
begin:
    nop
    ld    sp, $ffff       ; set the stack pointer to highest mem location + 1
    push  hl
    push  af
    push  de
    push  bc
    cp    a, $11          ; check if the gameboy is in cgb mode
    jr    z, .init_cgb
.init_dmg:
    ld    a, %11100100    ; Window palette colors, from darkest to lightest
    ld    [rBGP], a       ; CLEAR THE SCREEN
    jr    .init_common
.init_cgb:
    ld    a, $80
    ld    [$ff68], a    ; enable CGB BGP auto-inc
    ld    hl, $ff69
    call  set_grayscale ; bg0
    ld    a, $80
    ld    [$ff6a], a
    ld    hl, $ff6b
    call  set_grayscale ; obj1
    call  set_grayscale ; obj2

.init_common:
    ld    a,0             ; SET SCREEN TO TO UPPER RIGHT HAND CORNER
    ld    [rSCX], a
    ld    [rSCY], a
    call  StopLCD         ; YOU CAN NOT LOAD $8000 WITH LCD ON
    ld    hl, TileData
    ld    de, _VRAM       ; $8000
    ld    bc, 8*256       ; the ASCII character set: 256 characters
    call  mem_CopyMono    ; load tile data
    ld    a, $20          ; ASCII FOR BLANK SPACE
    ld    hl, _SCRN0 + SCRN_VX_B * 1
    ld    bc, SCRN_VX_B * (SCRN_VY_B - 1)
    call  mem_SetVRAM
    ld    hl, Title       ; display title
    ld    de, _SCRN0+(SCRN_VX_B*0) ;
    ld    bc, TitleEnd-Title
    call  mem_CopyVRAM
    ld    hl, Foot
    ld    de, _SCRN0+(SCRN_VX_B*17) ;
    ld    bc, FootEnd-Foot
    call  mem_CopyVRAM

    ; ------------------------------------------------------------------
    ; draw all 16 game rows (LCD still off here -> fast VRAM writes)
    ;   game N (0..15) -> map row N+1 ; one line per game:
    ;     col 0     selection arrow (filled in by refresh_arrow)
    ;     col 1-2   slot number, 1-based decimal
    ;     col 4-18  15-char game name from its header ($4134)
    ;     col 19    type flag  M / C / +   (or "- EMPTY -" text if unflashed)
    ; ------------------------------------------------------------------
    xor   a
    ld    [wIndex], a
.rows_loop
    call  build_row              ; renders game wIndex into wRowBuf (20 bytes)
    ld    a, [wIndex]
    inc   a
    call  row_addr               ; -> hl = map address of that row
    ld    d, h
    ld    e, l
    ld    hl, wRowBuf
    ld    bc, 20
    call  mem_CopyVRAM
    ld    a, [wIndex]
    inc   a
    ld    [wIndex], a
    cp    NUM_GAMES
    jr    nz, .rows_loop

    ; leave a sane ROM bank mapped (menu code is all in bank 0)
    ld    a, $01
    ld    [$2000], a
    xor   a
    ld    [$3000], a

    ; initial selection + arrow
    xor   a
    ld    [wSel], a
    call  refresh_arrow

    ; ready to turn on display
    ld    a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJOFF
    ld    [rLCDC], a

    ; ------------------------------------------------------------------
    ; main menu loop
    ; ------------------------------------------------------------------
.wait:
    call  read_pad          ; a = buttons (1 = pressed)
    ld    b, a
    and   PADF_UP
    jr    nz, .nav_up
    ld    a, b
    and   PADF_DOWN
    jr    nz, .nav_down
    ld    a, b
    and   (PADF_A | PADF_START)
    jr    nz, .launch
    jr    .wait

.nav_up:
    ld    a, [wSel]
    or    a
    jr    nz, .up_dec
    ld    a, NUM_GAMES      ; wrap 0 -> 15
.up_dec:
    dec   a
    jr    .commit_sel
.nav_down:
    ld    a, [wSel]
    inc   a
    cp    NUM_GAMES         ; wrap 15 -> 0
    jr    c, .commit_sel
    xor   a
.commit_sel:
    ld    [wSel], a
    call  refresh_arrow
.key_release:
    call  read_pad
    or    a
    jr    nz, .key_release
    jr    .wait

.launch:
    ld    a, [wSel]
    ld    c, a             ; .enter expects the game index in C
    ; fall through

.enter
    ; ChisFlash MBC5 multicart game-launch sequence (see CPLD Verilog).
    ;
    ; Register map (writes snooped by the CPLD regardless of RAM enable):
    ;   $4000 D6=1 ......... arm multicart mode  (ram_bank[6] <- 1)
    ;   $B000 D3..0 = N .... game_sel <- N        (gated on ram_bank[6]==1)
    ;   $A000 D0=1 ......... game_sel_en <- 1     (gated on ram_bank[6]==1)
    ;   $4000 (any) ....... rst_clk: CPLD pulses /RST ~10ms, console reboots
    ;
    ; Once game_sel_en flips to 1 the menu ROM is unmapped from $0000-$7FFF,
    ; so the tail of the sequence has to execute from HRAM.
    di
    call  StopLCD

    ; copy the trampoline to HRAM ($FF80).  Done inline (not mem_Copy) so
    ; that C, which carries the selected game index, is preserved.
    ld    hl, GameStart
    ld    de, $ff80
    ld    b,  GameStartEnd - GameStart
.copy_trampoline
    ld    a, [hl+]
    ld    [de], a
    inc   de
    dec   b
    jr    nz, .copy_trampoline

    jp    $ff80          ; C = game index (0..15)

; ****************************************************************************************
; hard-coded data
; ****************************************************************************************
Title:
    DB    $cd, $cd, $cd, $cd
    DB    "Game on Cart"
    DB    $cd, $cd, $cd, $cd
TitleEnd:

Foot:
    DB    $cd, $cd, $cd, $cd, $cd
    DB    "zephray.me"
    DB    $cd, $cd, $cd, $cd, $cd
FootEnd:

EmptyName:
    DB    " --- EMPTY --- "   ; exactly 15 chars
EmptyNameEnd:

; Trampoline executed from HRAM ($FF80).  C = selected game index.
; After the $A000 write the menu ROM is gone; the CPLD resets the console
; a few instructions later, so this never returns.
GameStart:
    ld    a, $40
    ld    [$4000], a    ; arm multicart mode (ram_bank[6] = 1)
    ld    a, c
    ld    [$b000], a    ; game_sel = C
    ld    a, $01
    ld    [$a000], a    ; game_sel_en = 1   -- menu ROM unmaps here
    xor   a
    ld    [$4000], a    ; trigger CPLD reset pulse -> reboot into game C
.wait_reset
    jr    .wait_reset
GameStartEnd:

; StopLCD:
; turn off LCD if it is on
; and wait until the LCD is off
StopLCD:
    ld    a,[rLCDC]
    rlca                    ; Put the high bit of LCDC into the Carry flag
    ret   nc              ; Screen is off already. Exit.

; Loop until we are in VBlank

.wait:
    ld    a,[rLY]
    cp    145             ; Is display on scan line 145 yet?
    jr    nz,.wait        ; no, keep waiting

; Turn off the LCD

    ld    a,[rLCDC]
    res   7,a             ; Reset bit 7 of LCDC
    ld    [rLCDC],a

    ret

set_grayscale:
    ld    a, $ff
    ld    [hl], a
    ld    a, $7f
    ld    [hl], a
    ld    a, $b5
    ld    [hl], a
    ld    a, $56
    ld    [hl], a
    ld    a, $4a
    ld    [hl], a
    ld    a, $29
    ld    [hl], a
    ld    a, $00
    ld    [hl], a
    ld    a, $00
    ld    [hl], a
    ret

; delay 1.3ms
delay:
    ld    e, $ff ; 2 M
.wait_loop
    nop     ; 1 M
    dec   e ; 1 M
    jr    nz, .wait_loop ; 3 or 4 M
    ret     ; 4 M

; Routine reading pad
read_pad:
    ; select direction pad
    ld    a, %00100000    ; bit 4-0, 5-1 bit (on Cruzeta, no buttons)
    ld    [rP1], a

    ; read the direction pad
    ld    a, [rP1]
    ld    d, a
    call  delay
    or    a, d            ; debouncing, only both 0 lead to a 0

    and   $0F             ; only care about the bottom 4 bits.
    swap  a               ; lower and upper exchange.
    ld    b, a            ; save direction pad information in b

    ; read the buttons
    ld    a, %00010000    ; bit 4 to 1, bit 5 to 0
    ld    [rP1], a

    ; same trick
    ld    a, [rP1]
    ld    d, a
    call  delay
    or    a, d

    and   $0F             ; only care about the bottom 4 bit
    or    b               ; or make a to b

    ; we now have at A, the state of all, complement and return
    cpl
    ret

; =====================================================================
; Menu helpers
; =====================================================================

; row_addr - map address of a BG row
;   in : a  = row number (0..17)
;   out: hl = _SCRN0 + 32*a
;   clobbers: a, de
row_addr:
    ld    h, 0
    ld    l, a
    add   hl, hl        ; x2
    add   hl, hl        ; x4
    add   hl, hl        ; x8
    add   hl, hl        ; x16
    add   hl, hl        ; x32
    ld    de, _SCRN0
    add   hl, de
    ret

; set_game_bank - map a game's first 16 KB into the $4000-$7FFF window
;   in : a = game index (0..15)
;   ChisFlash layout: game 0 -> bank $040 (upper half of slot 0, 1 MB),
;                     game N>=1 -> bank N*$80 (N * 2 MB)
;   clobbers: a, b
set_game_bank:
    or    a
    jr    nz, .nz
    xor   a
    ld    [$3000], a        ; rom_bank[10:8] = 0
    ld    a, $40
    ld    [$2000], a        ; rom_bank[7:0]  = $40  -> bank $040
    ret
.nz:
    ld    b, a
    srl   a
    ld    [$3000], a        ; rom_bank[10:8] = N >> 1
    ld    a, b
    and   $01
    rrca                    ; N&1 -> $80 / $00
    ld    [$2000], a        ; rom_bank[7:0]  = $80 or $00   -> bank N*$80
    ret

; build_row - render one game's row into wRowBuf (20 bytes)
;   in : wIndex = game index (0..15)
;   clobbers: a, b, c, d, e, h, l
build_row:
    ld    a, [wIndex]
    call  set_game_bank

    ld    hl, wRowBuf
    ld    a, $20
    ld    [hl+], a                  ; col 0: blank (arrow drawn by refresh_arrow)

    ; slot number, 1-based decimal, cols 1-2
    ld    a, [wIndex]
    inc   a                         ; 1..16
    ld    b, $30                    ; '0'
.tens:
    cp    10
    jr    c, .tens_done
    sub   10
    inc   b
    jr    .tens
.tens_done:
    ld    [hl], b                   ; tens digit
    inc   hl
    add   a, $30                    ; '0'
    ld    [hl+], a                  ; ones digit
    ld    a, $20
    ld    [hl+], a                  ; col 3: blank

    ; present? -> first Nintendo-logo byte in the game window is $CE
    ld    a, [$4104]
    cp    $ce
    jr    z, .present

    ; empty slot
    ld    de, EmptyName
    ld    b, 15
.ecopy:
    ld    a, [de]
    inc   de
    ld    [hl+], a
    dec   b
    jr    nz, .ecopy
    ld    a, $20
    ld    [hl], a                   ; col 19: blank
    ret

.present:
    ld    de, $4134                 ; game title field, 15 bytes
    ld    b, 15
.ncopy:
    ld    a, [de]
    inc   de
    ld    [hl+], a
    dec   b
    jr    nz, .ncopy
    ld    a, $20
    ld    [hl], a                   ; col 19: blank
    ret

; refresh_arrow - redraw the selection-arrow column (col 0) for all rows
;   in : wSel = selected index
;   clobbers: a, b, c, d, e, h, l
refresh_arrow:
    xor   a
    ld    [wIndex], a
.aloop:
    ld    a, [wIndex]
    inc   a
    call  row_addr                  ; hl = row map address (col 0)
    ld    a, [wIndex]
    ld    b, a
    ld    a, [wSel]
    cp    b
    ld    a, $10                    ; arrow glyph
    jr    z, .have
    ld    a, $20                    ; blank
.have:
    ld    bc, 1
    call  mem_SetVRAM               ; write A to [hl]
    ld    a, [wIndex]
    inc   a
    ld    [wIndex], a
    cp    NUM_GAMES
    jr    nz, .aloop
    ret
