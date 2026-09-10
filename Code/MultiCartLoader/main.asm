; MultiCart Loader for NCGB-Standard
; Copyright 2018 Wenting Zhang (zephray@outlook.com)
; Acknowledgement:
; Based on John Harrison's starter template

INCLUDE "gbhw.inc" ; standard hardware definitions from devrs.com
INCLUDE "ibmpc1.inc" ; ASCII character set from devrs.com

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
    ; display slot string
    ld    b, 4       ; 4 slots total
    ld    hl, _SCRN0 + 2 + SCRN_VX_B * 1
.loop
    dec   b
    push  bc
    ld    d, h
    ld    e, l
    ld    hl, Slot
    ld    bc, SlotEnd - Slot
    push  de
    call  mem_CopyVRAM
    pop   de
    pop   bc
    ; hl = de + 5
    ld    hl, 5
    add   hl, de
    ; calculate slot number
    ld    a, 4 + 48
    sub   a, b
    push  bc
    ld    bc, 1
    push  hl
    call  mem_SetVRAM
    pop   hl
    ; calculate address of next line
    ld    bc, SCRN_VX_B * 4 - 5
    add   hl, bc
    pop   bc
    ld    a, b
    or    a
    jr    nz, .loop
    ; display game info
    ld    c, 0
    ld    hl, _SCRN0+3+(SCRN_VX_B*2)
    push  hl
.info_loop
    ; start from bank switching
    ld    hl, BankLUT
    ld    b, 0
    add   hl, bc
    ld    a, [hl+]
    ld    d, a
    ld    a, [hl]
    ld    hl, $3000
    ld    [hl], a
    ld    a, d
    ld    hl, $2000
    ld    [hl], a
    ; copy name to vram
    pop   de  ; fetch address from stack
    push  bc  ; backup the iterator
    push  de  ; backup
    ld    hl, $4134
    ld    bc, $F
    call  mem_CopyVRAM
    pop   de  ; fetch address
    ld    hl, SCRN_VX_B*1
    add   hl, de
    push  hl  ; store new address

    ; check cgb flag
    ld    hl, $4143
    ld    a, [hl]
    cp    a, $80
    jr    z, .game_is_cgb_compatible
    cp    a, $c0
    jr    z, .game_is_cgb_only
.game_is_mono_only
    ld    hl, Mono
    ld    bc, MonoEnd - Mono
    jr    .disp_type_string
.game_is_cgb_compatible
    ld    hl, Compatiable
    ld    bc, CompatiableEnd - Compatiable
    jr    .disp_type_string
.game_is_cgb_only
    ld    hl, Color
    ld    bc, ColorEnd - Color
.disp_type_string   
    pop   de  ; load the loading address
    push  de  ; store the loading address
    call  mem_CopyVRAM

    pop   de  ; fetch address
    pop   bc  ; restore the iterator
    ld    hl, SCRN_VX_B*3
    add   hl, de
    push  hl
    
    inc   c
    inc   c
    ld    a, $08
    cp    a, c
    jr    nz, .info_loop

    pop   hl  ; free the stack

    ; ready to turn on display
    ld    a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJOFF 
    ld    [rLCDC], a

    ; main menu
    ld    a, 0
    jr    .refresh
.wait:
    call  read_pad  ; c need to be preserved
    ld    b, a
    and   %01000000 ; up
    jr    nz, .up
    ld    a, b
    and   %10000000 ; down
    jr    nz, .down
    ld    a, b
    and   %00001001 ; A or START
    jr    nz, .enter
    ; nothing happend
    nop
    jr    .wait
.up:
    ld    a, c
    or    a
    jr    z, .wait
    dec   a
    jr    .refresh
.down:
    ld    a, c
    ld    b, 3
    cp    a, b
    jr    z, .wait
    inc   a
    jr    .refresh
.refresh:
    ld    c, a  ; update new position
    ; set arrow
    ld    b, 0
    ld    hl, _SCRN0 + 1 + SCRN_VX_B * 2
.loop_arrow
    ld    a, c
    cp    a, b
    jr    z, .load_arrow
    ld    a, $20
    jr    .show_arrow
.load_arrow
    ld    a, $10
.show_arrow
    push  bc
    ld    bc, 1
    call  mem_SetVRAM 
    ; calculate address of next line
    ld    bc, SCRN_VX_B * 4 - 1
    add   hl, bc
    pop   bc
    inc   b
    ld    a, 4
    cp    a, b
    jr    nz, .loop_arrow

.wait_key_release
    call  read_pad
    or    a
    jr    nz, .wait_key_release

    jr    .wait

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

Slot:
    DB    "Slot"
SlotEnd:

Empty:
    DB    "EMPTY"
EmptyEnd:

Mono:
    DB    "Monochrome"
MonoEnd:

Compatiable:
    DB    "Mono/Color"
CompatiableEnd:

Color:
    DB    "Color only"
ColorEnd:

BankLUT:
    ; Cartridge are divided into 16KB banks
    ; Game Split is fixed 1MB 2MB 2MB 2MB
    DB    $40, $00
    DB    $80, $00
    DB    $00, $01
    DB    $80, $01
BankLUTEnd:

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
