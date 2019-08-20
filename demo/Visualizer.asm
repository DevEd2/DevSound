; ================================================================
; DevSound Visualizer
; ================================================================

EnvelopeSpeed	equ 4389/16 - $100

VisualizerVBlank:
	push	af
	push	bc
	push	de
	push	hl

	call	OAM_DMA

	; copy wave display buffer to vram
	ld	[tempSP],sp
	ld	sp,WaveDisplayBuffer
	ld	hl,$8800
	ld	b,4
.loop
	rept 8
	pop	de
	ld	a,e
	ld	[hl+],a
	ld	a,d
	ld	[hl+],a
	endr
	dec	b
	jr	nz,.loop
	ldh	a,[tempSP]
	ld	l,a
	ldh	a,[tempSP+1]
	ld	h,a
	ld	sp,hl

	; update pulse type, noise type and noise frequency
	ld	a,[CH1Pulse]
	add	$6c
	ld	[$99c1],a
	ld	a,[CH2Pulse]
	add	$6c
	ld	[$99e1],a
	ld	a,[CH4OutputLevel]
	and	a
	jr	z,.noch4
	ld	a,[CH4Noise]
	ld	hl,$9a24
	cp	45
	ld	[hl],$6a
	jr	c,.noise15
	sub	45
	ld	[hl],$6b
.noise15
	add	a
	add	45
.noch4
	ld	[$fe0d],a ; ch4 frequency sprite's x position

	; update ch1-3 frequency sprite's x position
	ld	a,[CH1PianoPos]
	ld	[$fe01],a
	ld	a,[CH2PianoPos]
	ld	[$fe05],a
	ld	a,[CH3PianoPos]
	ld	[$fe09],a

	; update output level sprites
	ld	a,[CH1OutputLevel]	; output levels
	and	$f
	add	$70
	ld	[$fe12],a
	ld	[$fe22],a
	ld	a,[CH2OutputLevel]
	and	$f
	add	$70
	ld	[$fe16],a
	ld	[$fe26],a
	ld	a,[CH3Vol]
	and	$f
	add	$70
	ld	[$fe1a],a
	ld	[$fe2a],a
	ld	a,[CH4OutputLevel]
	and	$f
	add	$70
	ld	[$fe1e],a
	ld	[$fe2e],a
	ld	a,[rNR51]			; panning masks
	ld	hl,$fe13
	ld	b,8
.loop2
	rrca
	ld	[hl],0
	jr	c,.notmuted
	ld	[hl],$10
.notmuted
	rept 4
	inc	l
	endr
	dec	b
	jr	nz,.loop2

	ld	hl,$9991		; raster time display address in VRAM
	ld	a,[RasterTimeChar]
	ld	[hl+],a
	ld	a,[RasterTimeChar+1]
	ld	[hl+],a

	; draw song id
	ld	hl,$9890
	ld	a,[SongIDChar]
	ld	[hl+],a
	ld	a,[SongIDChar+1]
	ld	[hl+],a
	ld	a,[SongIDChar+2]
	ld	[hl+],a

if EngineSpeed != -1
	ld	a,1
	ld	[VBlankOccurred],a
endc
	pop	hl
	pop	de
	pop	bc
	pop	af
	reti

VisualizerInit:
	ld	hl,VisualizerVarsStart
	ld	b,VisualizerVarsEnd-VisualizerVarsStart
	xor	a
.clearloop
	ld	[hl+],a
	dec	b
	jr	nz,.clearloop
	ld	[CH3Vol],a
	; fallthrough to draw default/current wave and update sprites

UpdateVisualizer:
	; draw raster time
	ld	a,[RasterTime]
	ld	hl,RasterTimeChar
	call	DrawHex

	; draw song id
	ld	a,[CurrentSong]
	if	UseDecimal
		ld	hl,SongIDChar+2
		call	DrawDec
	else
		ld	hl,SongIDChar
		ld	[hl],"$"-$20
		inc	hl
		call	DrawHex
	endc

	; depack the current wave and convert it into delta form
	ld	hl,DepackedWaveDelta
	ld	de,VisualizerTempWave
	ld	bc,$1000
