;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Custom Sprite Clipping Patch, by imamelia
;;
;; This patch allows you to give a sprite any size interaction field you want.  You simply have
;; to set the sprite clipping in the .cfg file to 3C, 3D, 3E, or 3F, depending on what you want
;; to do:
;;
;; - 3C will make the sprite use clipping values from tables in ROM.
;; - 3D will make the sprite use clipping values from tables in RAM.
;; - 3E is currently unused.  Do not use.
;; - 3F is currently unused.  Do not use.
;;
;; Instructions for use:
;;
;; If you want to set the clipping values in tables beforehand (in ROM)...
;;
;; 1) Set up the clipping values in the four tables below, if you choose to use them.
;; SprClipXDisp is for the X displacement of the clipping field, SprClipYDisp is for
;; the Y displacement, SprClipWidth is how wide the clipping field is, and SprClipHeight
;; is how tall it is.  Each byte in a table represents one custom clipping value; the first
;; byte is for custom clipping 00, the second is for custom clipping 01, etc.
;; 2) Use a text editor or the .cfg editor (mikeyk's won't work; use Romi's) to set the sprite
;; clipping index to 3C.  (The .cfg editor will tell you where this is.)
;; 3) Within the custom sprite code, store the custom clipping value to !RAM_CustSprClip,x.
;; For instance, if you want the sprite to use custom clipping value 05, put
;;	LDA #$05
;;	STA !RAM_CustSprClip
;; in the sprite's init routine.  (Make sure you actually have that define in the sprite or in an
;; incsrc file, or you'll get assembling errors.)
;;
;; If you want to set the clipping values manually in the sprite code (in RAM)...
;;
;; 1) Use a text editor or Romi's .cfg editor to set the sprite's clipping index to 3D.
;; 2) In the sprite code (can be in the init routine if the values never change), set up the four
;; clipping variables.  Store the X displacement of the clipping field to !RAM_SprClipXDisp,
;; the Y displacement to !RAM_SprClipYDisp, the width to !RAM_SprClipWidth, and the height
;; to !RAM_SprClipHeight.  Note that you have to actually have these defines in the sprite code
;; (if you put them in as defines), or you will get assembling errors.
;;
;; A note about the default RAM addresses:
;;
;; You may or may not be wondering why I picked $7FAB70, $7FABAA, $7FABB6, $7FABC2,
;; and $7FABCE for the default addresses.  Well, since all the RAM addresses mikeyk originally
;; used for custom sprites were in the $7FABxx range, I figured we should stick to the same area
;; when adding new custom sprite tables.  I used to have plans for $7FAB40, $7FAB4C, $7FAB58,
;; and $7FAB64 already, so $7FAB70 was the next table.  (I'd use $7FAB7C for custom object
;; clipping.) That's why the sprite clipping index is $7FAB70,x by default.  The other four tables
;; follow a similar logic; $7FAB9E,x was the last chunk of $7FABxx RAM used for a sprite table,
;; so the next four would be $7FABAA,x, $7FABB6,x, $7FABC2,x, and $7FABCE,x.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

header
lorom

!RAM_CustSprClip = $7FAB70		; 12 bytes of free RAM used for the custom sprite clipping value
!RAM_SprClipXDisp = $7FABAA		; 12 bytes of free RAM used for the X displacement of a custom sprite clipping field
!RAM_SprClipYDisp = $7FABB6		; 12 bytes of free RAM used for the Y displacement of a custom sprite clipping field
!RAM_SprClipWidth = $7FABC2		; 12 bytes of free RAM used for the width of a custom sprite clipping field
!RAM_SprClipHeight = $7FABCE		; 12 bytes of free RAM used for the height of a custom sprite clipping field
					; See below for SA-1 addresses.

!bank	= $800000			; do not change these
!addr	= $0000
!E4	= $E4
!14E0	= $14E0
!D8	= $D8
!14D4	= $14D4

if read1($00ffd5) == $23
sa1rom

