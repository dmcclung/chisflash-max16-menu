;*
;* GBHW.INC - Gameboy Hardware definitions for GALP
;*
;* by GABY. Inspired from work done by Carsten Sorensen & others.
;*
;* V1.0 - The original version
;*

; If all of these are already defined, don't do it again.

        IF      !DEF(HARDWARE_INC)
DEF HARDWARE_INC EQU 1

; (legacy rev_Check_hardware_inc macro removed: unused, and its float
;  comparison syntax is not accepted by modern RGBDS)

DEF _HW EQU $FF00

DEF _VRAM EQU $8000 ; $8000->$A000
DEF _SCRN0 EQU $9800 ; $9800->$9BFF
DEF _SCRN1 EQU $9C00 ; $9C00->$9FFF
DEF _RAM EQU $C000 ; $C000->$E000
DEF _HRAM EQU $F800 ; $F800->$FFFE
DEF _OAMRAM EQU $FE00 ; $FE00->$FE9F
DEF _AUD3WAVERAM EQU $FF30 ; $FF30->$FF3F


; --
; -- OAM flags
; --

DEF OAMF_PRI EQU %10000000 ; Priority
DEF OAMF_YFLIP EQU %01000000 ; Y flip
DEF OAMF_XFLIP EQU %00100000 ; X flip
DEF OAMF_PAL0 EQU %00000000 ; Palette number; 0,1
DEF OAMF_PAL1 EQU %00010000 ; Palette number; 0,1


;***************************************************************************
;*
;* Custom registers
;*
;***************************************************************************

; --
; -- P1 ($FF00)
; -- Register for reading joy pad info.    (R/W)
; --
DEF rP1 EQU $FF00

DEF P1F_5 EQU %00100000 ; P15 out port
DEF P1F_4 EQU %00010000 ; P14 out port
DEF P1F_3 EQU %00001000 ; P13 in port
DEF P1F_2 EQU %00000100 ; P12 in port
DEF P1F_1 EQU %00000010 ; P11 in port
DEF P1F_0 EQU %00000001 ; P10 in port


; --
; -- LCDC ($FF40)
; -- LCD Control (R/W)
; --
DEF rLCDC EQU $FF40

DEF LCDCF_OFF EQU %00000000 ; LCD Control Operation
DEF LCDCF_ON EQU %10000000 ; LCD Control Operation
DEF LCDCF_WIN9800 EQU %00000000 ; Window Tile Map Display Select
DEF LCDCF_WIN9C00 EQU %01000000 ; Window Tile Map Display Select
DEF LCDCF_WINOFF EQU %00000000 ; Window Display
DEF LCDCF_WINON EQU %00100000 ; Window Display
DEF LCDCF_BG8800 EQU %00000000 ; BG & Window Tile Data Select
DEF LCDCF_BG8000 EQU %00010000 ; BG & Window Tile Data Select
DEF LCDCF_BG9800 EQU %00000000 ; BG Tile Map Display Select
DEF LCDCF_BG9C00 EQU %00001000 ; BG Tile Map Display Select
DEF LCDCF_OBJ8 EQU %00000000 ; OBJ Construction
DEF LCDCF_OBJ16 EQU %00000100 ; OBJ Construction
DEF LCDCF_OBJOFF EQU %00000000 ; OBJ Display
DEF LCDCF_OBJON EQU %00000010 ; OBJ Display
DEF LCDCF_BGOFF EQU %00000000 ; BG Display
DEF LCDCF_BGON EQU %00000001 ; BG Display
; "Window Character Data Select" follows BG


; --
; -- STAT ($FF41)
; -- LCDC Status   (R/W)
; --
DEF rSTAT EQU $FF41

DEF STATF_LYC EQU %01000000 ; LYCEQULY Coincidence (Selectable)
DEF STATF_MODE10 EQU %00100000 ; Mode 10
DEF STATF_MODE01 EQU %00010000 ; Mode 01 (V-Blank)
DEF STATF_MODE00 EQU %00001000 ; Mode 00 (H-Blank)
DEF STATF_LYCF EQU %00000100 ; Coincidence Flag
DEF STATF_HB EQU %00000000 ; H-Blank
DEF STATF_VB EQU %00000001 ; V-Blank
DEF STATF_OAM EQU %00000010 ; OAM-RAM is used by system
DEF STATF_LCD EQU %00000011 ; Both OAM and VRAM used by system
DEF STATF_BUSY EQU %00000010 ; When set, VRAM access is unsafe


