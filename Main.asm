; ================================================================
; DevSound demo ROM
; ================================================================

; Debug flag
; If set to 1, enable debugging features.

DebugFlag	set	1

; If set to 1, display numbers in decimal instead of hexadecimal.

UseDecimal	set	0

; ================================================================
; Project includes
; ================================================================

include	"Variables.asm"
include	"Constants.asm"
include	"Macros.asm"
include	"hardware.inc"

; ================================================================
; Reset vectors (actual ROM starts here)
; ================================================================

SECTION	"Reset $00",HOME[$00]
Reset00:	ret

SECTION	"Reset $08",HOME[$08]
Reset08:	ret

SECTION	"Reset $10",HOME[$10]
Reset10:	ret

SECTION	"Reset $18",HOME[$18]
Reset18:	ret

SECTION	"Reset $20",HOME[$20]
Reset20:	ret

SECTION	"Reset $28",HOME[$28]
Reset28:	ret

SECTION	"Reset $30",HOME[$30]
Reset30:	ret

SECTION	"Reset $38",HOME[$38]
Reset38:	jp	ErrorHandler

; ================================================================
; Interrupt vectors
; ================================================================

SECTION	"VBlank interrupt",HOME[$40]
IRQ_VBlank:
	reti

SECTION	"LCD STAT interrupt",HOME[$48]
IRQ_STAT:
	reti

SECTION	"Timer interrupt",HOME[$50]
IRQ_Timer:
	reti

SECTION	"Serial interrupt",HOME[$58]
IRQ_Serial:
	reti

SECTION	"Joypad interrupt",Home[$60]
IRQ_Joypad:
	reti
	
; ================================================================
; System routines
; ================================================================

include	"SystemRoutines.asm"

; ================================================================
; ROM header
; ================================================================

SECTION	"ROM header",HOME[$100]

EntryPoint:
	nop
	jp	ProgramStart

NintendoLogo:	; DO NOT MODIFY OR ROM WILL NOT BOOT!!!
	db	$ce,$ed,$66,$66,$cc,$0d,$00,$0b,$03,$73,$00,$83,$00,$0c,$00,$0d
	db	$00,$08,$11,$1f,$88,$89,$00,$0e,$dc,$cc,$6e,$e6,$dd,$dd,$d9,$99
	db	$bb,$bb,$67,$63,$6e,$0e,$ec,$cc,$dd,$dc,$99,$9f,$bb,$b9,$33,$3e

ROMTitle:		db	"DEVSOUND",0,0,0	; ROM title (11 bytes)
ProductCode		db	"ADSE"				; product code (4 bytes)
GBCSupport:		db	0					; GBC support (0 = DMG only, $80 = DMG/GBC, $C0 = GBC only)
NewLicenseCode:	db	"DS"				; new license code (2 bytes)
SGBSupport:		db	0					; SGB support
CartType:		db	0					; Cart type, see hardware.inc for a list of values
ROMSize:		ds	1					; ROM size (handled by post-linking tool)
RAMSize:		db	0					; RAM size
DestCode:		db	1					; Destination code (0 = Japan, 1 = All others)
OldLicenseCode:	db	$33					; Old license code (if $33, check new license code)
ROMVersion:		db	0					; ROM version
HeaderChecksum:	ds	1					; Header checksum (handled by post-linking tool)
ROMChecksum:	ds	2					; ROM checksum (2 bytes) (handled by post-linking tool)

; ================================================================
; Start of program code
; ================================================================

ProgramStart:
	ld	sp,$fffe
	di						; disable interrupts
	
.wait						; wait for VBlank before disabling the LCD
	ldh	a,[rLY]
	cp	$90
	jr	nz,.wait
	xor	a
	ld	[rLCDC],a			; disable LCD
	
	call	ClearWRAM

	; clear HRAM
	xor	a
	ld	bc,$8080
._loop
	ld	[c],a
	inc	c
	dec	b
	jr	nz,._loop

	call	ClearVRAM
	
	CopyTileset1BPP	Font,0,(Font_End-Font)/8
	
	ld	hl,MainText			; load main text
	call	LoadMapText
	ld	a,%11100100			; 3 2 1 0
	ldh	[rBGP],a			; set background palette

	ld	a,IEF_VBLANK
	ldh	[rIE],a				; set VBlank interrupt flag
		
	ld	a,%10010001			; LCD on + BG on + BG $8000
	ldh	[rLCDC],a			; enable LCD
	
	; Sample implementation for loading a song.
	; Replace the 0 in ld a,0 with the ID of the song you want to load.
	; Note that invalid values will most likely result in a crash!
	
	ld	a,0
	call	DS_Init
	
	ei
	