!RAM_CustSprClip = $6000		; 22 bytes of free RAM used for the custom sprite clipping value
!RAM_SprClipXDisp = $6099		; 22 bytes of free RAM used for the X displacement of a custom sprite clipping field
!RAM_SprClipYDisp = $60AF		; 22 bytes of free RAM used for the Y displacement of a custom sprite clipping field
!RAM_SprClipWidth = $60C5		; 22 bytes of free RAM used for the width of a custom sprite clipping field
!RAM_SprClipHeight = $60DB		; 22 bytes of free RAM used for the height of a custom sprite clipping field

!bank	= $000000			; do not change these
!addr	= $6000
!E4	= $322C
!14E0	= $326E
!D8	= $3216
!14D4	= $3258

endif

org $03B6AA
autoclean JML SprClipHack1

org $03B6F0
autoclean JML SprClipHack2

freecode

SprClipXDisp:
db $00,$00,$00,$00,$00,$00,$00,$00	; custom sprite clipping values 00-07
db $00,$00,$00,$00,$00,$00,$00,$00	; custom sprite clipping values 08-0F
; you can insert more here, up to FF

SprClipYDisp:
db $00,$00,$00,$00,$00,$00,$00,$00	; custom sprite clipping values 00-07
db $00,$00,$00,$00,$00,$00,$00,$00	; custom sprite clipping values 08-0F
; you can insert more here, up to FF

SprClipWidth:
db $00,$00,$00,$00,$00,$00,$00,$00	; custom sprite clipping values 00-07
db $00,$00,$00,$00,$00,$00,$00,$00	; custom sprite clipping values 08-0F
; you can insert more here, up to FF

SprClipHeight:
db $00,$00,$00,$00,$00,$00,$00,$00	; custom sprite clipping values 00-07
db $00,$00,$00,$00,$00,$00,$00,$00	; custom sprite clipping values 08-0F
; you can insert more here, up to FF

SprClipHack1:

CPX #$3C			; if the clipping index is 3C or greater...
BCS CustomSprClip1	; then use the custom clipping routines
LDA $03B56C|!bank,x	; else, load the normal clipping table values
JML $03B6AE|!bank	;

CustomSprClip1:		;

BEQ .UseROMTables	; if X = 3C, then use the ROM tables
CPX #$3D			;
BEQ .UseRAMTables	; if X = 3D, then use the RAM tables

LDA $03B56C|!bank,x		; else, load the normal clipping table values
JML $03B6AE|!bank		;

.UseROMTables		;
PHB				;
PHK				;
PLB				;
LDX $15E9|!addr			; get the sprite index into X
LDA !RAM_CustSprClip,x	;
TAY				; and the clipping index into Y
JSR GetCustSprClipA1	;
PLB				;
PLX				;
PLY				;
RTL				;

.UseRAMTables		;
PHB				;
PHK				;
PLB				;
LDX $15E9|!addr			; get the sprite index into X
JSR GetCustSprClipA2	;
PLB				;
PLX				;
PLY				;
RTL				;

SprClipHack2:

CPX #$3C			; if the clipping index is 3C or greater...
BCS CustomSprClip2	; then use the custom clipping routines
LDA $03B56C|!bank,x	; else, load the normal clipping table values
JML $03B6F4|!bank	;

CustomSprClip2:		;

BEQ .UseROMTables	; if X = 3C, then use the ROM tables
CPX #$3D			;
BEQ .UseRAMTables	; if X = 3D, then use the RAM tables

LDA $03B56C|!bank,x	; else, load the normal clipping table values
JML $03B6AE|!bank	;

.UseROMTables		;
PHB				;
PHK				;
PLB				;
LDX $15E9|!addr			; get the sprite index into X
LDA !RAM_CustSprClip,x	;
TAY				; and the clipping index into Y
JSR GetCustSprClipB1	;
PLB				;
PLX				;
PLY				;
RTL				;

.UseRAMTables		;
PHB				;
PHK				;
PLB				;
LDX $15E9|!addr			; get the sprite index into X
JSR GetCustSprClipB2	;
PLB				;
PLX				;
PLY				;
RTL				;

