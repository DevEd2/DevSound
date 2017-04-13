; ================================================================
; DevSound - a Game Boy music system by DevEd
;
; Copyright (c) 2017 Edward J. Whalen
; 
; Permission is hereby granted, free of charge, to any person obtaining
; a copy of this software and associated documentation files (the
; "Software"), to deal in the Software without restriction, including
; without limitation the rights to use, copy, modify, merge, publish,
; distribute, sublicense, and/or sell copies of the Software, and to
; permit persons to whom the Software is furnished to do so, subject to
; the following conditions:
; 
; The above copyright notice and this permission notice shall be included
; in all copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
; IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
; CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
; TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
; ================================================================

include	"DevSound_Vars.asm"
include	"DevSound_Consts.asm"
include	"DevSound_Macros.asm"

SECTION	"DevSound",ROMX

DevSound_JumpTable:

DS_Init:	jp	DevSound_Init
DS_Play:	jp	DevSound_Play
DS_Stop:	jp	DevSound_Stop

; Driver thumbprint
db	"DevSound GB music player by DevEd | email: deved8@gmail.com"

; ================================================================
; Init routine
; INPUT: a = ID of song to init
; ================================================================

DevSound_Init:
	push	af
	push	af		; i swear there's a method to my madness here
	xor	a
	ldh	[rNR52],a	; disable sound

	; init sound RAM area
	ld	de,DSVarsStart
	ld	b,DSVarsEnd-DSVarsStart
	ld	hl,DefaultRegTable
.initLoop
	ld	a,[hl+]
	ld	[de],a
	inc	de
	dec	b
	jr	nz,.initLoop

	; load default waveform
	ld	hl,DefaultWave
	call	LoadWave
	
	; set up song pointers
	ld	hl,SongPointerTable
	pop	af
	add	a
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry		; HERE BE HACKS
	ld	a,[hl+]
	ld	e,a
	ld	a,[hl]
	ld	d,a
	ld	h,d
	ld	l,e
	ld	a,[hl+]
	ld	[CH1Ptr],a
	ld	a,[hl+]
	ld	[CH1Ptr+1],a	
	ld	a,[hl+]
	ld	[CH2Ptr],a
	ld	a,[hl+]
	ld	[CH2Ptr+1],a
	ld	a,[hl+]
	ld	[CH3Ptr],a
	ld	a,[hl+]
	ld	[CH3Ptr+1],a
	ld	a,[hl+]
	ld	[CH4Ptr],a
	ld	a,[hl+]
	ld	[CH4Ptr+1],a
	; get tempo
	ld	hl,SongSpeedTable
	pop	af		; see? I TOLD you there was a method to my madness!
	add	a
	add	l
	ld	l,a
	jr	nc,.nocarry2
	inc	h
.nocarry2
	ld	a,[hl+]
	dec	a
	ld	[GlobalSpeed1],a
	ld	a,[hl]
	dec	a
	ld	[GlobalSpeed2],a
	ld	a,%10000000
	ldh	[rNR52],a
	or	$7f
	ldh	[rNR51],a
	ldh	[rNR50],a
	ret

DefaultRegTable:
	db	0,0,0,0,0,1,1,1,1,1
	dw	DummyChannel,DummyTable,DummyTable,DummyTable,DummyTable
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dw	DummyChannel,DummyTable,DummyTable,DummyTable,DummyTable
	db	0,0,0,0,0,0,0,0,0,0,0,0,0
	dw	DummyChannel,DummyTable,DummyTable,DummyTable,DummyTable
	db	0,0,0,0,0,0,0,0,0,0,0,0,$ff,0,0	; the $FF is so that the wave is updated properly on the first frame
	dw	DummyChannel,DummyTable,DummyTable
	db	0,0,0,0,0,0,0,0,0
	
DefaultWave:	db	$01,$23,$45,$67,$89,$ab,$cd,$ef,$fe,$dc,$ba,$98,$76,$54,$32,$10

; ================================================================
; Stop routine
; ================================================================

DevSound_Stop:
	xor	a
	ldh	[rNR52],a
	ld	[CH1Enabled],a
	ld	[CH2Enabled],a
	ld	[CH3Enabled],a
	ld	[CH4Enabled],a
	ld	[SoundEnabled],a
	ret

; ================================================================
; Play routine
; ================================================================

DevSound_Play:
	; Since this routine is called during an interrupt (which may
	; happen in the middle of a routine), preserve all register
	; values just to be safe.
	push	af
	push	bc
	push	de
	push	hl
	ld	a,[SoundEnabled]
	and	a
	jr	nz,.doUpdate	; if sound is enabled, jump ahead
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
	
.doUpdate	
	; get song timer
	ld	a,[GlobalTimer]	; get global timer
	and	a				; is GlobalTimer non-zero?
	jr	nz,.noupdate	; if yes, don't update
	ld	a,[TickCount]	; get current tick count
	inc	a				; add 1
	ld	[TickCount],a	; store it in RAM
	rra					; check if A is odd
	jr	nc,.odd			; if a is odd, jump
.even
	ld	a,[GlobalSpeed1]
	jr	.setTimer
.odd
	ld	a,[GlobalSpeed2]
.setTimer
	ld	[GlobalTimer],a	; store timer value
	jr	UpdateCH1		; continue ahead
	
.noupdate
	dec	a				; subtract 1 from timer
	ld	[GlobalTimer],a	; store timer value
	jp	DoneUpdating	; done

; ================================================================
	
UpdateCH1:
	ld	a,[CH1Enabled]
	and	a
	jr	z,CH1_DoneUpdating
	ld	a,[CH1Tick]
	and	a
	jr	z,.continue
	dec	a
	ld	[CH1Tick],a
	jp	UpdateCH2	; too far for jr
.continue
	ld	hl,CH1Ptr	; get pointer
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH1Pos]	; get current offset
	ld	c,a			; store offset for later use
	add	l			; hl = hl + a (four lines)
	ld	l,a
	jr	nc,CH1_CheckByte
	inc	h
CH1_CheckByte:
	ld	a,[hl+]		; get byte
	inc	c			; add 1 to offset
	cp	$ff
	jr	z,.endChannel
	bit	7,a			; check for command
	jr	nz,.getCommand
	; if we have a note...