.loop
	ld	a,[de]
	swap	a
	and	$f
	rra
	ld	[hl],a
	sub	c
	ld	c,[hl]
	ld	[hl+],a
	ld	a,[de]
	inc	de
	and	$f
	rra
	ld	[hl],a
	sub	c
	ld	c,[hl]
	ld	[hl+],a
	dec	b
	jr	nz,.loop
	xor	a
	ld	[hl],a

	; clear and draw wave display buffer
	ld	hl,WaveDisplayBuffer+63
	ld	b,63
	xor	a
.loop2
	ld	[hl-],a
	dec	b
	jr	nz, .loop2
	ld	[hl+],a	; hl is now at the start of buffer + 1
	ld	de,DepackedWaveDelta+1
	ld	a,[DepackedWaveDelta]
	ld	c,a
	ld	b,0
	add	hl,bc
	add	hl,bc
	ld	bc,$480	; 4 tiles, leftmost pixel
.drawtileloop
	push	bc
.drawtileloop2
	ld	a,c
	or	[hl]
	ld	[hl-],a	; put dark gray pixel and change to light gray
	ld	a,[de]
	inc	de
	and	a
	jr	z,.drawtileskip
	ld	b,a
	bit	7,b
	jr	nz,.drawtileminus
.drawtileplus
	inc	hl		; advance to next row
	inc	hl
	dec	b
	jr	z,.drawtileskip
	ld	a,c
	or	[hl]
	ld	[hl],a	; stroke light gray line
	jr	.drawtileplus
.drawtileminus
	dec	hl		; advance to previous row
	dec	hl
	inc	b
	jr	z,.drawtileskip
	ld	a,c
	or	[hl]
	ld	[hl],a	; stroke light gray line
	jr	.drawtileminus
.drawtileskip
	inc	hl		; go back to dark gray pixel
	srl	c		; next pixel
	jr	nc,.drawtileloop2
	ld	bc,16
	add	hl,bc	; go to next tile
	pop	bc
	dec	b
	jr	nz,.drawtileloop

	call	UpdateVisualizerEnvelope
	ld	a,[EnvelopeTimer]
	add	EnvelopeSpeed
	ld	[EnvelopeTimer],a
	call	c,UpdateVisualizerEnvelope

	ld	bc,CH1ComputedFreq
	ld	de,CH1OutputLevel
	ld	hl,CH1PianoPos
	call	CalcPianoPos
	ld	bc,CH2ComputedFreq
	ld	de,CH2OutputLevel
	ld	hl,CH2PianoPos
	call	CalcPianoPos
	ld	bc,CH3ComputedFreq
	ld	de,CH3Vol
	ld	hl,CH3PianoPos
	jp	CalcPianoPos

UpdateVisualizerEnvelope_:	macro
	ld	a,[\1TempEnvelope]
	ld	b,a
	and	7
	jr	z,.skip\@
	ld	hl,\1EnvelopeCounter
	dec	[hl]
	jr	nz,.skip\@
	ld	[hl],a
	ld	a,[\1OutputLevel]
	bit	3,b
	jr	nz,.plus\@
	and	a
	jr	z,.skip\@
	dec	a
	jr	.skip2\@
.plus\@
	cp	15
	jr	z,.skip\@
	inc	a
.skip2\@
	ld	[\1OutputLevel],a
.skip\@
	endm

UpdateVisualizerEnvelope:
	UpdateVisualizerEnvelope_	CH1
	UpdateVisualizerEnvelope_	CH2
	UpdateVisualizerEnvelope_	CH4
	ret

CalcPianoPos:
	; calculate frequency sprite's x position based on the computed frequency
	; using some of hax math from Anniversary Crystal's music player routine
	; bc = source CHxComputedFreq
	; de = source CHxOutputLevel
	; hl = destination CHxPianoPos
	; the formula used in this function is
	; [hl] = ⌊24.5+24*log₂(131072/Freq("C2")/(2048-[bc]))⌋
	;      = ⌊24.5+24*(log₂(131072/65.4064)-log₂(2048-[bc]))⌋ (for A440 tuning)
	;      = ⌊(24.5+24*log₂(131072/65.4064))-(24*log₂(2048-[bc]))⌋
	;      = ⌊287.7474-24*log₂(2048-[bc])⌋
PianoPosConst	equ 8127	; ⌊287.7474⌋-256 in 8.8 bit fixed point form
	push	hl
	ld	a,[de]
	and	a
	jr	z,.nonote		; if the current level is 0, skip and hide the sprite
	ld	a,[bc]
	inc	bc
	ld	l,a
	ld	a,[bc]
	ld	h,a				; hl = [bc]
	ld	a,2048 % $100
	sub	l
	ld	l,a
	ld	a,2048 / $100
	sbc	h
	ld	h,a 			; hl = 2048-[bc]
	and	a
	ld	a,l
	jr	nz, .skip0check
	cp	1
	jr	z,.logshiftdone ; value is already 1
	jr	c,.nonote		; frequency is above 2047, this shouldn't happen
