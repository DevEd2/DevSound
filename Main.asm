; ================================================================
; DevSound demo ROM
; ================================================================

; Debug flag
; If set to 1, enable debugging features.

DebugFlag	set	1

; If set to 1, display numbers in decimal instead of hexadecimal.

UseDecimal	set	0

; Engine speed (= 4096/(256-x) Hz), -1 to use VBlank

EngineSpeed	set -1

; If defined, include a visualizer in the main screen

Visualizer  set 1

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

SECTION	"Reset $00",ROM0[$00]
Reset00:	ret

SECTION	"Reset $08",ROM0[$08]
Reset08:	ret

SECTION	"Reset $10",ROM0[$10]
Reset10:	ret

SECTION	"Reset $18",ROM0[$18]
Reset18:	ret

SECTION	"Reset $20",ROM0[$20]
Reset20:	ret

SECTION	"Reset $28",ROM0[$28]
Reset28:	ret

SECTION	"Reset $30",ROM0[$30]
Reset30:	ret

SECTION	"Reset $38",ROM0[$38]
Reset38:	jp	ErrorHandler

; ================================================================
; Interrupt vectors
; ================================================================

SECTION	"VBlank interrupt",ROM0[$40]
IRQ_VBlank:
if def(Visualizer)
	jp VisualizerVBlank
else
if EngineSpeed != -1
	push	af
	ld	a,1
	ld	[VBlankOccurred],a
	pop	af
endc
	reti
endc

SECTION	"LCD STAT interrupt",ROM0[$48]
IRQ_STAT:
	reti

SECTION	"Timer interrupt",ROM0[$50]
IRQ_Timer:
if EngineSpeed == -1
	reti
else
	jp	DoTimer
endc

SECTION	"Serial interrupt",ROM0[$58]
IRQ_Serial:
	reti

SECTION	"Joypad interrupt",ROM0[$60]
IRQ_Joypad:
	reti
	
; ================================================================
; System routines
; ================================================================

include	"SystemRoutines.asm"

; ================================================================
; ROM header
; ================================================================

SECTION	"ROM header",ROM0[$100]

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
	
if def(Visualizer)
	CopyTileset	VisualizerGfx,$640,(VisualizerGfx_End-VisualizerGfx)/16
	CopyBytes	VisualizerSprites,Sprites,VisualizerSprites_End-VisualizerSprites
	; copy oam dma routine into hram
	ld	hl,OAM_DMA_
	ld	bc,(10 * $100) + (OAM_DMA % $100)
.copy
	ld	a,[hl+]
	ld	[c],a
	inc	c
	dec	b
	jr	nz,.copy
endc
	
	; Emulator check
	ld	a,$ed						; this value isn't important
	ld	b,a							; copy value to B
	ld	[EmulatorCheck],a			; store in WRAM
	ld	a,[EmulatorCheck + $2000]	; read back value from echo RAM
	cp	b
	jp	z,.noemu
	ld	hl,.emutext
	call	LoadMapText
	ld	a,%10010001
	ldh	[rLCDC],a
	ld	a,IEF_VBLANK
	ldh	[rIE],a
	ei
.waitloop
	halt
	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnA,a
	jr	z,.waitloop
	xor	a
	ldh	[rLCDC],a	; no need to wait for VBlank in an emulator!
	di
	jp	.noemu
	
.emutext
;		 ####################
	db	"     !WARNING!      "
	db	"                    "
	db	"You are running this"
	db	"ROM in an inaccurate"
	db	"emulator. DevSound  "
	db	"relies on a quirk of"
	db	"the Game Boy's audio"
	db	"hardware that most  "
	db	"likely will not work"
	db	"in this emulator.   "
	db	"For best results,   "
	db	"use a more accurate "
	db	"emulator, such as   "
	db	"bgb or Gambatte, or "
	db	"run this ROM on real"
	db	"hardware.           "
	db	"                    "
	db	"Press A to continue."
;		 ####################
	
.noemu
	ld	hl,MainText			; load main text
	call	LoadMapText
	ld	hl,MainText			; load main text
	call	LoadMapText
	
if EngineSpeed == -1
	ld	a,IEF_VBLANK
else
	ld	a,EngineSpeed
	ld	[rTMA],a
	ld	[rTIMA],a
	ld	a,TACF_START + TACF_4KHZ
	ld	[rTAC],a
	ld	a,IEF_VBLANK + IEF_TIMER
endc
	ldh	[rIE],a				; set VBlank interrupt flag
	
if def(Visualizer)
	ld	a,%10010011			; LCD on + BG on + BG $8000 + Sprites on
else
	ld	a,%10010001			; LCD on + BG on + BG $8000
endc
	ldh	[rLCDC],a			; enable LCD
	
	; Sample implementation for loading a song.
	; Replace the 0 in ld a,0 with the ID of the song you want to load.
	; Note that invalid values will most likely result in a crash!
	
	xor	a
	ld	[FadeType],a	; FadeType must be reset for first init
	;ld	a,0				; uncomment this line and replace the 0 with the desired song ID
	call	DS_Init
	
	ei
	