.getNote
	ld	[CH1Note],a
	ld	a,[hl+]
	inc	c
	dec	a
	ld	[CH1Tick],a
	ld	a,[CH1Reset]
	jp	z,CH1_DoneUpdating
	xor	a
	ld	[CH1VolPos],a
	ld	[CH1PulsePos],a
	ld	[CH1ArpPos],a
	ld	[CH1VibPos],a
	ldh	[rNR12],a
	jp	CH1_DoneUpdating
.getCommand
	push	hl
	sub	$80
	add	a
	add	a,CH1_CommandTable%256
	ld	l,a
	adc	a,CH1_CommandTable/256
	sub	l
	ld	h,a
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	jp	[hl]
	
.endChannel
	xor	a
	ld	[CH1Enabled],a
	jp	UpdateCH2
	
CH1_DoneUpdating:
	ld	a,c
	ld	[CH1Pos],a
	jp	UpdateCH2	; too far for jr
		
CH1_CommandTable
	dw	.setInstrument
	dw	.setLoopPoint
	dw	.gotoLoopPoint
	dw	.setChannelPtr
	dw	.pitchBendUp
	dw	.pitchBendDown
	dw	.setSweep
	dw	.setPan
	dw	.setSpeed

.setInstrument
	pop	hl
	ld	a,[hl+]
	inc	c
	push	hl
	ld	hl,InstrumentTable
	add	a
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	; no reset flag
	ld	a,[hl+]
	ld	[CH1Reset],a
	ld	b,a
	; wave mode flag (unused for ch1)
	inc	hl
	; vol table
	ld	a,[hl+]
	ld	[CH1VolPtr],a
	ld	a,[hl+]
	ld	[CH1VolPtr+1],a
	; arp table
	ld	a,[hl+]
	ld	[CH1ArpPtr],a
	ld	a,[hl+]
	ld	[CH1ArpPtr+1],a
	; pulse table
	ld	a,[hl+]
	ld	[CH1PulsePtr],a
	ld	a,[hl+]
	ld	[CH1PulsePtr+1],a
	; vib table
	ld	a,[hl+]
	ld	[CH1VibPtr],a
	ld	a,[hl+]
	ld	[CH1VibPtr+1],a
	pop	hl
	jp	CH1_CheckByte	; too far for jr
	
.setLoopPoint
	pop	hl
	ld	a,c
	ld	[CH1LoopPos],a
	jp	CH1_CheckByte	; too far for jr
	
.gotoLoopPoint
	pop	hl
	ld	a,[CH1LoopPos]
	ld	[CH1Pos],a
	jp	UpdateCH1		; too far for jr
	
.setChannelPtr
	pop	hl
	ld	a,[hl+]
	ld	[CH1Ptr],a
	ld	a,[hl]
	ld	[CH1Ptr+1],a
	xor	a
	ld	c,a
	ld	[CH1Pos],a
	jp	UpdateCH1

.pitchBendUp	; TODO
	pop	hl
	inc	hl
	inc	c
	jp	CH1_CheckByte	; too far for jr
	
.pitchBendDown	; TODO
	pop	hl
	inc	hl
	inc	c
	jp	CH1_CheckByte	; too far for jr

.setSweep		; TODO
	pop	hl
	inc	hl
	inc	c
	jp	CH1_CheckByte	; too far for jr

.setPan			; TODO
	pop	hl
	inc	hl
	inc	c
	jp	CH1_CheckByte	; too far for jr

.setSpeed
	pop	hl
	ld	a,[hl+]
	inc	c
	dec	a
	ld	[GlobalSpeed1],a
	ld	a,[hl+]
	inc	c
	dec	a
	ld	[GlobalSpeed2],a
	jp	CH1_CheckByte	; too far for jr
	
; ================================================================
	
UpdateCH2:
	ld	a,[CH2Enabled]
	and	a
	jr	z,CH2_DoneUpdating
	ld	a,[CH2Tick]
	and	a
	jr	z,.continue
	dec	a
	ld	[CH2Tick],a
	jp	UpdateCH3	; too far for jr
.continue
	ld	hl,CH2Ptr	; get pointer
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH2Pos]	; get current offset
	ld	c,a			; store offset for later use
	add	l			; hl = hl + a (four lines)
	ld	l,a
	jr	nc,CH2_CheckByte
	inc	h
CH2_CheckByte:
	ld	a,[hl+]		; get byte
	inc	c			; add 1 to offset
	cp	$ff
	jr	z,.endChannel
	bit	7,a			; check for command
	jr	nz,.getCommand	
	; if we have a note...
.getNote
	ld	[CH2Note],a
	ld	a,[hl+]
	inc	c
	dec	a
	ld	[CH2Tick],a
	ld	a,[CH2Reset]
	jp	z,CH2_DoneUpdating
	xor	a
	ld	[CH2VolPos],a
	ld	[CH2PulsePos],a
	ld	[CH2ArpPos],a
	ld	[CH2VibPos],a
	ldh	[rNR22],a
	jp	CH2_DoneUpdating
.getCommand
	push	hl
	sub	$80
	add	a
	add	a,CH2_CommandTable%256
	ld	l,a
	adc	a,CH2_CommandTable/256
	sub	l
	ld	h,a
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	jp	[hl]
	
.endChannel
	xor	a
	ld	[CH2Enabled],a
	jp	UpdateCH3
	
CH2_DoneUpdating:
	ld	a,c
	ld	[CH2Pos],a
	jp	UpdateCH3
		
CH2_CommandTable
	dw	.setInstrument
	dw	.setLoopPoint
	dw	.gotoLoopPoint
	dw	.setChannelPtr
	dw	.pitchBendUp
	dw	.pitchBendDown
	dw	.setSweep
	dw	.setPan
	dw	.setSpeed

.setInstrument
	pop	hl
	ld	a,[hl+]
	inc	c
	push	hl
	ld	hl,InstrumentTable
	add	a
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	; no reset flag
	ld	a,[hl+]
	ld	[CH2Reset],a
	ld	b,a
	; wave mode flag (unused for CH2)
	inc	hl
	; vol table
	ld	a,[hl+]
	ld	[CH2VolPtr],a
	ld	a,[hl+]
	ld	[CH2VolPtr+1],a
	; arp table
	ld	a,[hl+]
	ld	[CH2ArpPtr],a
	ld	a,[hl+]
	ld	[CH2ArpPtr+1],a
	; pulse table
	ld	a,[hl+]
	ld	[CH2PulsePtr],a
	ld	a,[hl+]
	ld	[CH2PulsePtr+1],a
	; vib table
	ld	a,[hl+]
	ld	[CH2VibPtr],a
	ld	a,[hl+]
	ld	[CH2VibPtr+1],a
	pop	hl
	jp	CH2_CheckByte	; too far for jr
	