.skip0check
	ld	bc, 0
	ld	d,c
.logshiftloop
	; shift the value and increase the result by 1 until it's less than 2
	; based on the fact that log₂(x) = log₂(x/2)+1
	srl	h
	rr	l
	rr	c				; c receives the shift from hl, acting as decimal part
	inc	d
	ld	a,h
	and	a
	jr	nz, .logshiftloop
	ld	a,l
	dec	a
	jr	nz, .logshiftloop
.logshiftdone
	ld	hl,.logtable	; look up an entry for log₂(1.c) for a decimal part of the result
	add	hl,bc
	ld	e,[hl]			; d.e = log₂(2048-[bc])
	ld	a,d
	cp	4
	jr	c,.nonote		; value below 4 is guaranteed to be out of screen
	ld	h,d
	ld	l,e
	add	hl,hl			; x2  (overflow from this multiplication
	add	hl,de			; x3   can be ignored since the maximum
	add	hl,hl			; x6   possible value is less then 512
	add	hl,hl			; x12  (24*log₂(2048-0) = 264))
	add	hl,hl			; h.l = 24*log₂(2048-[bc])
	ld	a,PianoPosConst % $100
	sub	l				; only carry flag is needed, decimal part can be discarded at this point
	ld	a,PianoPosConst / $100
	sbc	h				; a = 287.7474-24*log₂(2048-[bc])
	pop	hl
	ld	[hl],a			; [hl] = 287.7474-24*log₂(2048-[bc])
	ret

.nonote
	pop	hl
	ld	[hl],0
	ret

.logtable
; ⌊log₂(1+(x/256))*256⌋
	db	  0,  1,  2,  4,  5,  7,  8,  9, 11, 12, 14, 15, 16, 18, 19, 21
	db	 22, 23, 25, 26, 27, 29, 30, 31, 33, 34, 35, 37, 38, 39, 40, 42
	db	 43, 44, 46, 47, 48, 49, 51, 52, 53, 54, 56, 57, 58, 59, 61, 62
	db	 63, 64, 65, 67, 68, 69, 70, 71, 73, 74, 75, 76, 77, 78, 80, 81
	db	 82, 83, 84, 85, 87, 88, 89, 90, 91, 92, 93, 94, 96, 97, 98, 99
	db	100,101,102,103,104,105,106,108,109,110,111,112,113,114,115,116
	db	117,118,119,120,121,122,123,124,125,126,127,128,129,131,132,133
	db	134,135,136,137,138,139,140,140,141,142,143,144,145,146,147,148
	db	149,150,151,152,153,154,155,156,157,158,159,160,161,162,162,163
	db	164,165,166,167,168,169,170,171,172,173,173,174,175,176,177,178
	db	179,180,181,181,182,183,184,185,186,187,188,188,189,190,191,192
	db	193,194,194,195,196,197,198,199,200,200,201,202,203,204,205,205
	db	206,207,208,209,209,210,211,212,213,214,214,215,216,217,218,218
	db	219,220,221,222,222,223,224,225,225,226,227,228,229,229,230,231
	db	232,232,233,234,235,235,236,237,238,239,239,240,241,242,242,243
	db	244,245,245,246,247,247,248,249,250,250,251,252,253,253,254,255

VisualizerSprites:
	db	128,  0,$67,0	; CH1 freq
	db	136,  0,$67,0	; CH2 freq
	db	144,  0,$67,0	; CH3 freq
	db	152,  0,$67,$80	; CH4 freq
	db	152,140,$70,0	; CH1 right output level
	db	152,148,$70,0	; CH2 right output level
	db	152,156,$70,0	; CH3 right output level
	db	152,164,$70,0	; CH4 right output level
	db	152,136,$70,0	; CH1 left output level
	db	152,144,$70,0	; CH2 left output level
	db	152,152,$70,0	; CH3 left output level
	db	152,160,$70,0	; CH4 left output level
VisualizerSprites_End:

VisualizerGfx:	incbin	"VisualizerGFX.bin"
VisualizerGfx_End:
