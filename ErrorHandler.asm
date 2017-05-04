; ================================================================
; Error handler
; TO USE: Include this file anywhere in the Home bank then
; add a call to ErrorHandler to RST_38
; ================================================================

ErrorHandler:

	; store stack pointer
	inc	sp
	inc	sp
	ld	[tempSP],sp
	
	push	hl
	push	af
	
	; store AF
	pop	hl
	ld	a,h
	ldh	[tempAF],a
	ld	a,l
	ldh	[tempAF+1],a
	
	; store BC
	ld	a,b
	ldh	[tempBC],a
	ld	a,c
	ldh	[tempBC+1],a
	
	; store DE
	ld	a,d
	ldh	[tempDE],a
	ld	a,e
	ldh	[tempDE+1],a
	
	; store HL
	pop	hl
	ld	a,h
	ldh	[tempHL],a
	ld	a,l
	ldh	[tempHL+1],a
	
	; store PC
	pop	hl				; hl = old program counter
	ld	a,h
	ldh	[tempPC],a
	ld	a,l
	ldh	[tempPC+1],a
	
	; store IF
	ldh	a,[rIF]
	ldh	[tempIF],a
	
	; store IE
	ldh	a,[rIE]
	ldh	[tempIE],a
	
.wait					; wait for VBlank before disabling the LCD
	ldh	a,[rLY]
	cp	$90
	jr	nz,.wait
	; Note that it probably isn't a good idea to use halt to wait for VBlank
	; because interrupts may not be enabled when an error occurs.
	
	xor	a
	ldh	[rLCDC],a		; disable LCD
	
	ld	a,%11100100		; default palette
	ldh	[rBGP],a
	
	call	ClearVRAM
	
	CopyTileset1BPP	Font,0,97
	ld	hl,ErrorHandlerTilemap
	call	LoadMapText
	
DrawRegisterValues:
	ld	de,tempAF
	
	ld	hl,$9965
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	hl,$996f
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	hl,$9985
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	hl,$998f
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	a,[de]
	inc	de
	call	DrawHex
	inc	de
	inc	de
	ld	hl,$99af
	ld	a,[de]
	inc	de
	call	DrawHex
	ld	a,[de]
	inc	de
	call	DrawHex
	
	ld	hl,$99a5
	ld	a,[tempSP+1]
	call	DrawHex
	ld	a,[tempSP]
	call	DrawHex
	
	; TODO: Draw IF and IE
	
	ld	a,[rIF]
	ld	b,a
	ld	hl,$99c8
	call	DrawBin
	
	ld	a,[rIE]
	ld	b,a
	ld	hl,$99e8
	call	DrawBin

	ld	a,%10010001
	ldh	[rLCDC],a
	
	call	DS_Stop

ErrorHandler_loop:
	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnStart,a
	jr	z,.continue
	jp	ProgramStart
.continue
	halt
	jr	ErrorHandler_loop
	
DrawBin:
	bit	7,b
	call	nz,.draw1
	call	z,.draw0
	bit	6,b
	call	nz,.draw1
	call	z,.draw0
	bit	5,b
	call	nz,.draw1
	call	z,.draw0
	bit	4,b
	call	nz,.draw1
	call	z,.draw0
	bit	3,b
	call	nz,.draw1
	call	z,.draw0
	bit	2,b
	call	nz,.draw1
	call	z,.draw0
	bit	1,b
	call	nz,.draw1
	call	z,.draw0
	bit	0,b
	call	nz,.draw1
	ret	nz
.draw0
	ld	a,"0" - 32
	ld	[hl+],a
	ret
.draw1
	ld	a,"1" - 32
	ld	[hl+],a
	ret
	
ErrorHandlerTilemap:
;		 ####################
	db	"     - ERROR -      "
	db	"                    "
	db	"An error has occured"
	db	"and the game cannot "
	db	"continue. Contact   "
	db	"the following email "
	db	"address to report   "
	db	"this error:         "
	db	"  deved8@gmail.com  "
	db	"                    "
	db	"Registers:          "
	db	" AF=$????  BC=$???? "
	db	" DE=$????  HL=$???? "
	db	" SP=$????  PC=$???? "
	db	"    IF=%XXXXXXXX    "
	db	"    IE=%XXXXXXXX    "
	db	"                    "
	db	"Press Start to exit."
;		 ####################