.setLoopPoint
	pop	hl
	ld	a,c
	ld	[CH2LoopPos],a
	jp	CH2_CheckByte	; too far for jr
	
.gotoLoopPoint
	pop	hl
	ld	a,[CH2LoopPos]
	ld	[CH2Pos],a
	jp	UpdateCH2		; too far for jr
	
.setChannelPtr
	pop	hl
	ld	a,[hl+]
	ld	[CH2Ptr],a
	ld	a,[hl]
	ld	[CH2Ptr+1],a
	xor	a
	ld	c,a
	ld	[CH2Pos],a
	jp	UpdateCH2

.pitchBendUp	; TODO
	pop	hl
	inc	hl
	inc	c
	jp	CH2_CheckByte	; too far for jr
	
.pitchBendDown	; TODO
	pop	hl
	inc	hl
	inc	c
	jp	CH2_CheckByte	; too far for jr

.setSweep		; TODO
	pop	hl
	inc	hl
	inc	c
	jp	CH2_CheckByte	; too far for jr

.setPan			; TODO
	pop	hl
	inc	hl
	inc	c
	jp	CH2_CheckByte	; too far for jr

.setSpeed
	pop	hl
	ld	a,[hl+]
	inc	c
	dec	a
	ld	[GlobalSpeed1],a
	ld	a,[hl+]
	inc	c
	dec	a
	ld	[GlobalSpeed2],a
	jp	CH2_CheckByte	; too far for jr
	
; ================================================================
	
UpdateCH3:
	ld	a,[CH3Enabled]
	and	a
	jr	z,CH3_DoneUpdating
	ld	a,[CH3Tick]
	and	a
	jr	z,.continue
	dec	a
	ld	[CH3Tick],a
	jp	UpdateCH4	; too far for jr
.continue
	ld	hl,CH3Ptr	; get pointer
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH3Pos]	; get current offset
	ld	c,a			; store offset for later use
	add	l			; hl = hl + a (four lines)
	ld	l,a
	jr	nc,CH3_CheckByte
	inc	h
CH3_CheckByte:
	ld	a,[hl+]		; get byte
	inc	c			; add 1 to offset
	cp	$ff
	jr	z,.endChannel
	bit	7,a			; check for command
	jr	nz,.getCommand
	; if we have a note...
.getNote
	ld	[CH3Note],a
	ld	a,[hl+]
	inc	c
	dec	a
	ld	[CH3Tick],a
	ld	a,[CH3Reset]
	jp	z,CH3_DoneUpdating
	xor	a
	ld	[CH3VolPos],a
	ld	[CH3WavePos],a
	ld	[CH3ArpPos],a
	ld	[CH3VibPos],a
	jp	CH3_DoneUpdating
.getCommand
	push	hl
	sub	$80
	add	a
	add	a,CH3_CommandTable%256
	ld	l,a
	adc	a,CH3_CommandTable/256
	sub	l
	ld	h,a
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	jp	[hl]
	
.endChannel
	xor	a
	ld	[CH3Enabled],a
	jp	UpdateCH4
	
CH3_DoneUpdating:
	ld	a,c
	ld	[CH3Pos],a
	jp	UpdateCH4	; too far for jr
		
CH3_CommandTable
	dw	.setInstrument
	dw	.setLoopPoint
	dw	.gotoLoopPoint
	dw	.setChannelPtr
	dw	.pitchBendUp
	dw	.pitchBendDown
	dw	.setSweep
	dw	.setPan
	dw	.setSpeed

.setInstrument
	pop	hl
	ld	a,[hl+]
	inc	c
	push	hl
	ld	hl,InstrumentTable
	add	a
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	; no reset flag
	ld	a,[hl+]
	ld	[CH3Reset],a
	ld	b,a
	; wave mode flag (unused for CH3)
	ld	a,[hl+]
	ld	[CH3Mode],a
	; vol table
	ld	a,[hl+]
	ld	[CH3VolPtr],a
	ld	a,[hl+]
	ld	[CH3VolPtr+1],a
	; arp table
	ld	a,[hl+]
	ld	[CH3ArpPtr],a
	ld	a,[hl+]
	ld	[CH3ArpPtr+1],a
	; pulse table
	ld	a,[hl+]
	ld	[CH3WavePtr],a
	ld	a,[hl+]
	ld	[CH3WavePtr+1],a
	; vib table
	ld	a,[hl+]
	ld	[CH3VibPtr],a
	ld	a,[hl+]
	ld	[CH3VibPtr+1],a
	pop	hl
	jp	CH3_CheckByte	; too far for jr
	
.setLoopPoint
	pop	hl
	ld	a,c
	ld	[CH3LoopPos],a
	jp	CH3_CheckByte	; too far for jr
	
.gotoLoopPoint
	pop	hl
	ld	a,[CH3LoopPos]
	ld	[CH3Pos],a
	jp	UpdateCH3		; too far for jr
	
.setChannelPtr
	pop	hl
	ld	a,[hl+]
	ld	[CH3Ptr],a
	ld	a,[hl]
	ld	[CH3Ptr+1],a
	xor	a
	ld	c,a
	ld	[CH3Pos],a
	jp	UpdateCH3

.pitchBendUp	; TODO
	pop	hl
	inc	hl
	inc	c
	jp	CH3_CheckByte	; too far for jr
	
.pitchBendDown	; TODO
	pop	hl
	inc	hl
	inc	c
	jp	CH3_CheckByte	; too far for jr

.setSweep		; TODO
	pop	hl
	inc	hl
	inc	c
	jp	CH3_CheckByte	; too far for jr

.setPan			; TODO
	pop	hl
	inc	hl
	inc	c
	jp	CH3_CheckByte	; too far for jr

.setSpeed
	pop	hl
	ld	a,[hl+]
	inc	c
	dec	a
	ld	[GlobalSpeed1],a
	ld	a,[hl+]
	inc	c
	dec	a
	ld	[GlobalSpeed2],a
	jp	CH3_CheckByte	; too far for jr
	