MainLoop:
	halt				; wait for VBlank
if EngineSpeed != -1
	ld	a,[VBlankOccurred]
	and	a
	jr	z,MainLoop
	xor	a
	ld	[VBlankOccurred],a
endc
if !def(Visualizer)
	ld	a,[RasterTime]
	ld	hl,$9a11		; raster time display address in VRAM
	call	DrawHex		; draw raster time
	; draw song id
	ld	a,[CurrentSong]
	if	UseDecimal
		ld	hl,$98b2
		call	DrawDec
	else
		ld	hl,$98b1
		call	DrawHex
	endc
endc
if EngineSpeed == -1
.loop
	ld	a,[rLY]			; wait for scanline 0
	and	a
	jp	nz,.loop
	ld	a,%00011011		; inverted palette
	ldh	[rBGP],a		; (draw CPU meter from top of screen)
if def(Visualizer)
	ldh [rOBP0],a
	ld	a,%10101011
	ldh [rOBP1],a
endc
	call	DS_Play		; update sound
	
	ldh	a,[rLY]			; get current scanline
	ld	[RasterTime],a
	ld	a,%11100100		; normal palette
	ldh	[rBGP],a		; (stop drawing CPU meter)
if def(Visualizer)
	ldh [rOBP0],a
	ld	a,%01010100
	ldh [rOBP1],a
endc
endc
if def(Visualizer)
	call	UpdateVisualizer
endc
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
	ld	a,1
	call	DS_Fade
	ld	a,[CurrentSong]
	call	DS_Init
.continue
	jp	MainLoop
	
if EngineSpeed != -1
DoTimer:
	push	af
	push	bc
	ld	a,[rLY]			; get current scanline
	ld	c,a				; copy to C for later use
	ld	a,%00011011		; inverted palette
	ldh	[rBGP],a		; (draw CPU meter)
	ldh [rOBP0],a
	ld	a,%10101011
	ldh [rOBP1],a
	call	DS_Play		; update sound
	
	ldh	a,[rLY]			; get current scanline
	sub	c
	jr	nc,.nocarry
	add	153
.nocarry
	ld	[RasterTime],a
	ld	a,%11100100		; normal palette
	ldh	[rBGP],a		; (stop drawing CPU meter)
	ldh [rOBP0],a
	ld	a,%01010100
	ldh [rOBP1],a
	pop	bc
	pop	af
	reti
endc
	
_CopyTileset1BPP:
	ld	a,[hl+]			; get tile
	ld	[de],a			; write tile
	inc	de				; increment destination address
	ld	[de],a			; write tile again
	inc	de				; increment destination address again
	dec	bc
	dec	bc				; since we're copying two tiles, we need to dec bc twice
	ld	a,b
	or	c
	jr	nz,_CopyTileset1BPP
	ret
	
if def(Visualizer)	
_CopyBytes:
	inc	b
	inc	c
	dec	c
	jr	nz,.loop
	dec	b
.loop
	ld	a,[hl+]
	ld	[de],a
	inc	de
	dec	c
	jr	nz,.loop
	dec	b
	jr	nz,.loop
	ret
	
OAM_DMA_:
	ld	a,Sprites/$100
	ld	[rDMA],a
	ld	a,$28
.wait
	dec	a
	jr	nz,.wait
	ret
endc
	
; ================================================================
; Graphics data
; ================================================================
	
MainText:
if def(Visualizer)
;		 ####################
	db	"                    "
	db	"    DevSound v2.2   "
	db	"   by DevEd & Pigu  "
	db	"                    "
	db	" Current song:  $?? "
	db	"                    "
	db	" A        Load song "
	db	" B        Stop song "
	db	" D-pad  Select song "
	db	" Start     Fade out "
	db	" Select     Fade in "
	db	"                    "
	db	" Raster time:   $?? "
	db	"                    "
	; visualizer starts here
	db	"1",$8c,$84,$85,$86,$84,$85,$86,$84,$85,$86,$84,$85,$86,$84,$85,$86,$84,$85,$86
	db	"2",$8c,$84,$85,$86,$84,$85,$86,$84,$85,$86,$84,$85,$86,$84,$85,$86,$84,$85,$86
	db	"3W",   $84,$85,$86,$84,$85,$86,$84,$85,$86,$84,$85,$86,$84,$85,$86,$84,$85,$86
	db	$a0,$a1,$a2,$a3,$8a,$87,$88,$88,$88,$88,$88,$88,$88,$88,$88,$89,"    "
;		 ####################
else
;		 ####################
	db	"                    "
	db	"    DevSound v2.2   "
	db	"   by DevEd & Pigu  "
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
endc

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
; Visualizer
; ================================================================

if def(Visualizer)
	include	"Visualizer.asm"
endc

; ================================================================
; GBS Header
; ================================================================

	include	"gbs.asm"

; ================================================================
; DevSound sound driver
; ================================================================

	include	"DevSound.asm"