; --
; -- SCY ($FF42)
; -- Scroll Y (R/W)
; --
DEF rSCY EQU $FF42


; --
; -- SCY ($FF43)
; -- Scroll X (R/W)
; --
DEF rSCX EQU $FF43


; --
; -- LY ($FF44)
; -- LCDC Y-Coordinate (R)
; --
; -- Values range from 0->153. 144->153 is the VBlank period.
; --
DEF rLY EQU $FF44


; --
; -- LYC ($FF45)
; -- LY Compare (R/W)
; --
; -- When LYEQUEQULYC, STATF_LYCF will be set in STAT
; --
DEF rLYC EQU $FF45


; --
; -- DMA ($FF46)
; -- DMA Transfer and Start Address (W)
; --
DEF rDMA EQU $FF46


; --
; -- BGP ($FF47)
; -- BG Palette Data (W)
; --
; -- Bit 7-6 - Intensity for %11
; -- Bit 5-4 - Intensity for %10
; -- Bit 3-2 - Intensity for %01
; -- Bit 1-0 - Intensity for %00
; --
DEF rBGP EQU $FF47


; --
; -- OBP0 ($FF48)
; -- Object Palette 0 Data (W)
; --
; -- See BGP for info
; --
DEF rOBP0 EQU $FF48


; --
; -- OBP1 ($FF49)
; -- Object Palette 1 Data (W)
; --
; -- See BGP for info
; --
DEF rOBP1 EQU $FF49


; --
; -- SB ($FF01)
; -- Serial Transfer Data (R/W)
; --
DEF rSB EQU $FF01

; --
; -- SC ($FF02)
; -- Serial I/O Control (R/W)
; --
DEF rSC EQU $FF02

; --
; -- DIV ($FF04)
; -- Divider register (R/W)
; --
DEF rDIV EQU $FF04


; --
; -- TIMA ($FF05)
; -- Timer counter (R/W)
; --
DEF rTIMA EQU $FF05


; --
; -- TMA ($FF06)
; -- Timer modulo (R/W)
; --
DEF rTMA EQU $FF06


; --
; -- TAC ($FF07)
; -- Timer control (R/W)
; --
DEF rTAC EQU $FF07

DEF TACF_START EQU %00000100
DEF TACF_STOP EQU %00000000
DEF TACF_4KHZ EQU %00000000
DEF TACF_16KHZ EQU %00000011
DEF TACF_65KHZ EQU %00000010
DEF TACF_262KHZ EQU %00000001


; --
; -- IF ($FF0F)
; -- Interrupt Flag (R/W)
; --
; -- IE ($FFFF)
; -- Interrupt Enable (R/W)
; --
DEF rIF EQU $FF0F
DEF rIE EQU $FFFF

DEF IEF_HILO EQU %00010000 ; Transition from High to Low of Pin number P10-P13
DEF IEF_SERIAL EQU %00001000 ; Serial I/O transfer end
DEF IEF_TIMER EQU %00000100 ; Timer Overflow
DEF IEF_LCDC EQU %00000010 ; LCDC (see STAT)
DEF IEF_VBLANK EQU %00000001 ; V-Blank


; --
; -- WY ($FF4A)
; -- Window Y Position (R/W)
; --
; -- 0 <EQU WY <EQU 143
; --
DEF rWY EQU $FF4A


; --
; -- WX ($FF4B)
; -- Window X Position (R/W)
; --
; -- 7 <EQU WX <EQU 166
; --
DEF rWX EQU $FF4B


;***************************************************************************
;*
;* Sound control registers
;*
;***************************************************************************