; ================================================================

UpdateCH4:
	ld	a,[CH4Enabled]
	and	a
	jr	z,CH4_DoneUpdating
	ld	a,[CH4Tick]
	and	a
	jr	z,.continue
	dec	a
	ld	[CH4Tick],a
	jp	DoneUpdating	; too far for jr
.continue
	ld	hl,CH4Ptr	; get pointer
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH4Pos]	; get current offset
	ld	c,a			; store offset for later use
	add	l			; hl = hl + a (four lines)
	ld	l,a
	jr	nc,CH4_CheckByte
	inc	h
CH4_CheckByte:
	ld	a,[hl+]		; get byte
	inc	c			; add 1 to offset
	cp	$ff
	jr	z,.endChannel
	bit	7,a			; check for command
	jr	nz,.getCommand	
	; if we have a note...
.getNote
	ld	[CH4Mode],a
	ld	a,[hl+]
	inc	c
	dec	a
	ld	[CH4Tick],a
	ld	a,[CH4Reset]
	jp	z,CH4_DoneUpdating
	xor	a
	ld	[CH4VolPos],a
	ld	[CH4NoisePos],a
	ldh	[rNR42],a
	jp	CH4_DoneUpdating
.getCommand
	push	hl
	sub	$80
	add	a
	add	a,CH4_CommandTable%256
	ld	l,a
	adc	a,CH4_CommandTable/256
	sub	l
	ld	h,a
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	jp	[hl]
	
.endChannel
	xor	a
	ld	[CH4Enabled],a
	jp	DoneUpdating
	
CH4_DoneUpdating:
	ld	a,c
	ld	[CH4Pos],a
	jp	DoneUpdating
		
CH4_CommandTable
	dw	.setInstrument
	dw	.setLoopPoint
	dw	.gotoLoopPoint
	dw	.setChannelPtr
	dw	.pitchBendUp
	dw	.pitchBendDown
	dw	.setSweep
	dw	.setPan
	dw	.setSpeed

.setInstrument
	pop	hl
	ld	a,[hl+]
	inc	c
	push	hl
	ld	hl,InstrumentTable
	add	a
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	; no reset flag
	ld	a,[hl+]
	ld	[CH4Reset],a
	ld	b,a
	; wave mode flag (unused for CH4)
	inc	hl
	; vol table
	ld	a,[hl+]
	ld	[CH4VolPtr],a
	ld	a,[hl+]
	ld	[CH4VolPtr+1],a
	; noise mode pointer
	ld	a,[hl+]
	ld	[CH4NoisePtr],a
	ld	a,[hl+]
	ld	[CH4NoisePtr+1],a
	pop	hl
	jp	CH4_CheckByte	; too far for jr
	
.setLoopPoint
	pop	hl
	ld	a,c
	ld	[CH4LoopPos],a
	jp	CH4_CheckByte	; too far for jr
	
.gotoLoopPoint
	pop	hl
	ld	a,[CH4LoopPos]
	ld	[CH4Pos],a
	jp	UpdateCH4		; too far for jr
	
.setChannelPtr
	pop	hl
	ld	a,[hl+]
	ld	[CH4Ptr],a
	ld	a,[hl]
	ld	[CH4Ptr+1],a
	xor	a
	ld	c,a
	ld	[CH4Pos],a
	jp	UpdateCH4

.pitchBendUp	; unused for ch4
	pop	hl
	inc	hl
	inc	c
	jp	CH4_CheckByte	; too far for jr
	
.pitchBendDown	; unused for ch4
	pop	hl
	inc	hl
	inc	c
	jp	CH4_CheckByte	; too far for jr

.setSweep		; unused for ch4
	pop	hl
	inc	hl
	inc	c
	jp	CH4_CheckByte	; too far for jr

.setPan			; unused for ch4
	pop	hl
	inc	hl
	inc	c
	jp	CH4_CheckByte	; too far for jr

.setSpeed
	pop	hl
	ld	a,[hl+]
	inc	c
	dec	a
	ld	[GlobalSpeed1],a
	ld	a,[hl+]
	inc	c
	dec	a
	ld	[GlobalSpeed2],a
	jp	CH4_CheckByte	; too far for jr

; ================================================================

DoneUpdating:
	call	UpdateRegisters
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
	
; ================================================================	

UpdateRegisters:
	
CH1_UpdateRegisters:
	ld	a,[CH1Enabled]
	and	a
	jp	z,CH2_UpdateRegisters

	ld	a,[CH1Note]
	cp	rest
	jr	nz,.norest
	xor	a
	ldh	[rNR12],a
	ldh	a,[rNR14]
	or	%10000000
	ldh	[rNR14],a
	jp	.done
.norest

	; update arps
	ld	hl,CH1ArpPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH1ArpPos]
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	ld	a,[hl+]
	cp	$80
	jr	nz,.noloop
	ld	a,[hl]
	ld	[CH1ArpPos],a
	jr	.continue
.noloop
	cp	$ff
	jr	z,.continue
	ld	[CH1Transpose],a
.noreset
	ld	a,[CH1ArpPos]
	inc	a
	ld	[CH1ArpPos],a
.continue
	
	; update sweep
	xor	a
	ldh	[rNR10],a
	
	; update pulse
	ld	hl,CH1PulsePtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH1PulsePos]
	add	l
	ld	l,a
	jr	nc,.nocarry2
	inc	h
.nocarry2
	ld	a,[hl+]
	cp	$ff
	jr	z,.updateNote
	swap	a
	rl	a
	rl	a
	ldh	[rNR11],a
.noreset2
	ld	a,[CH1PulsePos]
	inc	a
	ld	[CH1PulsePos],a
	ld	a,[hl+]
	cp	$80
	jr	nz,.updateNote
	ld	a,[hl]
	ld	[CH1PulsePos],a
	
; get note
.updateNote
	ld	a,[CH1Transpose]
	ld	b,a
	ld	a,[CH1Note]
	add	b
	
	ld	c,a
	ld	b,0
	
	ld	hl,FreqTable
	add	hl,bc
	add	hl,bc
	
	ld	a,[hl+]
	ldh	[rNR13],a
	ld	a,[hl]
	ldh	[rNR14],a
	ld	e,a

	; update volume
.updateVolume
	ld	hl,CH1VolPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH1VolPos]
	add	l
	ld	l,a
	jr	nc,.nocarry4
	inc	h