GetCustSprClipA1:		;

STZ $0F			;
LDA.w SprClipXDisp,y	;
BPL $02			;
DEC $0F			;
CLC				;
ADC !E4,x			;
STA $04			; $04 = sprite X position low byte + X displacement value
LDA !14E0,x		;
ADC $0F			;
STA $0A			; $0A = sprite X position high byte + X displacement high byte (00 or FF)
LDA.w SprClipWidth,y	;
STA $06			; $06 = sprite clipping width (a little less than 16 pixels)
STZ $0F			;
LDA.w SprClipYDisp,y	;
BPL $02			;
DEC $0F			;
CLC				;
ADC !D8,x			;
STA $05			; $05 = sprite Y position low byte + Y displacement value
LDA !14D4,x		;
ADC $0F			;
STA $0B			; $0B = sprite Y position high byte + Y displacement high byte (00 or FF)
LDA.w SprClipHeight,y	;
STA $07			; $07 = sprite clipping height
RTS				;

GetCustSprClipB1:		;

STZ $0F			;
LDA.w SprClipXDisp,y	;
BPL $02			;
DEC $0F			;
CLC				;
ADC !E4,x			;
STA $00			; $00 = sprite X position low byte + X displacement value
LDA !14E0,x		;
ADC $0F			;
STA $08			; $08 = sprite X position high byte + X displacement high byte (00 or FF)
LDA.w SprClipWidth,y	;
STA $02			; $02 = sprite clipping width (a little less than 16 pixels)
STZ $0F			;
LDA.w SprClipYDisp,y	;
BPL $02			;
DEC $0F			;
CLC				;
ADC !D8,x			;
STA $01			; $01 = sprite Y position low byte + Y displacement value
LDA !14D4,x		;
ADC $0F			;
STA $09			; $09 = sprite Y position high byte + Y displacement high byte (00 or FF)
LDA.w SprClipHeight,y	;
STA $03			; $03 = sprite clipping height
RTS				;

GetCustSprClipA2:			;

STZ $0F				;
LDA !RAM_SprClipXDisp,x	;
BPL $02				;
DEC $0F				;
CLC					;
ADC !E4,x				;
STA $04				; $04 = sprite X position low byte + X displacement value
LDA !14E0,x			;
ADC $0F				;
STA $0A				; $0A = sprite X position high byte + X displacement high byte (00 or FF)
LDA !RAM_SprClipWidth,x	;
STA $06				; $06 = sprite clipping width (a little less than 16 pixels)
STZ $0F				;
LDA !RAM_SprClipYDisp,x	;
BPL $02				;
DEC $0F				;
CLC					;
ADC !D8,x				;
STA $05				; $05 = sprite Y position low byte + Y displacement value
LDA !14D4,x			;
ADC $0F				;
STA $0B				; $0B = sprite Y position high byte + Y displacement high byte (00 or FF)
LDA !RAM_SprClipHeight,x	;
STA $07				; $07 = sprite clipping height
RTS					;

GetCustSprClipB2:			;

STZ $0F				;
LDA !RAM_SprClipXDisp,x	;
BPL $02				;
DEC $0F				;
CLC					;
ADC !E4,x				;
STA $00				; $00 = sprite X position low byte + X displacement value
LDA !14E0,x			;
ADC $0F				;
STA $08				; $08 = sprite X position high byte + X displacement high byte (00 or FF)
LDA !RAM_SprClipWidth,x	;
STA $02				; $02 = sprite clipping width (a little less than 16 pixels)
STZ $0F				;
LDA !RAM_SprClipYDisp,x	;
BPL $02				;
DEC $0F				;
CLC					;
ADC !D8,x				;
STA $01				; $01 = sprite Y position low byte + Y displacement value
LDA !14D4,x			;
ADC $0F				;
STA $09				; $09 = sprite Y position high byte + Y displacement high byte (00 or FF)
LDA !RAM_SprClipHeight,x	;
STA $03				; $03 = sprite clipping height
RTS					;
