

!Graphic_Tile_Number = #$80
!Graphic_Tile_Properties = #$3F

!ROUTINE_ADDRESS_MARIO_SPRITE_INTERACTIONS = $01A7DC

;----------  INIT ROUTINE -------------
print "INIT ",pc
init:


.return
    RTL




; ------------- MAIN SPRITE WRAPPER -----------------
print "MAIN ",pc
main:
    PHB
    PHK
    PLB
    JSR sprite_main
    PLB
    RTL

; ------------ MAIN ROUTINE --------------------
sprite_main:

    ; Call our Graphics Routine
    JSR gfx

    ; Interact with Mario
    JSR mario_interactions

.return
    RTS


; ------------- MARIO INTERACTION ROUTINE ------------
mario_interactions:

    JSL !ROUTINE_ADDRESS_MARIO_SPRITE_INTERACTIONS


.return
    RTS


; ------------ GRAPHICS ROUTINE ---------------------
gfx:

    %GetDrawInfo()

    LDA $00
    STA $0300,y

    LDA $01
    STA $0301,y

    LDA !Graphic_Tile_Number
    STA $0302,y

    LDA !Graphic_Tile_Properties
    STA $0303,y

	; increment the OAM index
    INY #4

    ; ending code for gfx
    ; set that the tiles are 16x16
    LDY #$02
    ; set that we drew 1 tile
    LDA #$01

    ; Finish OAM Write for Graphics
    JSL $01B7B3|!BankB

.return
    RTS