.nocarry4
	ld	a,[hl+]
	cp	$ff
	jr	z,.done
	swap	a
	ld	b,a
	ldh	a,[rNR12]
	cp	b
	jr	z,.noreset3
	ld	a,b
	ldh	[rNR12],a
	ld	a,e
	or	$80
	ldh	[rNR14],a
.noreset3
	ld	a,[CH1VolPos]
	inc	a
	ld	[CH1VolPos],a
	ld	a,[hl+]
	cp	$8f
	jr	nz,.done
	ld	a,[hl]
	ld	[CH1VolPos],a
.done

; ================================================================

CH2_UpdateRegisters:
	ld	a,[CH2Enabled]
	and	a
	jp	z,CH3_UpdateRegisters
	
	ld	a,[CH2Note]
	cp	rest
	jr	nz,.norest
	xor	a
	ldh	[rNR22],a
	ldh	a,[rNR24]
	or	%10000000
	ldh	[rNR24],a
	jp	.done
.norest

	; update arps
	ld	hl,CH2ArpPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH2ArpPos]
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	ld	a,[hl+]
	cp	$80
	jr	nz,.noloop
	ld	a,[hl]
	ld	[CH2ArpPos],a
	jr	.continue
.noloop
	cp	$ff
	jr	z,.continue
	ld	[CH2Transpose],a
.noreset
	ld	a,[CH2ArpPos]
	inc	a
	ld	[CH2ArpPos],a
.continue
	
	; update pulse
	ld	hl,CH2PulsePtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH2PulsePos]
	add	l
	ld	l,a
	jr	nc,.nocarry2
	inc	h
.nocarry2
	ld	a,[hl+]
	cp	$ff
	jr	z,.updateNote
	swap	a
	rl	a
	rl	a
	ldh	[rNR21],a
.noreset2
	ld	a,[CH2PulsePos]
	inc	a
	ld	[CH2PulsePos],a
	ld	a,[hl+]
	cp	$80
	jr	nz,.updateNote
	ld	a,[hl]
	ld	[CH2PulsePos],a
	
; get note
.updateNote
	ld	a,[CH2Transpose]
	ld	b,a
	ld	a,[CH2Note]
	add	b
	
	ld	c,a
	ld	b,0
	
	ld	hl,FreqTable
	add	hl,bc
	add	hl,bc
	
	ld	a,[hl+]
	ldh	[rNR23],a
	ld	a,[hl]
	ldh	[rNR24],a
	ld	e,a

	; update volume
.updateVolume
	ld	hl,CH2VolPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH2VolPos]
	add	l
	ld	l,a
	jr	nc,.nocarry4
	inc	h
.nocarry4
	ld	a,[hl+]
	cp	$ff
	jr	z,.done
	swap	a
	ld	b,a
	ldh	a,[rNR22]
	cp	b
	jr	z,.noreset3
	ld	a,b
	ldh	[rNR22],a
	ld	a,e
	or	$80
	ldh	[rNR24],a
.noreset3
	ld	a,[CH2VolPos]
	inc	a
	ld	[CH2VolPos],a
	ld	a,[hl+]
	cp	$8f
	jr	nz,.done
	ld	a,[hl]
	ld	[CH2VolPos],a
.done

; ================================================================

CH3_UpdateRegisters:
	ld	a,[CH3Enabled]
	and	a
	jp	z,CH4_UpdateRegisters
	
	ld	a,[CH3Note]
	cp	rest
	jr	nz,.norest
	xor	a
	ldh	[rNR32],a
	ld	[CH3Vol],a
	ldh	a,[rNR34]
	or	%10000000
	ldh	[rNR34],a
	jp	.done
.norest

	; update arps
	ld	hl,CH3ArpPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH3ArpPos]
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	ld	a,[hl+]
	cp	$80
	jr	nz,.noloop
	ld	a,[hl]
	ld	[CH3ArpPos],a
	jr	.continue
.noloop
	cp	$ff
	jr	z,.continue
	ld	[CH3Transpose],a
.noreset
	ld	a,[CH3ArpPos]
	inc	a
	ld	[CH3ArpPos],a
.continue

	xor	a
	ldh	[rNR31],a
	or	%10000000
	ldh	[rNR30],a
	
; get note
.updateNote
	ld	a,[CH3Transpose]
	ld	b,a
	ld	a,[CH3Note]
	add	b
	
	ld	c,a
	ld	b,0
	
	ld	hl,FreqTable
	add	hl,bc
	add	hl,bc
	
	ld	a,[hl+]
	ldh	[rNR33],a
	ld	a,[hl]
	ldh	[rNR34],a
	ld	e,a
	
	; update wave
	ld	hl,CH3WavePtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH3WavePos]
	add	l
	ld	l,a
	jr	nc,.nocarry2
	inc	h
.nocarry2
	ld	a,[hl+]
	cp	$ff
	jr	z,.updateVolume
	ld	b,a
	ld	a,[CH3Wave]
	cp	b
	jr	z,.noreset2
	ld	a,b
	ld	[CH3Wave],a
	add	a
	ld	hl,WaveTable
	add	l
	ld	l,a
	jr	nc,.nocarry3
	inc	h	
.nocarry3
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	call	LoadWave
	ld	a,e
	or	%10000000
	ldh	[rNR34],a
.noreset2
	ld	a,[CH3WavePos]
	inc	a
	ld	[CH3WavePos],a
	ld	a,[hl+]
	cp	$80
	jr	nz,.updateVolume
	ld	a,[hl]
	ld	[CH3WavePos],a

.updateVolume
	ld	hl,CH3VolPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH3VolPos]
	add	l
	ld	l,a
	jr	nc,.nocarry4
	inc	h
.nocarry4
	ld	a,[hl+]
	cp	$ff
	jr	z,.done
	ld	b,a
	ld	a,[CH3Vol]
	cp	b
	jr	z,.noreset3
	ld	a,b
	ldh	[rNR32],a
	ld	[CH3Vol],a
	ld	a,e
	or	$80
	ldh	[rNR34],a
.noreset3
	ld	a,[CH3VolPos]
	inc	a
	ld	[CH3VolPos],a
	ld	a,[hl+]
	cp	$80
	jr	nz,.done
	ld	a,[hl]
	ld	[CH3VolPos],a
