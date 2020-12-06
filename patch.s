	CPU		Z80
	ORG		0000h
	BINCLUDE "prg.orig"

; Bubble Bobble Free Play / Enhancement patch
; 2020 "Hatsune" Mike Moffitt
;
; Features:
;   * Free Play flow enabled or disabled with DSW2.7
;   * No existing functionality or options compromised
;   * TODO: Rank display, difficulty & round selection at start

; Ports / shared MCU RAM
; ======================
INPUT_DIP0 = 0FC20h
INPUT_DIP1 = 0FC21h
INPUT_P1 = 0FC22h
INPUT_P2 = 0FC23h

; Routines
; ========
; Prints a string.
; hl = pointer to pascal-style string
; de = coordinates?
print_string = 0E9Ah
add_credit = 0C39h
game_over_screen = 020C1h


; RAM variables (anything in the E000h region is shared with the sub CPU)
; =======================================================================
Share_CreditCount = 0E366h
Share_CoinLatchP1 = 0E361h
Share_CoinLatchP2 = 0E35Fh

Share_Rank = 0E5DCh  ; Dynamic difficulty. Max 1Eh.

; -----------------------------------------------------------------------------

; I'm using DSW1 bit 6 to test for free play enable/disable. When the switch is
; set, the dip switch pulls the input LOW to a logic '0'. So, checks are done
; like this:
;
;	ld	a, (INPUT_DIP1)
;	bit	6, a
;	jr	z, .free_logic
;
; The game actually checks this DIP in a few spots when players are out of
; lives. At 0F26h and 0F74h this occurs. Calls are made from 4156h and 418Ch
; respectively. By eliminating these calls we can claim that entire area for
; new routines.
;
; Those functions apparently write the player score and stage number to F7FEh
; and F7FFh, then hangs because it is expecting a change or some sort of ack.
; Maybe it is intended for some form of score save, or score table registry.
mystery_dip_check_disable_1:
	ORG	4156h
	nop
	nop
	nop
mystery_dip_check_disable_2:
	ORG	418Ch
	nop
	nop
	nop

dip_check_unk_1_ret:
	ORG	0F26h
	ret

; Show credit count or free play based on settings.
maybe_draw_free_play:
	ld	a, (INPUT_DIP1)
	bit	6, a
	jr	z, .free_logic
	; Normal logic.
	ld	a, (Share_CreditCount)
	jp	211Ah

.free_logic:
	ld	de, 0DABAh
	ld	hl, .free_play_string
	ld	c, 0
	jp	print_string

.free_play_string:
	db	10
	db	" FREE PLAY"

dip_check_unk_2_ret:
	ORG	0F74h
	ret

maybe_clear_credits_before_game_over:
	; Check if in free play
	ld	a, (INPUT_DIP1)
	bit	6, a
	jr	nz, .go_to_game_over ; If not in free play skip clear.
	; Clear credits.
	ld	hl, Share_CreditCount
	ld	(hl), 0

.go_to_game_over:
	jp	game_over_screen

maybe_show_insert_coin_screen:
	; Check if in free play
	ld	a, (INPUT_DIP1)
	bit	6, a
	jr	z, .free_logic
	; This sets up the timer to wait 5Ah frames.
	ld	a, 5Ah
	rst	18h
.free_logic:
	jp	2B15h

; More mystery dsw checks.
mystery_dip_check_disable_3:
	ORG	0EE3h
	ret

; This game has a kinda weird checksum! Rather than checking all of the ROM at
; boot, it slowly iterates through the ROM space over the course of many
; frames. I am not sure it even triggers on a per-frame basis; it might be
; driven sporadically by game events.
;
; The checksum at E35Ch is incremented slowly. When it has finished checking a
; section of ROM it is compared to an expected value at E35Dh. If it succeeds,
; it starts this "progressive checksum" over with a different start offset.
;
; This means that the amount of time it takes for an innocent change to trigger
; a crash or other unwanted behavior is variable and hard to predict. It took a
; while to find this one. Sky Shark (developed by Toaplan, but published by
; Taito) has a similar checksum scheme, but it is a little less tangled.
;
; The routine for the progressive checksum is at 0AE3h. Defeating it gives us
; some much needed free ROM space anyway.
sporadic_checksum_disable:
	ORG	0AE3h
	ret

; STicking some routines in the checksum area too.

maybe_allow_coin_in:
	; Check if in free play
	ld	a, (INPUT_DIP1)
	bit	6, a
	jr	z, .free_logic
	; Reproduce overwritten normal logic.
	ld	a, (Share_CoinLatchP1)
	jp	0C00h

.free_logic:
	ld	a, (INPUT_P1)  ; Read p1 input
	bit	6, a  ; start pressed?
	jr	nz, .no_p1_in
	; If so, put in a coin.
	ld	hl, 0E364h
	ld	a, 0
	ld	de, 0E36Ah
	jr	.set_credits

.no_p1_in:
	ld	a, (INPUT_P2)
	bit	6, a
	jr	nz, .no_p2_in
	; Put in a coin.
	ld	hl, 0E365h
	ld	a, 0
	ld	de, 0E372h
	jr	.set_credits

.no_p2_in:
	jp	00C27h

; Hooks to the new routines.
.set_credits:
	ld	hl, Share_CreditCount
	ld	(hl), 9
	jr	.no_p2_in

start_credit_hook:
	ORG	00BFDh
	jp	maybe_allow_coin_in

game_over_hook:
	ORG	01FDEh
	call	maybe_clear_credits_before_game_over

credit_count_draw_hook:
	ORG	02117h
	jp	maybe_draw_free_play

insert_coin_screen_hook:
	ORG	02B12h
	jp	maybe_show_insert_coin_screen
