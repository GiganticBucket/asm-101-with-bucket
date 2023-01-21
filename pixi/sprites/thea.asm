

; Constant Values
!Graphic_Tile_Happy = #$80
!Graphic_Tile_Sad = #$82
!Graphic_Tile_Properties = #$3F
!Moving_Speed = #$10

!SOUND_EFFECT_BANK = $1DFC
!SOUND_EFFECT_NUMBER = #$08
!HEALTH = #$03

!DIRECTION_RIGHT = #$00
!DIRECTION_LEFT = #$01

!STATE_HAPPY = #$00
!STATE_SAD = #$01

; Constant Addresses
!ADDRESS_SPRITES_LOCKED_FLAG = $9D
!ROUTINE_ADDRESS_MARIO_SPRITE_INTERACTIONS = $01A7DC
!ROUTINE_ADDRESS_SPRITE_PHYSICS = $01802A
!ROUTINE_ADDRESS_HURT_MARIO = $00F5B7
!ROUTINE_ADDRESS_JUMP_MARIO = $01AA33
!ROUTINE_ADDRESS_DISPLAY_CONTACT = $01AB99
!ADDRESS_GOAL_SPHERE_TIMER = $1493
!ADDRESS_BOSS_TRIGGER_GOAL = $13C6

; Sprite Tables
!SPRITE_TABLE_DIRECTION = $157C
!SPRITE_TABLE_X_SPEED = $B6
!SPRITE_TABLE_BLOCKED_STATUS = $1588
!SPRITE_TABLE_HEALTH = $1504
!SPRITE_TABLE_STATUS = $14C8
!SPRITE_TABLE_STATE = $1528

;----------  INIT ROUTINE -------------
print "INIT ",pc
init:

    %SubHorzPos()
    TYA
    STA !SPRITE_TABLE_DIRECTION,x

    LDA !HEALTH
    STA !SPRITE_TABLE_HEALTH,x

    LDA !STATE_HAPPY
    STA !SPRITE_TABLE_STATE,x

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

    ; Check Locked Status and Kick out if we need to
    LDA !ADDRESS_SPRITES_LOCKED_FLAG
    BNE .return

    ; Interact with Mario
    JSR mario_interactions

    ; Handle Sprite Movement & Physics
    JSR sprite_movement

.return
    RTS

; ------------- SPRITE MOVEMENT ROUTINE ------------
sprite_movement:

    ; Call Physics Routine.
    JSL !ROUTINE_ADDRESS_SPRITE_PHYSICS

    ; Check if we bonked a left wall
    LDA !SPRITE_TABLE_BLOCKED_STATUS,x
    AND #$02
    CMP #$02
    BEQ .switchtoright

    ; Check if we bonked a right wall
    LDA !SPRITE_TABLE_BLOCKED_STATUS,x
    AND #$01
    CMP #$01
    BEQ .switchtoleft

    BRA .afterblocked

.switchtoright

    LDA !DIRECTION_RIGHT
    STA !SPRITE_TABLE_DIRECTION,x

    BRA .afterblocked
.switchtoleft

    LDA !DIRECTION_LEFT
    STA !SPRITE_TABLE_DIRECTION,x

.afterblocked

    ; Update our sprite speed.
    LDA !SPRITE_TABLE_DIRECTION,x
    CMP !DIRECTION_LEFT
    BEQ .movementleft

    ; moving right
    LDA !Moving_Speed
    STA !SPRITE_TABLE_X_SPEED,x
    BRA .aftermovement

.movementleft
    ; left
    LDA !Moving_Speed
    EOR #$FF
    INC
    STA !SPRITE_TABLE_X_SPEED,x

.aftermovement



.return
    RTS



; ------------- MARIO INTERACTION ROUTINE ------------
mario_interactions:

    JSL !ROUTINE_ADDRESS_MARIO_SPRITE_INTERACTIONS
    BCC .return

    JSR checkifabove
    BCC .hurtmario

    ; SAD THEA :(
    LDA !STATE_SAD
    STA !SPRITE_TABLE_STATE,x

    ; Bounce Mario
    JSL !ROUTINE_ADDRESS_JUMP_MARIO
    ; Show Contact Graphic
    JSL !ROUTINE_ADDRESS_DISPLAY_CONTACT
    ; Play Sound Effect
    LDA !SOUND_EFFECT_NUMBER
    STA !SOUND_EFFECT_BANK

    DEC !SPRITE_TABLE_HEALTH,x
    LDA !SPRITE_TABLE_HEALTH,x
    BNE .return

    ; So here we hit the boss, AND the boss's health
    ; has fallen to zero.  So we can end the game or something.
.endgame

    ; prevent mario from walking at the end
    DEC !ADDRESS_BOSS_TRIGGER_GOAL

    ; Set the goal for the level.
    LDA #$FF
    STA !ADDRESS_GOAL_SPHERE_TIMER

    ; KILL THE THEA :gasp
    LDA #$02
    STA !SPRITE_TABLE_STATUS,x

    BRA .return
.hurtmario
    JSL !ROUTINE_ADDRESS_HURT_MARIO

.return
    RTS


;--------- Function to check if mario is on top of the sprite or not ------------
;--------- Code by Runic on SMWC ------------------------------------------------
; Output: Sets the carry flag if mario is on top.
checkifabove:
    LDA #$14            ; min distance above sprite necessary to bounce
    STA $01
    LDA $05 : SEC : SBC $01
    ROL $00                ; clipping y displacements (compared?)
    CMP $D3
    PHP
    LSR $00
    LDA $0B : SBC #$00
    PLP
    SBC $D4
    BMI .not_top
    ; set the carry flag
    SEC
    BRA .return
.not_top
    ; clear the carry flag
    CLC
.return
    RTS


; ------------ GRAPHICS ROUTINE ---------------------
gfx:

    %GetDrawInfo()

    LDA $00
    STA $0300,y

    LDA $01
    STA $0301,y

    LDA !SPRITE_TABLE_STATE,x
    CMP !STATE_HAPPY
    BEQ .happy
    LDA !Graphic_Tile_Sad
    BRA .aftertile
.happy
    LDA !Graphic_Tile_Happy
.aftertile
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