.done

; ================================================================

CH4_UpdateRegisters:
	ld	a,[CH4Enabled]
	and	a
	jp	z,DoneUpdatingRegisters
	
	ld	a,[CH4Mode]
	cp	rest
	jr	nz,.norest
	xor	a
	ldh	[rNR42],a
	ldh	a,[rNR44]
	or	%10000000
	ldh	[rNR44],a
	jp	.done
.norest

	; update arps
	ld	hl,CH4NoisePtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH4NoisePos]
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	ld	a,[hl+]
	cp	$80
	jr	nz,.noloop
	ld	a,[hl]
	ld	[CH4NoisePos],a
	jr	.continue
.noloop
	cp	$ff
	jr	z,.continue
	ld	[CH4Transpose],a
.noreset
	ld	a,[CH4NoisePos]
	inc	a
	ld	[CH4NoisePos],a
.continue
	
; get note
.updateNote
	ld	a,[CH4Transpose]
	ld	b,a
	ld	a,[CH4Mode]
	add	b
	
	ld	hl,NoiseTable
	add	l
	ld	l,a
	jr	nc,.nocarry2
	inc	h
.nocarry2
	
	ld	a,[hl+]
	ldh	[rNR43],a	

	; update volume
.updateVolume
	ld	hl,CH4VolPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH4VolPos]
	add	l
	ld	l,a
	jr	nc,.nocarry3
	inc	h
.nocarry3
	ld	a,[hl+]
	cp	$ff
	jr	z,.done
	swap	a
	ld	b,a
	ldh	a,[rNR42]
	cp	b
	jr	z,.noreset3
	ld	a,b
	ldh	[rNR42],a
	ld	a,%10000000
	ldh	[rNR44],a
.noreset3
	ld	a,[CH4VolPos]
	inc	a
	ld	[CH4VolPos],a
	ld	a,[hl+]
	cp	$8f
	jr	nz,.done
	ld	a,[hl]
	ld	[CH4VolPos],a
.done
	
DoneUpdatingRegisters:
	ret
	

; ================================================================
; Subroutines
; ================================================================

LoadWave:
	xor	a
	ldh	[rNR30],a	; disable CH3
	ld	bc,$1030	; b = counter, c = HRAM address
.loop
	ld	a,[hl+]		; get byte from hl
	ld	[c],a		; copy to wave ram
	inc	c
	dec	b
	jr	nz,.loop	; loop until done
	ld	a,%10000000
	ldh	[rNR30],a	; enable CH3
	ret

; ================================================================
; Frequency table
; ================================================================

FreqTable:  
;	     C-x  C#x  D-x  D#x  E-x  F-x  F#x  G-x  G#x  A-x  A#x  B-x
	dw	$02c,$09c,$106,$16b,$1c9,$223,$277,$2c6,$312,$356,$39b,$3da ; octave 1
	dw	$416,$44e,$483,$4b5,$4e5,$511,$53b,$563,$589,$5ac,$5ce,$5ed ; octave 2
	dw	$60a,$627,$642,$65b,$672,$689,$69e,$6b2,$6c4,$6d6,$6e7,$6f7 ; octave 3
	dw	$706,$714,$721,$72d,$739,$744,$74f,$759,$762,$76b,$773,$77b ; octave 4
	dw	$783,$78a,$790,$797,$79d,$7a2,$7a7,$7ac,$7b1,$7b4,$7ba,$7be ; octave 5
	dw	$7c1,$7c4,$7c8,$7cb,$7ce,$7d1,$7d4,$7d6,$7d9,$7db,$7dd,$7df ; octave 6
	
NoiseTable:	; taken from deflemask
	db	$a4	; 15 steps
	db	$97,$96,$95,$94,$87,$86,$85,$84,$77,$76,$75,$74,$67,$66,$65,$64
	db	$57,$56,$55,$54,$47,$46,$45,$44,$37,$36,$35,$34,$27,$26,$25,$24
	db	$17,$16,$15,$14,$07,$06,$05,$04,$03,$02,$01,$00
	db	$ac	; 7 steps
	db	$9f,$9e,$9d,$9c,$8f,$8e,$8d,$8c,$7f,$7e,$7d,$7c,$6f,$6e,$6d,$64
	db	$5f,$5e,$5d,$5c,$4f,$4e,$4d,$4c,$3f,$3e,$3d,$3c,$2f,$2e,$2d,$24
	db	$1f,$1e,$1d,$1c,$0f,$0e,$0d,$0c,$03,$02,$01,$00
	
; ================================================================
; Song data
; TODO: Separate this data to its own file so users don't have to
; scroll through this entire file
; ================================================================

DummyTable:	db	$ff

DummyChannel:
	db	EndChannel
	
; =================================================================

SongSpeedTable:
	db	4,3			; test
	db	6,6			; gadunk
	db	3,3			; hw envelope test
	
SongPointerTable:
	dw	PT_TestSong
	dw	PT_Gadunk
	dw	PT_HWEnvTest
	
; =================================================================

; Wave volume values
w0			equ	%00000000
w1			equ	%01100000
w2			equ	%01000000
w3			equ	%00100000

; For pulse instruments, volume control is software-based by default.
; However, hardware volume envelopes may still be used by adding the
; envelope length * $10.
; Example: $3F = initial volume $F, env. length $3
; Repeat that value for the desired length.
; Note that using initial volume $F + envelope length $F will be
; interpreted as a "table end" command, use initial volume $F +
; envelope length $0 instead.
; Same applies to initial volume $F + envelope length $8 which
; is interpreted as a "loop" command, use initial volume $F +
; envelope length $0 instead.

vol_Gadunk: 	db	15,5,10,5,2,6,10,15,12,6,10,7,8,9,10,15,4,3,2,1,$8f,0
vol_Arp:		db	8,8,8,7,7,7,6,6,6,5,5,5,4,4,4,4,3,3,3,3,3,2,2,2,2,2,2,1,1,1,1,1,1,1,1,0,$ff
vol_OctArp:		db	12,11,10,9,9,8,8,8,7,7,6,6,7,7,6,6,5,5,5,5,5,5,4,4,4,4,4,4,4,3,3,3,3,3,3,2,2,2,2,2,2,1,1,1,1,1,1,0,$ff
vol_HWEnvTest:	db	$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$77,$ff
vol_Bass1:		db	w3,$ff
vol_Bass2:		db	w3,w3,w3,w3,w1,$ff
vol_Bass3:		db	w3,w3,w3,w3,w3,w3,w3,w2,w2,w2,w2,w1,$ff

