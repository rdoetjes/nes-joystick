.include "ppu.inc"
.include "apu.inc"

.include "neshdr.asm"
.include "neschar.asm"

.segment "STARTUP"
.segment "CODE"

   jmp init


DEFMASK        = %00001000 ; background enabled

START_X        = 5
START_Y        = 14
START_NT_ADDR  = NAMETABLE_A + 32 * START_Y + START_X

START_NT_ADDR_1  = NAMETABLE_A + (32 * START_Y) + START_X + (joystick_str_end - joystick_str)

.macro WAIT_VBLANK
:  bit PPUSTATUS
   bpl :-
.endmacro

init:
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

@game_loop:
   WAIT_VBLANK

   jmp @game_loop

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
.word   init        ; $fffc reset
.word   irq         ; $fffe irq / brk
