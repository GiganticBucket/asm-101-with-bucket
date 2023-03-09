

Graphic_Tile_Array:
    db $80, $82,
       $A0, $A2
Graphic_Tile_X_Offset_Left_Array:
    db $00, $10,
       $00, $10
Graphic_Tile_X_Offset_Right_Array:
    db $10, $00,
       $10, $00
Graphic_Tile_Y_Offset_Array:
    db $00, $00,
       $10, $10

!Graphic_Tile_Properties_Left = #$3F
!Graphic_Tile_Properties_Right = #$7F
!Graphic_Tile_Num_Tiles = #$04

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
!ADDRESS_SPRITE_OBJECT_CLIPPING_MODE = $C2


; Sprite Tables
!SPRITE_TABLE_DIRECTION = $157C
!SPRITE_TABLE_X_SPEED = $B6
!SPRITE_TABLE_Y_SPEED = $AA
!SPRITE_TABLE_BLOCKED_STATUS = $1588
!SPRITE_TABLE_HEALTH = $1504
!SPRITE_TABLE_STATUS = $14C8
!SPRITE_TABLE_STATE = $1528

; Clipping Values
!RAM_SprClipXDisp = $7FABAA
!RAM_SprClipYDisp = $7FABB6
!RAM_SprClipWidth = $7FABC2
!RAM_SprClipHeight = $7FABCE

; Clipping variables for this sprite.
; This is for sprite-sprite interaction
!XClip = #$02
!YClip = #$02
!XClipLength = #$1C
!YClipLength = #$1C


;----------  INIT ROUTINE -------------
print "INIT ",pc
init:

    ; load up the clipping variables and store them into the
    ; correct addresses.
    LDA !XClip
    STA !RAM_SprClipXDisp,x
    LDA !YClip
    STA !RAM_SprClipYDisp,x
    LDA !XClipLength
    STA !RAM_SprClipWidth,x
    LDA !YClipLength
    STA !RAM_SprClipHeight,x

    ; store the index of 00 into the ObjClippingIndex.
    LDA #$00
    STA !ADDRESS_SPRITE_OBJECT_CLIPPING_MODE,x

    ; Set the sprite-clipping mode to custom.
    LDA #$3D
    STA $1662,x

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

    ; Call physics
    JSL !ROUTINE_ADDRESS_SPRITE_PHYSICS

    ; Call our custom Sprite-Object interaction Routine
    JSR apply_object_clipping

    ; Check if we're on the ground (blocked on bottom)
    ; if so, zero out our Y speed.
    LDA !SPRITE_TABLE_BLOCKED_STATUS,x
    AND #$04
    CMP #$04
    BNE .afterground
    ; we're blocked on ground, so zero out speed.
    STZ !SPRITE_TABLE_Y_SPEED,x
.afterground

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

;-------------------- Custom Sprite-Object Interaction ----------
; Output: Stores blocked status in 7E1588 based on the custom
;         sprite clipping values configured above.
apply_object_clipping:

    ; this is our 'assembled' clipping object
    LDA #$00
    PHA

    ; bottom-side clipping check
    LDA $D8,x
    PHA
    LDA $14D4,x
    PHA
    LDA $E4,x
    PHA
    LDA $14E0,x
    PHA
    LDA !YClipLength
    ; we subtract 1 tile here, as the regular physics already accounts for it.
    CLC
    SBC #$10
    JSR add_to_sprite_position_y
    JSL !ROUTINE_ADDRESS_SPRITE_PHYSICS
    PLA
    STA $14E0,x
    PLA
    STA $E4,x
    PLA
    STA $14D4,x
    PLA
    STA $D8,x

    LDA !SPRITE_TABLE_BLOCKED_STATUS,x
    AND #$04
    STA $00
    PLA
    ORA $00
    PHA

    ; top-side clipping check
    LDA $D8,x
    PHA
    LDA $14D4,x
    PHA
    LDA $E4,x
    PHA
    LDA $14E0,x
    PHA
    LDA !YClip
    JSR add_to_sprite_position_y
    JSL !ROUTINE_ADDRESS_SPRITE_PHYSICS
    PLA
    STA $14E0,x
    PLA
    STA $E4,x
    PLA
    STA $14D4,x
    PLA
    STA $D8,x

    LDA !SPRITE_TABLE_BLOCKED_STATUS,x
    AND #$08
    STA $00
    PLA
    ORA $00
    PHA

    ; left-side clipping check
    LDA $D8,x
    PHA
    LDA $14D4,x
    PHA
    LDA $E4,x
    PHA
    LDA $14E0,x
    PHA
    LDA !XClip
    JSR add_to_sprite_position_x
    JSL !ROUTINE_ADDRESS_SPRITE_PHYSICS
    PLA
    STA $14E0,x
    PLA
    STA $E4,x
    PLA
    STA $14D4,x
    PLA
    STA $D8,x

    LDA !SPRITE_TABLE_BLOCKED_STATUS,x
    AND #$02
    STA $00
    PLA
    ORA $00
    PHA

    ; right-side clipping check
    LDA $D8,x
    PHA
    LDA $14D4,x
    PHA
    LDA $E4,x
    PHA
    LDA $14E0,x
    PHA
    LDA !XClipLength
    ; we subtract 1 tile here, as the regular physics already accounts for it.
    CLC
    SBC #$10
    JSR add_to_sprite_position_x
    JSL !ROUTINE_ADDRESS_SPRITE_PHYSICS
    PLA
    STA $14E0,x
    PLA
    STA $E4,x
    PLA
    STA $14D4,x
    PLA
    STA $D8,x

    LDA !SPRITE_TABLE_BLOCKED_STATUS,x
    AND #$01
    STA $00
    PLA
    ORA $00

    ; at this point our A will have a nice 'aggregation' of
    ; blocked statuses.
    STA !SPRITE_TABLE_BLOCKED_STATUS,x
.return
    RTS



;------------------- Add to Position. --------------------------
; input: A = Y Offset
add_to_sprite_position_y:
    CLC
    ADC $D8,x
    STA $D8,x
    LDA $14D4,x
    ADC #$00
    STA $14D4,x

.return
    RTS

;------------------- Add to Position. --------------------------
; input: A = X Offset
add_to_sprite_position_x:
    CLC
    ADC $E4,x
    STA $E4,x
    LDA $14E0,x
    ADC #$00
    STA $14E0,x

.return
    RTS

; ------------ GRAPHICS ROUTINE ---------------------
gfx:

    %GetDrawInfo()

    LDA !SPRITE_TABLE_X_SPEED,x
    STA $02

    ; Push X, for later use.
    PHX
    LDX !Graphic_Tile_Num_Tiles
.loop
    DEX

    ; X offset
    ; load in our speed (saved from before)
    LDA $02
    CMP #$7F
    BPL .movingleft
    LDA Graphic_Tile_X_Offset_Right_Array,x
    BRA .setxoffset
.movingleft
    LDA Graphic_Tile_X_Offset_Left_Array,x
.setxoffset
    CLC
    ADC $00
    STA $0300,y

    ; Y offset
    LDA $01
    CLC
    ADC Graphic_Tile_Y_Offset_Array,x
    STA $0301,y

    ; pick the tile
    LDA Graphic_Tile_Array,x
    STA $0302,y


    ; Right vs Left sprite tile properties
    ; load in our speed (saved from before)
    LDA $02
    CMP #$7F
    BPL .propleft
    LDA !Graphic_Tile_Properties_Right
    BRA .setprop
.propleft
    LDA !Graphic_Tile_Properties_Left
.setprop
    STA $0303,y

	; increment the OAM index
    INY #4

    ; compare X, stop drawing if we need to.
    CPX #$00
    BNE .loop

    ; ending code for gfx
    ; set that the tiles are 16x16
    LDY #$02
    ; set that we drew a certain number of tiles.
    LDA !Graphic_Tile_Num_Tiles

    ; Finish OAM Write for Graphics
    PLX
    JSL $01B7B3

.return

    RTS