vol_Kick:		db	$18,$ff
vol_Snare:		db	$1d,$ff
vol_OHH:		db	$48,$ff
vol_CymbQ:		db	$6a,$ff
vol_CymbL:		db	$3f,$ff

; =================================================================

arp_Gadunk: 	db	20,22,19,14,20,5,0,15,20,$ff
arp_Pluck059:	db	19,0,5,5,9,9,0,$80,1
arp_Pluck047:	db	19,0,4,4,7,7,0,$80,1
arp_Octave:		db	0,19,12,12,0,0,0,0,12,$80,2
arp_Test:		db	0,0,4,4,7,7,$80,0
arp_Pluck:		db	12,0,$ff

; Noise values are the same as Deflemask, but with one exception:
; To convert 7-step noise values (noise mode 1 in deflemask) to a
; format usable by DevSound, take the corresponding value in the
; arpeggio macro and add s7.
; Example: db s7+32 = noise value 32 with step lengh 7
; Note that each noiseseq must be terminated with a loop command
; ($80) otherwise the noise value will reset!

s7	equ	$2d

noiseseq_Kick:	db	32,26,37,$80,2
noiseseq_Snare:	db	s7+29,s7+23,s7+20,35,$80,3
noiseseq_Hat:	db	39,43,$80,1

; =================================================================

pulse_Dummy:	db	0,$ff
pulse_Arp:		db	2,2,2,1,1,1,0,0,0,3,3,3,$80,0
pulse_OctArp:	db	2,2,2,1,1,2,$ff

; =================================================================
	
vib_Dummy
	dw	0,$80,$00

; =================================================================

WaveTable:
	dw	wave_Bass
	dw	DefaultWave
	
wave_Bass:	db	$00,$01,$11,$11,$22,$11,$00,$02,$57,$76,$7a,$cc,$ee,$fc,$b1,$23
;	wave_Square:	db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00

waveseq_Bass:	db	0,$ff
waveseq_Tri:	db	1,$ff

; =================================================================

InstrumentTable:
	dw	ins_Gadunk
	dw	ins_Arp1
	dw	ins_Arp2
	dw	ins_OctArp
	dw	ins_Bass1
	dw	ins_Bass2
	dw	ins_Bass3
	dw	ins_GadunkWave
	dw	ins_Test
	dw	ins_Kick
	dw	ins_Snare
	dw	ins_CHH
	dw	ins_OHH
	dw	ins_CymbQ
	dw	ins_CymbL

; Instrument format: [no reset flag],[wave mode (ch3 only)],[voltable id],[arptable id],[pulsetable/wavetable id],[vibtable id]
; note that wave mode must be 0 for non-wave instruments
; !!! REMEMBER TO ADD INSTRUMENTS TO THE INSTRUMENT POINTER TABLE !!!
ins_Gadunk:		Instrument	0,0,vol_Gadunk,arp_Gadunk,pulse_Dummy,vib_Dummy
ins_Arp1:		Instrument	0,0,vol_Arp,arp_Pluck059,pulse_Arp,vib_Dummy
ins_Arp2:		Instrument	0,0,vol_Arp,arp_Pluck047,pulse_Arp,vib_Dummy
ins_OctArp:		Instrument	0,0,vol_OctArp,arp_Octave,pulse_OctArp,vib_Dummy
ins_Bass1:		Instrument	0,0,vol_Bass1,arp_Pluck,waveseq_Bass,vib_Dummy
ins_Bass2:		Instrument	0,0,vol_Bass2,arp_Pluck,waveseq_Bass,vib_Dummy
ins_Bass3:		Instrument	0,0,vol_Bass3,arp_Pluck,waveseq_Bass,vib_Dummy
ins_GadunkWave:	Instrument	0,0,vol_Bass1,arp_Gadunk,waveseq_Tri,vib_Dummy
ins_Test:		Instrument	0,0,vol_HWEnvTest,arp_Test,pulse_Arp,vib_Dummy
ins_Kick:		Instrument	0,0,vol_Kick,noiseseq_Kick,DummyTable,DummyTable	; pulse/waveseq and vibrato unused by noise instruments
ins_Snare:		Instrument	0,0,vol_Snare,noiseseq_Snare,DummyTable,DummyTable
ins_CHH:		Instrument	0,0,vol_Kick,noiseseq_Hat,DummyTable,DummyTable
ins_OHH:		Instrument	0,0,vol_OHH,noiseseq_Hat,DummyTable,DummyTable
ins_CymbQ:		Instrument	0,0,vol_CymbQ,noiseseq_Hat,DummyTable,DummyTable
ins_CymbL:		Instrument	0,0,vol_CymbL,noiseseq_Hat,DummyTable,DummyTable	

_ins_Gadunk		equ	0
_ins_Arp1		equ	1
_ins_Arp2		equ	2
_ins_OctArp		equ	3
_ins_Bass1		equ	4
_ins_Bass2		equ	5
_ins_Bass3		equ	6
_ins_GadunkWave	equ	7
_ins_Test		equ	8
_ins_Kick		equ	9
_ins_Snare		equ	10
_ins_CHH		equ	11
_ins_OHH		equ	12
_ins_CymbQ		equ	13
_ins_CymbL		equ	14

Kick	equ	_ins_Kick
Snare	equ	_ins_Snare
CHH		equ	_ins_CHH
OHH		equ	_ins_OHH
CymbQ	equ	_ins_CymbQ
CymbL	equ	_ins_CymbL


; =================================================================

PT_Gadunk:	dw	Gadunk_CH1,DummyChannel,Gadunk_CH3,DummyChannel

Gadunk_CH1:
	db	SetInstrument,_ins_Gadunk
	db	SetLoopPoint
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	F_3,3,rest,1
	db	F_3,3,rest,1
	db	F_3,3,rest,1
	db	F_3,3,rest,1
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	F_3,3,rest,1
	db	F_3,3,rest,1
	db	F#3,3,rest,1
	db	F#3,3,rest,1
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	F_3,3,rest,1
	db	F_3,3,rest,1
	db	F_3,3,rest,1
	db	F_3,3,rest,1
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	F_3,3,rest,1
	db	F_3,3,rest,1
	db	F#3,3,rest,1
	db	F#3,3,rest,1
	db	F#3,12,rest,76	
	db	GotoLoopPoint
	db	EndChannel
	
