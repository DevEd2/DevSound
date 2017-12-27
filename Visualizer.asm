; ================================================================
; DevSound Visualizer
; ================================================================

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
	
	; TODO
	ld	a,[RasterTime]
	ld	hl,$9991		; raster time display address in VRAM
	call	DrawHex		; draw raster time
	
	; draw song id
	ld	a,[CurrentSong]
	if	UseDecimal
		ld	hl,$9892
		call	DrawDec
	else
		ld	hl,$9891
		call	DrawHex
	endc
	
if EngineSpeed != -1
	ld	a,1
	ld	[VBlankOccurred],a
endc
	pop	hl
	pop	de
	pop	bc
	pop	af
	reti

UpdateVisualizer:
	ld	a,%11100101
	ld	[rBGP],a
	; depack the current wave and convert it into delta form
	ld	hl,DepackedWaveDelta
	ld	de,VisualizerTempWave
	ld	bc,$1000
.loop
	ld	a,[de]
	swap	a
	and	$f
	ld	[hl],a
	sub	c
	ld	c,[hl]
	ld	[hl+],a
	ld	a,[de]
	inc	de
	and	$f
	ld	[hl],a
	sub	c
	ld	c,[hl]
	ld	[hl+],a
	dec	b
	jr	nz,.loop
	xor	a
	ld	[hl],a
	
	; clear wave display buffer
	ld	hl,WaveDisplayBuffer+63
	ld	b,63
	xor	a
.loop2
	ld	[hl-],a
	dec	b
	jr nz, .loop2
	ld	[hl],a ; hl is now at the start of buffer
	
	; TODO
	ld	a,%11100100
	ld	[rBGP],a
	ret
	
VisualizerSprites:
	db	128,  0,$70,0 ; CH1 freq
	db	136,  0,$70,0 ; CH2 freq
	db	144,  0,$70,0 ; CH3 freq
	db	152,  0,$70,0 ; CH4 freq
	db	152,136,$00,0,152,140,$00,0 ; CH1 envelope/panning
	db	152,144,$00,0,152,148,$00,0 ; CH2 envelope/panning
	db	152,152,$00,0,152,156,$00,0 ; CH3 envelope/panning
	db	152,160,$00,0,152,164,$00,0 ; CH4 envelope/panning
VisualizerSprites_End:
	
VisualizerGfx:	incbin	"VisualizerGFX.bin"
VisualizerGfx_End:
