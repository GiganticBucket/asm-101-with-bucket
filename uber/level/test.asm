
; Address Constants
!Address_Mario_X_Speed = $7B

; Value Constants
!Constant_Kill_Mario_Threshold_Speed = #$2E

; Init Method
init:

	RTL

; Main Method
main:

	; Check Right-ward speed.
	LDA !Address_Mario_X_Speed
	CMP !Constant_Kill_Mario_Threshold_Speed
	BPL .playerdies

	BRA .return

.playerdies
	; Here, the player has a powerup status that is
	; NON-zero, so we're going to kill the player.  
	JSL $00F606

.return

	RTL