Gadunk_CH3:
	db	SetLoopPoint
	db	rest,132
	db	$80,7
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	F_3,3,rest,1
	db	F_3,3,rest,1
	db	F_3,3,rest,1
	db	F_3,3,rest,1
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	G#3,3,rest,1
	db	F_3,3,rest,1
	db	F_3,3,rest,1
	db	F#3,3,rest,1
	db	F#3,3,rest,1
	db	F#3,9,rest,7
	db	GotoLoopPoint
	db	EndChannel
	
; =================================================================
	
PT_TestSong:
	dw	TestSong_CH1,TestSong_CH2,TestSong_CH3,TestSong_CH4
	
TestSong_CH1:
	db	SetInstrument,_ins_OctArp
	db	SetLoopPoint
	db	F_5,6,D#5,6,F_5,8,F_5,4,G#5,4,F_5,4,D#5,4,C#5,4,D#5,4,F_5,4,D#5,6,C#5,6,A#4,4
	db	C#5,20,A#4,4,C#5,4,D#5,4,F_5,6,F#5,6,F_5,4,C#5,8,D#5,8
	db	F_5,6,D#5,6,F_5,8,F_5,4,G#5,4,F_5,4,D#5,4,C#5,4,D#5,4,F_5,4,D#5,6,C#5,6,A#4,4
	db	C#5,20,C#5,4,D#5,4,C#5,4,A#5,6,B_5,6,A#5,4,F#5,8,G#5,8
	db	GotoLoopPoint
	db	EndChannel
	
TestSong_CH2:
	db	SetLoopPoint
	db	$80,1,G#4,6,G#4,6,G#4,12,G#4,4,G#4,4,$80,2,G#4,4,G#4,4,G#4,4,$80,1,G#4,4,$80,2,G#4,6,G#4,6,$80,1,G#4,4
	db	$80,2,B_4,6,B_4,6,B_4,12,$80,1,B_4,4,$80,2,B_4,4,F#4,4,F#4,4,F#4,4,$80,1,F#4,4,$80,2,F#4,6,$80,1,E_4,6,F#4,4
	db	$80,1,G#4,6,G#4,6,G#4,12,G#4,4,G#4,4,$80,2,G#4,4,G#4,4,G#4,4,$80,1,G#4,4,$80,2,G#4,6,G#4,6,$80,1,G#4,4
	db	$80,2,B_4,6,B_4,6,B_4,12,$80,1,B_4,4,$80,2,B_4,4,F#5,4,F#5,4,F#5,4,$80,1,F#5,4,$80,2,F#5,6,$80,1,E_5,6,F#5,4
	db	GotoLoopPoint
	db	EndChannel
	
TestSong_CH3:
	db	SetInstrument,4
	db	SetLoopPoint
	db	C#3,4,C#4,2,$80,5,C#3,2,$80,4,G#3,4,C#4,4,C#3,4,$80,6,C#4,4,$80,4,G#3,4,C#4,4
	db	G#2,4,G#3,2,$80,5,G#2,2,$80,4,D#3,4,G#3,4,G#2,4,$80,6,G#3,4,$80,4,G#2,4,A#2,4
	db	B_2,4,B_3,2,$80,5,B_2,2,$80,4,F#3,4,B_3,4,B_2,4,$80,6,B_3,4,$80,4,C#4,4,B_3,4
	db	F#2,4,F#3,2,$80,5,F#2,2,$80,4,C#3,4,F#3,4,F#2,4,$80,6,F#3,4,$80,4,B_2,4,B_3,4
	db	GotoLoopPoint
	db	EndChannel
	
TestSong_CH4:
.block0
	db	SetLoopPoint
	Drum	CymbL,8
	Drum	Snare,4
	Drum	CHH,4
	Drum	Kick,4
	Drum	CHH,2
	db		fix,2
	Drum	Snare,4
	Drum	OHH,4
	Drum	Kick,4
	Drum	CHH,4
	Drum	Snare,4
	Drum	CHH,4
	Drum	Kick,4
	Drum	CHH,2
	db		fix,2
	Drum	Snare,4
	Drum	Kick,2
	Drum	CHH,2
	Drum	Kick,4
	Drum	CHH,4
	Drum	Snare,4
	Drum	CHH,4
	Drum	Kick,4
	Drum	CHH,2
	db		fix,2
	Drum	Snare,4
	Drum	OHH,4
	Drum	Kick,4
	Drum	CHH,4
	Drum	Snare,4
	Drum	CHH,4
	Drum	Kick,4
	Drum	CHH,2
	db		fix,2
	Drum	Snare,4
	Drum	Kick,2
	Drum	CHH,2
	db	SetChannelPtr
	dw	.block1
	db	EndChannel
	
.block1
	Drum	Kick,4
	Drum	CHH,4
	Drum	Snare,4
	Drum	CHH,4
	Drum	Kick,4
	Drum	CHH,2
	db		fix,2
	Drum	Snare,4
	Drum	OHH,4
	Drum	Kick,4
	Drum	CHH,4
	Drum	Snare,4
	Drum	CHH,4
	Drum	Kick,4
	Drum	CHH,2
	db		fix,2
	Drum	Snare,4
	Drum	Kick,2
	Drum	CHH,2
	Drum	Kick,4
	Drum	CHH,4
	Drum	Snare,4
	Drum	CHH,4
	Drum	Kick,4
	Drum	CHH,2
	db		fix,2
	Drum	Snare,4
	Drum	OHH,4
	Drum	Kick,4
	Drum	CHH,4
	Drum	Snare,4
	Drum	CHH,4
	Drum	Kick,4
	Drum	CHH,2
	db		fix,2
	Drum	Snare,4
	db		fix,2
	db		fix,2
	db	SetChannelPtr
	dw	.block0
	db	EndChannel
	
; =================================================================

PT_HWEnvTest:
	dw	HWEnvTest_CH1,DummyChannel,DummyChannel,HWEnvTest_CH4
	
HWEnvTest_CH1:
	db	SetInstrument,_ins_Test
	db	C_4,16
	db	EndChannel
	
HWEnvTest_CH4:
	Drum	Snare,16
	db	EndChannel