MainLoop:
	; draw song id
	ld	a,[CurrentSong]
	if	UseDecimal
		ld	hl,$98b2
		call	DrawDec
	else
		ld	hl,$98b1
		call	DrawHex
	endc
.loop	
	ld	a,[rLY]			; wait for scanline 0
	and	a
	jp	nz,.loop
	ldh	a,[rBGP]		; get current palette
	ld	b,a				; copy to B for later use
	xor	$ff				; invert palette
	ldh	[rBGP],a		; (draw CPU meter from top of screen)
	call	DS_Play		; update sound
	
	ldh	a,[rLY]			; get current scanline
	ld	c,a
	ld	a,b				; restore palette
	ldh	[rBGP],a		; (stop drawing CPU meter)
	halt				; wait for VBlank
	
	ld	a,c
	ld	hl,$9a11		; raster time display address in VRAM
	call	DrawHex		; draw raster time
		; playback controls
	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnUp,a
	jr	nz,.add16
	bit	btnDown,a
	jr	nz,.sub16
	bit	btnLeft,a
	jr	nz,.sub1
	bit	btnRight,a
	jr	nz,.add1
	bit	btnA,a
	jr	nz,.loadSong
	bit	btnB,a
	jr	nz,.stopSong
	bit	btnStart,a
	jr	nz,.fadeout
	bit	btnSelect,a
	jr	nz,.fadein
	jr	.continue

.add1
	ld	a,[CurrentSong]
	inc	a
	ld	[CurrentSong],a
	jr	.continue
.sub1
	ld	a,[CurrentSong]
	dec	a
	ld	[CurrentSong],a
	jr	.continue
.add16
	ld	a,[CurrentSong]
	add	16
	ld	[CurrentSong],a
	jr	.continue
.sub16
	ld	a,[CurrentSong]
	sub	16
	ld	[CurrentSong],a
	jr	.continue
.loadSong
	ld	a,[CurrentSong]
	call	DS_Init
	jr	.continue
.stopSong
	call	DS_Stop
	jr	.continue
.fadeout
	ld	a,2
	call	DS_Fade
	jr	.continue
.fadein	
	ld	a,[CurrentSong]
	call	DS_Init
	ld	a,1
	call	DS_Fade
.continue
	jp	MainLoop
	
; ================================================================
; Graphics data
; ================================================================
	
MainText:
;		 ####################
	db	"                    "
	db	"    DevSound v1.0   "
	db	"      by DevEd      "
	db	"  deved8@gmail.com  "
	db	"                    "
	db	" Current song:  $?? "
	db	"                    "
	db	" Controls:          "
	db	" A        Load song "
	db	" B        Stop song "
	db	" D-pad  Select song "
	db	" Start     Fade out "
	db	" Select     Fade in "
	db	"                    "
	db	"                    "
	db	"                    "
	db	" Raster time:   $?? "
	db	"                    "
;		 ####################

Font:	incbin	"Font.bin"	; 1bpp font data
Font_End:

; ================================================================
; Draw decimal number A at HL
; ================================================================

; Routine copied from GBS2GB.

DrawDec:
	call	.div10	; get 1's digit
	ld	[hl-],a		; write char
	ld	a,c
	call	.div10	; get 10's digit
.notzero2
	ld	[hl-],a		; write char
	ld	a,c
	add	$10			; add offset to tile #
.notzero3
	ld	[hl],a		; write 100's digit
	ret
	
.div10
	ld	c,0			; divide by 10
.d1 
	ld	b,a
	sub	10
	jr	c,.d2
	inc	c
	jr	.d1
.d2
	ld	a,b
	add	$10			; add offset to tile #
	ret

; ================================================================
; Error handler
; ================================================================

	include	"ErrorHandler.asm"

; ================================================================
; GBS Header
; ================================================================

	include	"gbs.asm"

; ================================================================
; DevSound sound driver
; ================================================================

	include	"DevSound.asm"
