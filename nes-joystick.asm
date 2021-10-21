.include "ppu.inc"
.include "apu.inc"

.include "neshdr.asm"
.include "neschar.asm"

.segment "STARTUP"
.segment "CODE"

   jmp start

joystick_str: 
   .asciiz "JOYSTICK 1 VALUE"
joystick_str_end:

DEFMASK        = %00001000 ; background enabled

START_X        = 5
START_Y        = 14
START_NT_ADDR  = NAMETABLE_A + 32 * START_Y + START_X

START_NT_ADDR_1  = NAMETABLE_A + (32 * START_Y) + START_X + (joystick_str_end - joystick_str)

.macro WAIT_VBLANK
:  bit PPUSTATUS
   bpl :-
.endmacro

start:
   sei
   cld
   ldx #$40
   stx APU_FRAMECTR ; disable IRQ
   ldx #$FF
   txs ; init stack pointer
   inx ; reset X to zero to initialize PPU and APU registers
   stx PPUCTRL
   stx PPUMASK
   stx APU_MODCTRL

   WAIT_VBLANK

   ; while waiting for two frames for PPU to stabilize, reset RAM
   txa   ; still zero!
@clr_ram:
   sta $000,x
   sta $100,x
   sta $200,x
   sta $300,x
   sta $400,x
   sta $500,x
   sta $600,x
   sta $700,x
   inx
   bne @clr_ram

   WAIT_VBLANK

   ; start writing to palette, starting with background color
   lda #>BG_COLOR
   sta PPUADDR
   lda #<BG_COLOR
   sta PPUADDR
   lda #BLACK
   sta PPUDATA ; black backround color
   sta PPUDATA ; palette 0, color 0 = black
   lda #(RED | DARK)
   sta PPUDATA ; color 1 = dark red
   lda #(RED | NEUTRAL)
   sta PPUDATA ; color 2 = neutral red
   lda #(RED | LIGHT)
   sta PPUDATA ; color 3 = light red

   ; set scroll position to 0,0
   lda #0
   sta PPUSCROLL ; x = 0
   sta PPUSCROLL ; y = 0
   ; enable display
   lda #DEFMASK
   sta PPUMASK

   ;set x y for string
   lda #>START_NT_ADDR
   sta PPUADDR
   lda #<START_NT_ADDR
   sta PPUADDR

   ; set $a0 to point to string
   lda #<joystick_str
   sta $a0
   lda #>joystick_str
   sta $a1
   ;print the string
   jsr printString

@game_loop:
   WAIT_VBLANK

   ;set our joystick value store in #03 to 00
   lda #$0
   sta $03

   jsr latchControllers
   
   jsr readController1

   lda $03
   jsr convertJoystickValueToHex
   
   jsr printJoyStick

   jmp @game_loop

readController1:
   ldx #$0

@readController1BitOne:
   lda $4016
   and #%00000001
   beq @bitSet

   lda $03
   asl
   sta $03
   jmp @continue

@bitSet:
   lda $03
   asl
   ora #%00000001
   sta $03

@continue:
   inx 
   cpx #$8
   bne @readController1BitOne
   
   ;invert the value
   lda $03
   eor #$ff
   sta $03
   rts

latchControllers:
   lda #$01
   sta $4016
   lda #$00 
   sta $4016
   rts

printJoyStick:
;set x y to draw the joystick value
   lda #>START_NT_ADDR_1
   sta PPUADDR
   lda #<START_NT_ADDR_1
   sta PPUADDR

   ;set the value to draw in $a0
   lda #<$0000
   sta $a0
   lda #>$0000
   sta $a1
   jsr printString
   rts

convertJoystickValueToHex:
   tax
   ;mask off top nibble
   and #$f0
   lsr
   lsr
   lsr
   lsr
   adc #$30
   sta $00

   ;mask off bottom nibble
   txa
   and #$0f
   adc #$30
   sta $01

   ;terminate our two byte (joystick value) string 
   lda #$00
   sta $02
   rts

printString:
 ; place string character tiles
   ldy #0
@string_loop:
   lda ($a0),y
   beq @setCharPallete
   sta PPUDATA
   iny
   jmp @string_loop
@setCharPallete:
   jsr setpal
   WAIT_VBLANK
   rts

setpal:
   ; set all table A tiles to palette 0
   lda #>ATTRTABLE_A
   sta PPUADDR
   lda #<ATTRTABLE_A
   sta PPUADDR
   lda #0
   ldx #64
@attr_loop:
   sta PPUDATA
   dex
   bne @attr_loop
   rts 

; ------------------------------------------------------------------------
; System V-Blank Interrupt
; ------------------------------------------------------------------------

nmi:
   pha

   ; refresh scroll position to 0,0
   lda #0
   sta PPUSCROLL
   sta PPUSCROLL

   ; keep default PPU config
   sta PPUCTRL
   lda #DEFMASK
   sta PPUMASK

   pla

   ; Interrupt exit
irq:
   rti


.segment "VECTORS"
.word   nmi         ; $fffa vblank nmi
.word   start       ; $fffc reset
.word   irq         ; $fffe irq / brk
