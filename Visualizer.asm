; ================================================================
; DevSound Visualizer
; ================================================================

;

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
	ld	a,[CH3OutputLevel]
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

UpdateVisualizer:
	ld	a,%11100101
	ld	[rBGP],a
	
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
	
	; calculate ch1-3 frequency sprite's x position based on their computed frequencies
	; using some of hax math from Anniversary Crystal's music player
	
	; TODO
	ld	a,%11100100
	ld	[rBGP],a
	ret
	
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