; --
; -- AUDVOL/NR50 ($FF24)
; -- Channel control / ON-OFF / Volume (R/W)
; --
; -- Bit 7   - Vin->SO2 ON/OFF (Vin??)
; -- Bit 6-4 - SO2 output level (volume) (# 0-7)
; -- Bit 3   - Vin->SO1 ON/OFF (Vin??)
; -- Bit 2-0 - SO1 output level (volume) (# 0-7)
; --
DEF rNR50 EQU $FF24
DEF rAUDVOL EQU rNR50


; --
; -- AUDTERM/NR51 ($FF25)
; -- Selection of Sound output terminal (R/W)
; --
; -- Bit 7   - Output sound 4 to SO2 terminal
; -- Bit 6   - Output sound 3 to SO2 terminal
; -- Bit 5   - Output sound 2 to SO2 terminal
; -- Bit 4   - Output sound 1 to SO2 terminal
; -- Bit 3   - Output sound 4 to SO1 terminal
; -- Bit 2   - Output sound 3 to SO1 terminal
; -- Bit 1   - Output sound 2 to SO1 terminal
; -- Bit 0   - Output sound 0 to SO1 terminal
; --
DEF rNR51 EQU $FF25
DEF rAUDTERM EQU rNR51


; --
; -- AUDENA/NR52 ($FF26)
; -- Sound on/off (R/W)
; --
; -- Bit 7   - All sound on/off (sets all audio regs to 0!)
; -- Bit 3   - Sound 4 ON flag (doesn't work!)
; -- Bit 2   - Sound 3 ON flag (doesn't work!)
; -- Bit 1   - Sound 2 ON flag (doesn't work!)
; -- Bit 0   - Sound 1 ON flag (doesn't work!)
; --
DEF rNR52 EQU $FF26
DEF rAUDENA EQU rNR52


;***************************************************************************
;*
;* SoundChannel #1 registers
;*
;***************************************************************************

; --
; -- AUD1SWEEP/NR10 ($FF10)
; -- Sweep register (R/W)
; --
; -- Bit 6-4 - Sweep Time
; -- Bit 3   - Sweep Increase/Decrease
; --           0: Addition    (frequency increases???)
; --           1: Subtraction (frequency increases???)
; -- Bit 2-0 - Number of sweep shift (# 0-7)
; -- Sweep Time: (n*7.8ms)
; --
DEF rNR10 EQU $FF10
DEF rAUD1SWEEP EQU rNR10


; --
; -- AUD1LEN/NR11 ($FF11)
; -- Sound length/Wave pattern duty (R/W)
; --
; -- Bit 7-6 - Wave Pattern Duty (00:12.5% 01:25% 10:50% 11:75%)
; -- Bit 5-0 - Sound length data (# 0-63)
; --
DEF rNR11 EQU $FF11
DEF rAUD1LEN EQU rNR11


; --
; -- AUD1ENV/NR12 ($FF12)
; -- Envelope (R/W)
; --
; -- Bit 7-4 - Initial value of envelope
; -- Bit 3   - Envelope UP/DOWN
; --           0: Decrease
; --           1: Range of increase
; -- Bit 2-0 - Number of envelope sweep (# 0-7)
; --
DEF rNR12 EQU $FF12
DEF rAUD1ENV EQU rNR12


; --
; -- AUD1LOW/NR13 ($FF13)
; -- Frequency lo (W)
; --
DEF rNR13 EQU $FF13
DEF rAUD1LOW EQU rNR13


; --
; -- AUD1HIGH/NR14 ($FF14)
; -- Frequency hi (W)
; --
; -- Bit 7   - Initial (when set, sound restarts)
; -- Bit 6   - Counter/consecutive selection
; -- Bit 2-0 - Frequency's higher 3 bits
; --
DEF rNR14 EQU $FF14
DEF rAUD1HIGH EQU rNR14


;***************************************************************************
;*
;* SoundChannel #2 registers
;*
;***************************************************************************

; --
; -- AUD2LEN/NR21 ($FF16)
; -- Sound Length; Wave Pattern Duty (R/W)
; --
; -- see AUD1LEN for info
; --
DEF rNR21 EQU $FF16
DEF rAUD2LEN EQU rNR21


; --
; -- AUD2ENV/NR22 ($FF17)
; -- Envelope (R/W)
; --
; -- see AUD1ENV for info
; --
DEF rNR22 EQU $FF17
DEF rAUD2ENV EQU rNR22


; --
; -- AUD2LOW/NR23 ($FF18)
; -- Frequency lo (W)
; --
DEF rNR23 EQU $FF18
DEF rAUD2LOW EQU rNR23


; --
; -- AUD2HIGH/NR24 ($FF19)
; -- Frequency hi (W)
; --
; -- see AUD1HIGH for info
; --
DEF rNR24 EQU $FF19
DEF rAUD2HIGH EQU rNR24


;***************************************************************************
;*
;* SoundChannel #3 registers
;*
;***************************************************************************

; --
; -- AUD3ENA/NR30 ($FF1A)
; -- Sound on/off (R/W)
; --
; -- Bit 7   - Sound ON/OFF (1EQUON,0EQUOFF)
; --
DEF rNR30 EQU $FF1A
DEF rAUD3ENA EQU rNR30


; --
; -- AUD3LEN/NR31 ($FF1B)
; -- Sound length (R/W)
; --
; -- Bit 7-0 - Sound length
; --
DEF rNR31 EQU $FF1B
DEF rAUD3LEN EQU rNR31


; --
; -- AUD3LEVEL/NR32 ($FF1C)
; -- Select output level
; --
; -- Bit 6-5 - Select output level
; --           00: 0/1 (mute)
; --           01: 1/1
; --           10: 1/2
; --           11: 1/4
; --
DEF rNR32 EQU $FF1C
DEF rAUD3LEVEL EQU rNR32


; --
; -- AUD3LOW/NR33 ($FF1D)
; -- Frequency lo (W)
; --
; -- see AUD1LOW for info
; --
DEF rNR33 EQU $FF1D
DEF rAUD3LOW EQU rNR33


; --
; -- AUD3HIGH/NR34 ($FF1E)
; -- Frequency hi (W)
; --
; -- see AUD1HIGH for info
; --
DEF rNR34 EQU $FF1E
DEF rAUD3HIGH EQU rNR34


; --
; -- AUD4LEN/NR41 ($FF20)
; -- Sound length (R/W)
; --
; -- Bit 5-0 - Sound length data (# 0-63)
; --
DEF rNR41 EQU $FF20
DEF rAUD4LEN EQU rNR41


; --
; -- AUD4ENV/NR42 ($FF21)
; -- Envelope (R/W)
; --
; -- see AUD1ENV for info
; --
DEF rNR42 EQU $FF21
DEF rAUD4ENV EQU rNR42


; --
; -- AUD4POLY/NR42 ($FF22)
; -- Polynomial counter (R/W)
; --
; -- Bit 7-4 - Selection of the shift clock frequency of the (scf)
; --           polynomial counter (0000-1101)
; --           freqEQUdrf*1/2^scf (not sure)
; -- Bit 3 -   Selection of the polynomial counter's step
; --           0: 15 steps
; --           1: 7 steps
; -- Bit 2-0 - Selection of the dividing ratio of frequencies (drf)
; --           000: f/4   001: f/8   010: f/16  011: f/24
; --           100: f/32  101: f/40  110: f/48  111: f/56  (fEQU4.194304 Mhz)
; --
DEF rNR42_2 EQU $FF22
DEF rAUD4POLY EQU rNR42_2


; --
; -- AUD4GO/NR43 ($FF23)
; -- (has wrong name and value (ff30) in Dr.Pan's doc!)
; --
; -- Bit 7 -   Inital
; -- Bit 6 -   Counter/consecutive selection
; --
DEF rNR43 EQU $FF23
DEF rAUD4GO EQU rNR43	; silly name!

;***************************************************************************
;*
;* Cart related
;*
;***************************************************************************

DEF ROM_NOMBC EQU 0
DEF ROM_MBC1 EQU 1
DEF ROM_MBC1_RAM EQU 2
DEF ROM_MBC1_RAM_BAT EQU 3
DEF ROM_MBC2 EQU 5
DEF ROM_MBC2_BAT EQU 6
DEF ROM_NOMBC_RAM EQU 8
DEF ROM_NOMBC_RAM_BAT EQU 9

DEF ROM_SIZE_256KBIT EQU 0
DEF ROM_SIZE_512KBIT EQU 1
DEF ROM_SIZE_1M EQU 2
DEF ROM_SIZE_2M EQU 3
DEF ROM_SIZE_4M EQU 4
DEF ROM_SIZE_8M EQU 5
DEF ROM_SIZE_16M EQU 6

DEF ROM_SIZE_32KBYTE EQU 0
DEF ROM_SIZE_64KBYTE EQU 1
DEF ROM_SIZE_128KBYTE EQU 2
DEF ROM_SIZE_256KBYTE EQU 3
DEF ROM_SIZE_512KBYTE EQU 4
DEF ROM_SIZE_1MBYTE EQU 5
DEF ROM_SIZE_2MBYTE EQU 6

DEF RAM_SIZE_0KBIT EQU 0
DEF RAM_SIZE_16KBIT EQU 1
DEF RAM_SIZE_64KBIT EQU 2
DEF RAM_SIZE_256KBIT EQU 3
DEF RAM_SIZE_1MBIT EQU 4

DEF RAM_SIZE_0KBYTE EQU 0
DEF RAM_SIZE_2KBYTE EQU 1
DEF RAM_SIZE_8KBYTE EQU 2
DEF RAM_SIZE_32KBYTE EQU 3
DEF RAM_SIZE_128KBYTE EQU 4

;***************************************************************************
;*
;* Keypad related
;*
;***************************************************************************

DEF PADF_DOWN EQU $80
DEF PADF_UP EQU $40
DEF PADF_LEFT EQU $20
DEF PADF_RIGHT EQU $10
DEF PADF_START EQU $08
DEF PADF_SELECT EQU $04
DEF PADF_B EQU $02
DEF PADF_A EQU $01

DEF PADB_DOWN EQU $7
DEF PADB_UP EQU $6
DEF PADB_LEFT EQU $5
DEF PADB_RIGHT EQU $4
DEF PADB_START EQU $3
DEF PADB_SELECT EQU $2
DEF PADB_B EQU $1
DEF PADB_A EQU $0

;***************************************************************************
;*
;* Screen related
;*
;***************************************************************************

DEF SCRN_X EQU 160 ; Width of screen in pixels
DEF SCRN_Y EQU 144 ; Height of screen in pixels
DEF SCRN_X_B EQU 20  ; Width of screen in bytes
DEF SCRN_Y_B EQU 18  ; Height of screen in bytes

DEF SCRN_VX EQU 256 ; Virtual width of screen in pixels
DEF SCRN_VY EQU 256 ; Virtual height of screen in pixels
DEF SCRN_VX_B EQU 32  ; Virtual width of screen in bytes
DEF SCRN_VY_B EQU 32  ; Virtual height of screen in bytes

MACRO NINTENDO_LOGO
;*
;* Nintendo scrolling logo
;* (Code won't work on a real GameBoy)
;* (if next six lines are altered.)
 DB $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
 DB $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
 DB $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E
        ENDM

MACRO ROM_HEADER
;*
;* Nintendo scrolling logo
;* (Code won't work on a real GameBoy)
;* (if next six lines are altered.)

;    0123456789ABCDEF
 DB $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
 DB $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
 DB $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

 DB "EXAMPLE",0,0,0,0,0,0,0,0 ; Cart name - 15bytes
 DB 0                         ; $143
 DB 0,0                       ; $144 - Licensee code (not important)
 DB 0                         ; $146 - SGB Support indicator
 DB \1                        ; $147 - Cart type
 DB \2                        ; $148 - ROM Size
 DB \3                        ; $149 - RAM Size
 DB 1                         ; $14a - Destination code
 DB $33                       ; $14b - Old licensee code
 DB 0                         ; $14c - Mask ROM version
 DB 0                         ; $14d - Complement check (important)
 DW 0                         ; $14e - Checksum (not important)

        ENDM

        ENDC    ;HARDWARE_INC
