	CPU		Z80
	ORG		0h
	BINCLUDE "prg.orig"

INPUT_DIP0 = 0FC20h
INPUT_DIP1 = 0FC21h
INPUT_P1 = 0FC22h
INPUT_P2 = 0FC23h

ADD_CREDIT = 0C39h

CREDIT_COUNT = 0E366h

GAME_OVER_SCREEN = 020C1h

; Prints a string.
; hl = pointer to pascal-style string
; de = coordinates?
PRINT_STRING = 0E9Ah

; Checking the credits rountine...
	ORG	0BFDh

; Pushing start inserts a credit
;	ld	a, (0E361h)
;	ld	a, (INPUT_P1)
;	bit	6, a
;	jr	nz, .no_p1_in
;	ld	hl, 0E364h
;	ld	a, (INPUT_DIP0)
;	ld	de, 0E36Ah
;	call	add_credit
;.no_p1_in:
;	jr	0C27h
;	ld	a, (INPUT_P2)
;	bit	6, a
;	jr	nz, .no_p2_in
;	call	add_credit
;.no_p2_in:
;	jr	0C27h

; Inserting a credit does not make any sound
	ORG	0C7Ah
	ret
; Abusing the now saved space to stick a new routine
zero_credits_then_gameover:
;	ld	hl, CREDIT_COUNT
;	ld	a, 0
;	ld	(hl), a
;	jp	GAME_OVER_SCREEN

; At game over, credits are zeroed out
	ORG	01FDEh
;	call	zero_credits_then_gameover

; Draw "Free Play" instead of credit count
	ORG	02117h
;	ld	de, 0DABAh
;	ld	hl, .free_play_string
;	jp	PRINT_STRING
;.free_play_string:
;	db	9
;	db	"FREE PLAY"

; Inserting a credit flatly sets the credit count to 2
	ORG	0C4Eh
	ld	hl, CREDIT_COUNT
	ld	a, 2
	ld	(hl), a
	jr	0C5Ah
