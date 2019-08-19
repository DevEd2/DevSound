; ================================================================
; System routines
; ================================================================

; ================================================================
; Clear work RAM
; ================================================================

ClearWRAM:
	ld	hl,$c001	; don't clear first byte of WRAM (preserve GBType)
	ld	bc,$1fff
	jr	ClearLoop	; routine continues in ClearLoop

; ================================================================
; Clear tilemap area
; ================================================================

ClearScreen:
	ld	hl,$9800
	ld	bc,$800
	jr	ClearLoop	; routine continues in ClearLoop

; ================================================================
; Clear video RAM
; ================================================================

ClearVRAM:
	ld	hl,$8000
	ld	bc,$2000
	; routine continues in ClearLoop

; ================================================================
; Clear a section of RAM
; ================================================================

ClearLoop:
	xor	a
	ld	[hl+],a
	dec	bc
	ld	a,b
	or	c
	jr	nz,ClearLoop
	ret

; ================================================================
; Wait for LCD status to change
; ================================================================

WaitStat:
	push	af
.wait
	ld	a,[rSTAT]
	and	2
	jr	z,.wait
.wait2
	ld	a,[rSTAT]
	and	2
	jr	nz,.wait2
	pop	af
	ret

; ================================================================
; Check joypad input
; ================================================================

CheckInput:
	ld	a,P1F_5
	ld	[rP1],a
	ld	a,[rP1]
	ld	a,[rP1]
	cpl
	and	a,$f
	swap	a
	ld	b,a

	ld	a,P1F_4
	ld	[rP1],a
	ld	a,[rP1]
	ld	a,[rP1]
	ld	a,[rP1]
	ld	a,[rP1]
	ld	a,[rP1]
	ld	a,[rP1]
	cpl
	and	a,$f
	or	a,b
	ld	b,a

	ld	a,[sys_btnHold]
	xor	a,b
	and	a,b
	ld	[sys_btnPress],a
	ld	a,b
	ld	[sys_btnHold],a
	ld	a,P1F_5|P1F_4
	ld	[rP1],a
	ret

; ================================================================
; Draw hexadecimal number A at HL
; ================================================================

DrawHex:
	push	af
	swap	a
	call	.loop1
	pop	af
.loop1
	and	$f
	cp	$a
	jr	c,.loop2
	add	a,$7
.loop2
	add	a,$10
	ld	[hl+],a
	ret

; ================================================================
; Load a text tilemap
; ================================================================

LoadMapText:
	ld	de,_SCRN0
	ld	b,$12
	ld	c,$14
.loop
	ld	a,[hl+]
	sub 32
	ld	[de],a
	inc	de
	dec	c
	jr	nz,.loop
	ld	c,$14
	ld	a,e
	add	$C
	jr	nc,.continue
	inc	d
.continue
	ld	e,a
	dec	b
	jr	nz,.loop
	ret
