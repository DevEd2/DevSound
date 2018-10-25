; ================================================================
; DevSound - a Game Boy music system by DevEd
;
; Copyright (c) 2017 - 2018 DevEd
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

; Uncomment the following line to enable custom hooks.
; UseCustomHooks		set	1

; Uncomment the following line if you want the DevSound player code to be in ROM0 instead of its own bank.
; Could be useful for multibank setups.
; TODO: Make some tweaks to song data format to allow for multiple banks
; UseROM0				set	1

; Uncomment the following line if you want to include song data elsewhere.
; Could be useful for multibank setups.
; TODO: Make some tweaks to song data format to allow for multiple banks
; DontIncludeSongData	set	1

; Comment the following line to disable SFX support (via FX Hammer).
; Useful if you want to use your own sound effect system.
; (Note that DevSound may require some minor modifications if you
; want to use your own SFX system.)
UseFXHammer				set	1

; Uncomment this to disable all time-consuming features
; This includes: wave buffer, PWM, random wave, zombie mode,
; wave volume scaling, channel volume
; WARNING: Any songs that use the additional features will crash DevSound!
; DemoSceneMode 		set	1

; Uncomment this to to disable wave volume scaling.
; PROS: Less CPU usage
; CONS: Less volume control for CH3
; NoWaveVolumeScaling	set	1

; Uncomment this to disable zombie mode (for compatibility
; with old emulators such as VBA).
; NOTE: Zombie mode is known to be problematic with certain
; GBC CPU revisions. If you want your game/demo to be
; compatible with all GBC hardware revisions, I would
; recommend disabling this.
; PROS: Less CPU usage
;		Compatible with old emulators such as VBA
; CONS: Volume envelopes will sound "dirtier"
; DisableZombieMode		set	1

; Comment this line to enable Deflemask compatibility hacks.
DisableDeflehacks		set	1

; Uncomment this line for a simplified echo buffer. Useful if RAM usage
; is a concern.
; PROS: Less RAM usage
; CONS: Echo delay will be disabled
; SimpleEchoBuffer		set	1

if	!def(UseFXHammerDisasm)
FXHammer_SFXCH2		equ	$c7cc
FXHammer_SFXCH4		equ	$c7d9
endc

DevSound:

include	"DevSound_Vars.asm"
include	"DevSound_Consts.asm"
include	"DevSound_Macros.asm"

if    !def(UseROM0)
SECTION    "DevSound",ROMX
else
SECTION    "DevSound",ROM0
endc

if	!def(UseCustomHooks)
DevSound_JumpTable:

DS_Init:			jp	DevSound_Init
DS_Play:			jp	DevSound_Play
DS_Stop:			jp	DevSound_Stop
DS_Fade:			jp	DevSound_Fade
DS_ExternalCommand:	jp	DevSound_ExternalCommand
endc

; Driver thumbprint
db	"DevSound GB music player by DevEd | email: deved8@gmail.com"

; ================================================================
; Init routine
; INPUT: a = ID of song to init
; ================================================================

DevSound_Init:
	di
	ld	b,a		; Preserve song ID
	
	xor	a
	ldh	[rNR52],a	; disable sound
	ld	[PWMEnabled],a
	ld	[RandomizerEnabled],a
	ld	[WaveBufUpdateFlag],a

	; init sound RAM area
	ld	de,InitVarsStart
	ld	c,DSVarsEnd-InitVarsStart
	ld	hl,DefaultRegTable
.initLoop
	ld	a,[hl+]
	ld	[de],a
	inc	de
	dec	c
	jr	nz,.initLoop
	
	ld	e,b		; Transfer song ID

	push	de
	; load default waveform
	ld	hl,DefaultWave
	call	LoadWave
	; clear buffers
	call	ClearWaveBuffer
	call	ClearArpBuffer
	call	ClearEchoBuffers
	pop	de
	; set up song pointers
	ld	hl,SongPointerTable
	ld	d,0
	add	hl,de
	add	hl,de
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
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
	ld	hl,DummyChannel
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[hl+]
	ld	[CH1RetPtr],a
	ld	[CH2RetPtr],a
	ld	[CH3RetPtr],a
	ld	[CH4RetPtr],a
	ld	a,[hl]
	ld	[CH1RetPtr+1],a
	ld	[CH2RetPtr+1],a
	ld	[CH3RetPtr+1],a
	ld	[CH4RetPtr+1],a
	ld	a,$11
	ld	[CH1Pan],a
	ld	[CH2Pan],a
	ld	[CH3Pan],a
	ld	[CH4Pan],a
	ld	a,15
	ld	[CH1ChanVol],a
	ld	[CH2ChanVol],a
	ld	[CH3ChanVol],a
	ld	[CH4ChanVol],a
	; get tempo
	ld	hl,SongSpeedTable
	add	hl,de
	add	hl,de
	ld	a,[hl+]
	dec	a
	ld	[GlobalSpeed1],a
	ld	a,[hl]
	dec	a
	ld	[GlobalSpeed2],a
	ld	a,%10000000
	ldh	[rNR52],a
	ld	a,$FF
	ldh	[rNR51],a
	ld	a,7
	ld	[GlobalVolume],a
	; if visualizer is enabled, init it too
if def(Visualizer)
if !def(DemoSceneMode) && !def(NoWaveVolumeScaling)
	CopyBytes	DefaultWave,VisualizerTempWave,16
endc
	call	VisualizerInit
endc
	reti

; ================================================================
; External command processing routine
; INPUT: a  = command ID
; 		 bc = parameters
; ================================================================

DevSound_ExternalCommand:	
	cp	(.commandTableEnd-.commandTable)/2
	ret	nc	; if command ID is out of bounds, exit
	ld	hl,.commandTable
	
	add	a
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	jp	hl
	
.commandTable
	dw	.dummy			; $00 - dummy
	dw	.setSpeed		; $01 - set speed
	dw	.muteChannel	; $02 - mute given sound channel (TODO)
.commandTableEnd

	
.setSpeed
	ld	a,b
	ld	[GlobalSpeed1],a
	ld	a,c
	ld	[GlobalSpeed2],a
;	ret
	
.muteChannel		; TODO
;	ld	a,c
;	and	3

.dummy
	ret
	
; ================================================================
; Stop routine
; ================================================================

DevSound_Stop:
	ld	c,low(rNR52)
	xor	a
	ld	[c],a	; disable sound output (resets all sound regs)
	set	7,a
	ld	[c],a	; enable sound output
	dec	c
	or	$ff
	ld	[c],a	; all sound channels to left+right speakers
	dec	c
	and	$77
	ld	[c],a	; VIN output off + master volume max
	xor	a
	ld	[CH1Enabled],a
	ld	[CH2Enabled],a
	ld	[CH3Enabled],a
	ld	[CH4Enabled],a
	ld	[SoundEnabled],a
	; if visualizer is enabled, init it too (to make everything zero)
if def(Visualizer)
	jp	VisualizerInit
else
	ret
endc

; ================================================================
; Fade routine
; Note: if planning to call both this and DS_Init, call this first.
; ================================================================

DevSound_Fade:
	and	3
	cp	3
	ret	z 	; 3 is an invalid value, silently ignore it
	inc	a 	; Increment...
	set	2,a ; Mark this fade as the first
	ld	[FadeType],a
	ld	a,7
	ld	[FadeTimer],a
	ret
	
; ================================================================
; Play routine
; ================================================================

DevSound_Play:
	; Since this routine is called during an interrupt (which may
	; happen in the middle of a routine), preserve all register
	; values just to be safe.
	; Other registers are saved at `.doUpdate`.
	push	af
	ld	a,[SoundEnabled]
	and	a
	jr	nz,.doUpdate		; if sound is enabled, jump ahead
	pop	af
	ret
	
.doUpdate
	push	bc
	push	de
	push	hl
	; do stuff with sync tick
	ld	a,[SyncTick]
	and	a
	jr	z,.getSongTimer
	dec	a
	ld	[SyncTick],a
.getSongTimer
	ld	a,[GlobalTimer]		; get global timer
	and	a					; is GlobalTimer non-zero?
	jr	nz,.noupdate		; if yes, don't update
	ld	a,[TickCount]		; get current tick count
	xor	1					; toggle between 0 and 1
	ld	[TickCount],a		; store it in RAM
	jr	nz,.odd				; if a is 1, jump
.even
	ld	a,[GlobalSpeed1]
	jr	.setTimer
.odd
	ld	a,[GlobalSpeed2]
.setTimer
	ld	[GlobalTimer],a		; store timer value
	jr	UpdateCH1			; continue ahead
	
.noupdate
	dec	a					; subtract 1 from timer
	ld	[GlobalTimer],a		; store timer value
	jp	DoneUpdating		; done

; ================================================================
	
UpdateCH1:
	ld	a,[CH1Enabled]
	and	a
	jp	z,UpdateCH2			; if channel is disabled, skip to UpdateCH2
	ld	a,[CH1Tick]
	and	a
	jr	z,.continue			; if channel tick = 0, then jump ahead
	dec	a					; otherwise...
	ld	[CH1Tick],a			; decrement channel tick...
	jp	UpdateCH2	; ...and do echo buffer.
.continue
	ld	hl,CH1Ptr			; get pointer
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
CH1_CheckByte:
	ld	a,[hl+]				; get byte
	cp	$ff					; if $ff...
	jp	z,.endChannel
	cp	$c9					; if $c9...
	jp	z,.retSection
	cp	release				; if release
	jp	z,.release
	cp	___					; if null note...
	jp	z,.nullnote
	cp	echo				; if echo
	jp	z,.echo
	bit	7,a					; if command...
	jp	nz,.getCommand
	; if we have a note...
	ld	b,a
	xor	a
	ld	[CH1DoEcho],a
	ld	a,b
.getNote
	ld	[CH1NoteBackup],a	; set note	
	ld	b,a
	ld	a,[CH1NotePlayed]
	and	a
	jr	nz,.skipfill
	ld	a,b
	call	CH1FillEchoBuffer
.skipfill
	ld	a,[hl+]				; get note length
	dec	a					; subtract 1
	ld	[CH1Tick],a			; set channel tick
	ld	a,l					; store back current pos
	ld	[CH1Ptr],a
	ld	a,h
	ld	[CH1Ptr+1],a
	ld	a,[CH1PortaType]
	dec	a					; if toneporta, don't reset everything
	jr	z,.noreset
	xor	a
	ld	[CH1ArpPos],a		; reset arp position
	inc	a
	ld	[CH1VibPos],a		; reset vibrato position
	ld	hl,CH1VibPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[hl]				; get vibrato delay
	ld	[CH1VibDelay],a		; set delay
	xor	a
	ld	hl,CH1Reset
	bit	0,[hl]			
	jr	nz,.noreset_checkvol
	ld	[CH1PulsePos],a
.noreset_checkvol
	bit	1,[hl]
	jr	nz,.noreset
	ld	[CH1VolPos],a
	ld	[CH1VolLoop],a
.noreset
	ld	a,[CH1NoteCount]
	inc	a
	ld	[CH1NoteCount],a
	ld	b,a
	; check if instrument mode is 1 (alternating)
	ld	a,[CH1InsMode]
	and	a
	jr	z,.noInstrumentChange
	ld	a,b
	rra
	jr	nc,.notodd
	ld	a,[CH1Ins1]
	jr	.odd
.notodd
	ld	a,[CH1Ins2]
.odd
	call	CH1_SetInstrument
.noInstrumentChange
	ld	hl,CH1Reset
	set	7,[hl]			; signal the start of note for pitch bend
	jp	UpdateCH2
	
.endChannel
	xor	a
	ld	[CH1Enabled],a
	jp	UpdateCH2

.retSection
	ld	hl,CH1RetPtr
	ld	a,[hl+]
	ld	[CH1Ptr],a
	ld	a,[hl]
	ld	[CH1Ptr+1],a
	jp	UpdateCH1
	
.nullnote
	xor	a
	ld	[CH1DoEcho],a
	ld	a,[hl+]
	dec	a
	ld	[CH1Tick],a		; set tick
	ld	a,l				; store back current pos
	ld	[CH1Ptr],a
	ld	a,h
	ld	[CH1Ptr+1],a
	jp	UpdateCH2
	
.release
	; follows FamiTracker's behavior except only the volume table will be affected
	xor	a
	ld	[CH1DoEcho],a
	ld	a,[hl+]
	dec	a
	ld	[CH1Tick],a		; set tick
	ld	a,l				; store back current pos
	ld	[CH1Ptr],a
	ld	a,h
	ld	[CH1Ptr+1],a
	ld	hl,CH1VolPos
	inc	[hl]
	jp	UpdateCH2
	
.echo
	ld	b,a
	ld	a,1
	ld	[CH1DoEcho],a
	ld	a,b
	jp	.getNote
	
.getCommand
	ld	b,a
	xor	a
	ld	[CH1DoEcho],a
	ld	a,b
	cp	DummyCommand
	jp	nc, CH1_CheckByte
	; Not needed because function performs "add a" which discards bit 7
	; sub	$80	; subtract 128 from command value
	call	JumpTableBelow
	
	dw	.setInstrument
	dw	.setLoopPoint
	dw	.gotoLoopPoint
	dw	.callSection
	dw	.setChannelPtr
	dw	.pitchBendUp
	dw	.pitchBendDown
	dw	.setSweep
	dw	.setPan
	dw	.setSpeed
	dw	.setInsAlternate
	dw	CH1_CheckByte	;.randomizeWave
	dw	.combineWaves
	dw	.enablePWM
	dw	.enableRandomizer
	dw	CH1_CheckByte	;.disableAutoWave
	dw	.arp
	dw	.toneporta
	dw	.chanvol
	dw	.setSyncTick
	dw	.setEchoDelay
	dw	.setRepeatPoint
	dw	.repeatSection

.setInstrument
	ld	a,[hl+]					; get ID of instrument to switch to
	push	hl					; preserve HL
	call	CH1_SetInstrument
	xor	a
	ld	[CH1InsMode],a			; reset instrument mode
	pop	hl						; restore HL
	jp	CH1_CheckByte
	
.setLoopPoint
	ld	a,l
	ld	[CH1LoopPtr],a
	ld	a,h
	ld	[CH1LoopPtr+1],a
	jp	CH1_CheckByte
	
.gotoLoopPoint
	ld	hl,CH1LoopPtr			; get loop pointer
	ld	a,[hl+]
	ld	[CH1Ptr],a
	ld	a,[hl]
	ld	[CH1Ptr+1],a
	jp	UpdateCH1

.callSection
	ld	a,[hl+]
	ld	[CH1Ptr],a
	ld	a,[hl+]
	ld	[CH1Ptr+1],a
	ld	a,l
	ld	[CH1RetPtr],a
	ld	a,h
	ld	[CH1RetPtr+1],a
	jp	UpdateCH1
	
.setChannelPtr
	ld	a,[hl+]
	ld	[CH1Ptr],a
	ld	a,[hl]
	ld	[CH1Ptr+1],a
	jp	UpdateCH1

.pitchBendUp
	ld	a,[hl+]
	ld	[CH1PortaSpeed],a
	and	a
	jr	z,.loadPortaType
	ld	a,2
	jr	.loadPortaType
	
.pitchBendDown
	ld	a,[hl+]
	ld	[CH1PortaSpeed],a
	and	a
	jr	z,.loadPortaType
	ld	a,3
	jr	.loadPortaType
	
.toneporta
	ld	a,[hl+]
	ld	[CH1PortaSpeed],a
	and	a
	jr	z,.loadPortaType
	ld	a,1
.loadPortaType
	ld	[CH1PortaType],a
	jp	CH1_CheckByte

.setSweep
	ld	a,[hl+]
	ld	[CH1Sweep],a
	jp	CH1_CheckByte

.setPan
	ld	a,[hl+]
	ld	[CH1Pan],a
	jp	CH1_CheckByte

.setSpeed
	ld	a,[hl+]
	dec	a
	ld	[GlobalSpeed1],a
	ld	a,[hl+]
	dec	a
	ld	[GlobalSpeed2],a
	jp	CH1_CheckByte
	
.setInsAlternate
	ld	a,[hl+]
	ld	[CH1Ins1],a
	ld	a,[hl+]
	ld	[CH1Ins2],a
	ld	a,1
	ld	[CH1InsMode],a
	jp	CH1_CheckByte
	
.combineWaves
	ld	a,l
	add	4
	ld	l,a
	jp	nc,CH1_CheckByte
	inc	h
	jp	CH1_CheckByte	
	
.enablePWM
	inc	hl
	inc	hl
	jp	CH1_CheckByte
	
.setSyncTick
	ld	a,[hl+]
	ld	[SyncTick],a
	jp	CH1_CheckByte
	
.enableRandomizer
	inc	hl
	jp	CH1_CheckByte
	
.arp
	call	DoArp
	jp	CH1_CheckByte

.chanvol
	ld	a,[hl+]
	and	$f
	ld	[CH1ChanVol],a
	jp	CH1_CheckByte
	
.setEchoDelay
	ld	a,[hl+]
	and	$3f
	ld	[CH1EchoDelay],a
	jp	CH1_CheckByte
	
.setRepeatPoint
	ld	a,l
	ld	[CH1RepeatPtr],a
	ld	a,h
	ld	[CH1RepeatPtr+1],a
	jp	CH1_CheckByte
	
.repeatSection
	ld	a,[CH1RepeatCount]
	and	a	; section currently repeating?
	jr	z,.notrepeating
	dec	a
	ld	[CH1RepeatCount],a
	and	a
	jr	z,.stoprepeating
	inc	hl
	jr	.dorepeat
.notrepeating
	ld	a,[hl+]
	dec	a
	ld	[CH1RepeatCount],a
	ld	a,1
	ld	[CH1DoRepeat],a
.dorepeat
	ld	hl,CH1RepeatPtr			; get loop pointer
	ld	a,[hl+]
	ld	[CH1Ptr],a
	ld	a,[hl]
	ld	[CH1Ptr+1],a
	jp	UpdateCH1
.stoprepeating
	xor	a
	ld	[CH1DoRepeat],a
.norepeat
	inc	hl
	jp	CH1_CheckByte
	
CH1_SetInstrument:
	ld	hl,InstrumentTable
	ld	e,a
	ld	d,0
	add	hl,de
	add	hl,de
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	; no reset flag
	ld	a,[hl+]
	and	3
	ld	[CH1Reset],a
	ld	b,a
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
	ld	hl,CH1VibPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[hl]
	ld	[CH1VibDelay],a
	ret
	
; ================================================================
	
UpdateCH2:
	ld	a,[CH2Enabled]
	and	a
	jp	z,UpdateCH3
	ld	a,[CH2Tick]
	and	a
	jr	z,.continue
	dec	a
	ld	[CH2Tick],a
	jp	UpdateCH3
.continue
	ld	hl,CH2Ptr	; get pointer
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
CH2_CheckByte:
	ld	a,[hl+]		; get byte
	cp	$ff
	jp	z,.endChannel
	cp	$c9
	jp	z,.retSection
	cp	release				; if release
	jp	z,.release
	cp	___
	jp	z,.nullnote
	cp	echo
	jp	z,.echo
	bit	7,a			; check for command
	jp	nz,.getCommand	
	; if we have a note...
	ld	b,a
	xor	a
	ld	[CH2DoEcho],a
	ld	a,b
.getNote
	ld	[CH2NoteBackup],a
	ld	b,a
	ld	a,[CH2NotePlayed]
	and	a
	jr	nz,.skipfill
	ld	a,b
	call	CH2FillEchoBuffer
.skipfill
	ld	a,[hl+]
	dec	a
	ld	[CH2Tick],a
	ld	a,l				; store back current pos
	ld	[CH2Ptr],a
	ld	a,h
	ld	[CH2Ptr+1],a
	ld	a,[CH2PortaType]
	dec	a				; if toneporta, don't reset everything
	jr	z,.noreset
	xor	a
	ld	[CH2ArpPos],a
	if(UseFXHammer)
	ld	a,[FXHammer_SFXCH2]
	cp	3
	jp	z,.noupdate
	endc
	ldh	[rNR22],a
.noupdate
	inc	a
	ld	[CH2VibPos],a
	ld	hl,CH2VibPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[hl]
	ld	[CH2VibDelay],a
	xor	a
	ld	hl,CH2Reset
	bit	0,[hl]
	jr	nz,.noreset_checkvol
	ld	[CH2PulsePos],a
.noreset_checkvol
	bit	1,[hl]
	jr	nz,.noreset
	ld	[CH2VolPos],a
	ld	[CH2VolLoop],a
.noreset
	ld	a,[CH2NoteCount]
	inc	a
	ld	[CH2NoteCount],a
	ld	b,a
	; check if instrument mode is 1 (alternating)
	ld	a,[CH2InsMode]
	and	a
	jr	z,.noInstrumentChange
	ld	a,b
	rra
	jr	nc,.notodd
	ld	a,[CH2Ins1]
	jr	.odd
.notodd
	ld	a,[CH2Ins2]
.odd
	call	CH2_SetInstrument
.noInstrumentChange
	ld	hl,CH2Reset
	set	7,[hl]
	jp	UpdateCH3
	
.endChannel
	xor	a
	ld	[CH2Enabled],a
	jp	UpdateCH3
	
.retSection
	ld	hl,CH2RetPtr
	ld	a,[hl+]
	ld	[CH2Ptr],a
	ld	a,[hl]
	ld	[CH2Ptr+1],a
	jp	UpdateCH2
	
.nullnote
	xor	a
	ld	[CH2DoEcho],a
	ld	a,[hl+]
	dec	a
	ld	[CH2Tick],a		; set tick
	ld	a,l				; store back current pos
	ld	[CH2Ptr],a
	ld	a,h
	ld	[CH2Ptr+1],a
	jp	UpdateCH3
	
.release
	; follows FamiTracker's behavior except only the volume table will be affected
	xor	a
	ld	[CH2DoEcho],a
	ld	a,[hl+]
	dec	a
	ld	[CH2Tick],a		; set tick
	ld	a,l				; store back current pos
	ld	[CH2Ptr],a
	ld	a,h
	ld	[CH2Ptr+1],a
	ld	hl,CH2VolPos
	inc	[hl]
	jp	UpdateCH3
	
.echo
	ld	b,a
	ld	a,1
	ld	[CH2DoEcho],a
	ld	a,b
	jp	.getNote
	
.getCommand
	ld	b,a
	xor	a
	ld	[CH2DoEcho],a
	ld	a,b
	cp	DummyCommand
	jp	nc,CH2_CheckByte
	; Not needed because function performs "add a" which discards bit 7
	; sub	$80
	call	JumpTableBelow
	
	dw	.setInstrument
	dw	.setLoopPoint
	dw	.gotoLoopPoint
	dw	.callSection
	dw	.setChannelPtr
	dw	.pitchBendUp
	dw	.pitchBendDown
	dw	.setSweep
	dw	.setPan
	dw	.setSpeed
	dw	.setInsAlternate
	dw	CH2_CheckByte	;.randomizeWave
	dw	.combineWaves
	dw	.enablePWM
	dw	.enableRandomizer
	dw	CH2_CheckByte	;.disableAutoWave
	dw	.arp
	dw	.toneporta
	dw	.chanvol
	dw	.setSyncTick
	dw	.setEchoDelay
	dw	.setRepeatPoint
	dw	.repeatSection

.setInstrument
	ld	a,[hl+]
	push	hl
	call	CH2_SetInstrument
	pop	hl
	xor	a
	ld	[CH2InsMode],a
	jp	CH2_CheckByte
	
.setLoopPoint
	ld	a,l
	ld	[CH2LoopPtr],a
	ld	a,h
	ld	[CH2LoopPtr+1],a
	jp	CH2_CheckByte
	
.gotoLoopPoint
	ld	hl,CH2LoopPtr
	ld	a,[hl+]
	ld	[CH2Ptr],a
	ld	a,[hl]
	ld	[CH2Ptr+1],a
	jp	UpdateCH2
	
.callSection
	ld	a,[hl+]
	ld	[CH2Ptr],a
	ld	a,[hl+]
	ld	[CH2Ptr+1],a
	ld	a,l
	ld	[CH2RetPtr],a
	ld	a,h
	ld	[CH2RetPtr+1],a
	jp	UpdateCH2
	
.setChannelPtr
	ld	a,[hl+]
	ld	[CH2Ptr],a
	ld	a,[hl]
	ld	[CH2Ptr+1],a
	jp	UpdateCH2

.pitchBendUp
	ld	a,[hl+]
	ld	[CH2PortaSpeed],a
	and	a
	jr	z,.loadPortaType
	ld	a,2
	jr	.loadPortaType
	
.pitchBendDown
	ld	a,[hl+]
	ld	[CH2PortaSpeed],a
	and	a
	jr	z,.loadPortaType
	ld	a,3
	jr	.loadPortaType
	
.toneporta
	ld	a,[hl+]
	ld	[CH2PortaSpeed],a
	and	a
	jr	z,.loadPortaType
	ld	a,1
.loadPortaType
	ld	[CH2PortaType],a
	jp	CH2_CheckByte

.setSweep
.enableRandomizer
	inc	hl
	jp	CH2_CheckByte

.setPan
	ld	a,[hl+]
	ld	[CH2Pan],a
	jp	CH2_CheckByte

.setSpeed
	ld	a,[hl+]
	dec	a
	ld	[GlobalSpeed1],a
	ld	a,[hl+]
	dec	a
	ld	[GlobalSpeed2],a
	jp	CH2_CheckByte

.setInsAlternate
	ld	a,[hl+]
	ld	[CH2Ins1],a
	ld	a,[hl+]
	ld	[CH2Ins2],a
	ld	a,1
	ld	[CH2InsMode],a
	jp	CH2_CheckByte
	
.combineWaves
	ld	a,l
	add	4
	ld	l,a
	jp	nc,CH2_CheckByte
	inc	h
	jp	CH2_CheckByte	
	
.enablePWM
	inc	hl
	inc	hl
	jp	CH2_CheckByte
	
.arp
	call	DoArp
	jp	CH2_CheckByte

.chanvol
	ld	a,[hl+]
	and	$f
	ld	[CH2ChanVol],a
	jp	CH2_CheckByte
	
.setSyncTick
	ld	a,[hl+]
	ld	[SyncTick],a
	jp	CH2_CheckByte
	
.setEchoDelay
	ld	a,[hl+]
	and	$3f
	ld	[CH2EchoDelay],a
	jp	CH2_CheckByte
	
.setRepeatPoint
	ld	a,l
	ld	[CH2RepeatPtr],a
	ld	a,h
	ld	[CH2RepeatPtr+1],a
	jp	CH2_CheckByte
	
.repeatSection
	ld	a,[CH2RepeatCount]
	and	a	; section currently repeating?
	jr	z,.notrepeating
	dec	a
	ld	[CH2RepeatCount],a
	and	a
	jr	z,.stoprepeating
	inc	hl
	jr	.dorepeat
.notrepeating
	ld	a,[hl+]
	dec	a
	ld	[CH2RepeatCount],a
	ld	a,1
	ld	[CH2DoRepeat],a
.dorepeat
	ld	hl,CH2RepeatPtr			; get loop pointer
	ld	a,[hl+]
	ld	[CH2Ptr],a
	ld	a,[hl]
	ld	[CH2Ptr+1],a
	jp	UpdateCH2
.stoprepeating
	xor	a
	ld	[CH2DoRepeat],a
.norepeat
	inc	hl
	jp	CH2_CheckByte
	
CH2_SetInstrument:
	ld	hl,InstrumentTable
	ld	e,a
	ld	d,0
	add	hl,de
	add	hl,de
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	; no reset flag
	ld	a,[hl+]
	and	3
	ld	[CH2Reset],a
	ld	b,a
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
	ld	hl,CH2VibPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[hl]
	ld	[CH2VibDelay],a
	ret
	
; ================================================================
	
UpdateCH3:
	ld	a,[CH3Enabled]
	and	a
	jp	z,UpdateCH4
	ld	a,[CH3Tick]
	and	a
	jr	z,.continue
	dec	a
	ld	[CH3Tick],a
	jp	UpdateCH4
.continue
	ld	hl,CH3Ptr	; get pointer
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
CH3_CheckByte:
	ld	a,[hl+]		; get byte
	cp	$ff
	jp	z,.endChannel
	cp	$c9
	jp	z,.retSection
	cp	release				; if release
	jp	z,.release
	cp	___
	jp	z,.nullnote
	cp	echo
	jp	z,.echo
	bit	7,a			; check for command
	jp	nz,.getCommand
	; if we have a note...
	ld	b,a
	xor	a
	ld	[CH1DoEcho],a
	ld	a,b
.getNote
	ld	[CH3NoteBackup],a
	ld	b,a
	ld	a,[CH3NotePlayed]
	and	a
	jr	nz,.skipfill
	ld	a,b
	call	CH3FillEchoBuffer
.skipfill
	ld	a,[hl+]
	dec	a
	ld	[CH3Tick],a
	ld	a,l				; store back current pos
	ld	[CH3Ptr],a
	ld	a,h
	ld	[CH3Ptr+1],a
	ld	a,[CH3PortaType]
	dec	a				; if toneporta, don't reset everything
	jr	z,.noresetvol
	xor	a
	ld	[CH3ArpPos],a
	cpl
	ld	[CH3Wave],a		; workaround for wave corruption bug on DMG, forces wave update at note start
	ld	a,1
	ld	[CH3VibPos],a
	ld	hl,CH3VibPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[hl]
	ld	[CH3VibDelay],a
	xor	a
	ld	hl,CH3Reset
	bit	0,[hl]
	jr	nz,.noresetwave
	ld	[CH3WavePos],a
.noresetwave
	bit	1,[hl]
	jr	nz,.noresetvol
	ld	[CH3VolPos],a
.noresetvol
	ld	a,[CH3NoteCount]
	inc	a
	ld	[CH3NoteCount],a
	ld	b,a
	ld	a,[CH3ComputedVol]
	ldh	[rNR32],a	; fix for volume not updating when unpausing
	
	; check if instrument mode is 1 (alternating)
	ld	a,[CH3InsMode]
	and	a
	jr	z,.noInstrumentChange
	ld	a,b
	rra
	jr	nc,.notodd
	ld	a,[CH3Ins1]
	jr	.odd
.notodd
	ld	a,[CH3Ins2]
.odd
	call	CH3_SetInstrument
.noInstrumentChange
	ld	hl,CH3Reset
	set	7,[hl]
	jp	UpdateCH4
	
.endChannel
	xor	a
	ld	[CH3Enabled],a
	jp	UpdateCH4
	
.retSection
	ld	hl,CH3RetPtr
	ld	a,[hl+]
	ld	[CH3Ptr],a
	ld	a,[hl]
	ld	[CH3Ptr+1],a
	jp	UpdateCH3
	
.nullnote
	ld	b,a
	xor	a
	ld	[CH1DoEcho],a
	ld	a,b
	ld	a,[hl+]
	dec	a
	ld	[CH3Tick],a
	ld	a,l				; store back current pos
	ld	[CH3Ptr],a
	ld	a,h
	ld	[CH3Ptr+1],a
	jp	UpdateCH4
	
.release
	; follows FamiTracker's behavior except only the volume table will be affected
	ld	b,a
	xor	a
	ld	[CH1DoEcho],a
	ld	a,b
	ld	a,[hl+]
	dec	a
	ld	[CH3Tick],a		; set tick
	ld	a,l				; store back current pos
	ld	[CH3Ptr],a
	ld	a,h
	ld	[CH3Ptr+1],a
	ld	hl,CH3VolPos
	inc	[hl]
	jp	UpdateCH4

.echo
	ld	b,a
	ld	a,1
	ld	[CH3DoEcho],a
	ld	a,b
	jp	.getNote
	
.getCommand
	cp	DummyCommand
	jp	nc,CH3_CheckByte
	; Not needed because function performs "add a" which discards bit 7
	; sub	$80
	call	JumpTableBelow
	
	dw	.setInstrument
	dw	.setLoopPoint
	dw	.gotoLoopPoint
	dw	.callSection
	dw	.setChannelPtr
	dw	.pitchBendUp
	dw	.pitchBendDown
	dw	.setSweep
	dw	.setPan
	dw	.setSpeed
	dw	.setInsAlternate
	dw	.randomizeWave
	dw	.combineWaves
	dw	.enablePWM
	dw	.enableRandomizer
	dw	.disableAutoWave
	dw	.arp
	dw	.toneporta
	dw	.chanvol
	dw	.setSyncTick
	dw	.setEchoDelay
	dw	.setRepeatPoint
	dw	.repeatSection

.setInstrument
	ld	a,[hl+]
	push	hl
	call	CH3_SetInstrument
	pop	hl
	xor	a
	ld	[CH3InsMode],a
	jp	CH3_CheckByte
	
.setLoopPoint
	ld	a,l
	ld	[CH3LoopPtr],a
	ld	a,h
	ld	[CH3LoopPtr+1],a
	jp	CH3_CheckByte
	
.gotoLoopPoint
	ld	hl,CH3LoopPtr
	ld	a,[hl+]
	ld	[CH3Ptr],a
	ld	a,[hl]
	ld	[CH3Ptr+1],a
	jp	UpdateCH3
	
.callSection
	ld	a,[hl+]
	ld	[CH3Ptr],a
	ld	a,[hl+]
	ld	[CH3Ptr+1],a
	ld	a,l
	ld	[CH3RetPtr],a
	ld	a,h
	ld	[CH3RetPtr+1],a
	jp	UpdateCH3
	
.setChannelPtr
	ld	a,[hl+]
	ld	[CH3Ptr],a
	ld	a,[hl]
	ld	[CH3Ptr+1],a
	jp	UpdateCH3

.pitchBendUp
	ld	a,[hl+]
	ld	[CH3PortaSpeed],a
	and	a
	jr	z,.loadPortaType
	ld	a,2
	jr	.loadPortaType
	
.pitchBendDown
	ld	a,[hl+]
	ld	[CH3PortaSpeed],a
	and	a
	jr	z,.loadPortaType
	ld	a,3
	jr	.loadPortaType
	
.toneporta
	ld	a,[hl+]
	ld	[CH3PortaSpeed],a
	and	a
	jr	z,.loadPortaType
	ld	a,1
.loadPortaType
	ld	[CH3PortaType],a
	jp	CH3_CheckByte

.setSweep
	inc	hl
	jp	CH3_CheckByte

.setPan
	ld	a,[hl+]
	ld	[CH3Pan],a
	jp	CH3_CheckByte

.setSpeed
	ld	a,[hl+]
	dec	a
	ld	[GlobalSpeed1],a
	ld	a,[hl+]
	dec	a
	ld	[GlobalSpeed2],a
	jp	CH3_CheckByte
	
.setInsAlternate
	ld	a,[hl+]
	ld	[CH3Ins1],a
	ld	a,[hl+]
	ld	[CH3Ins2],a
	ld	a,1
	ld	[CH3InsMode],a
	jp	CH3_CheckByte
	
if def(DemoSceneMode)
	
.randomizeWave
.disableAutoWave
	jp	CH3_CheckByte
	
.combineWaves
	ld	a,l
	add	4
	ld	l,a
	jp	nc,CH3_CheckByte
	inc	h
	jp	CH3_CheckByte	
	
.enablePWM
	inc	hl
	inc	hl
	jp	CH3_CheckByte
	
.enableRandomizer
	inc	hl
	jp	CH3_CheckByte
	
else
	
.randomizeWave
	push	hl
	call	_RandomizeWave
	pop	hl
	jp	CH3_CheckByte

.combineWaves
	push	bc
	ld	a,[hl+]
	ld	c,a
	ld	a,[hl+]
	ld	b,a
	ld	a,[hl+]
	ld	e,a
	ld	a,[hl+]
	ld	d,a
	push	hl
	call	_CombineWaves
	pop	hl
	pop	bc
	jp	CH3_CheckByte
	
.enablePWM
	push	hl
	call	ClearWaveBuffer
	pop	hl
	ld	a,[hl+]
	ld	[PWMVol],a
	ld	a,[hl+]
	ld	[PWMSpeed],a
	ld	a,$ff
	ld	[WavePos],a
	xor	a
	ld	[PWMDir],a
	ld	[RandomizerEnabled],a
	inc	a
	ld	[PWMEnabled],a
	ld	[PWMTimer],a
	jp	CH3_CheckByte
	
.enableRandomizer
	push	hl
	call	ClearWaveBuffer
	pop	hl
	ld	a,[hl+]
	ld	[RandomizerSpeed],a
	ld	a,1
	ld	[RandomizerTimer],a
	ld	[RandomizerEnabled],a
	xor	a
	ld	[PWMEnabled],a
	jp	CH3_CheckByte
	
.disableAutoWave
	xor	a
	ld	[PWMEnabled],a
	ld	[RandomizerEnabled],a
	jp	CH3_CheckByte
	
endc
	
.arp
	call	DoArp
	jp	CH3_CheckByte

.chanvol
	ld	a,[hl+]
	and	$f
	ld	[CH3ChanVol],a
	jp	CH3_CheckByte
	
.setSyncTick
	ld	a,[hl+]
	ld	[SyncTick],a
	jp	CH3_CheckByte
	
.setEchoDelay
	ld	a,[hl+]
	and	$3f
	ld	[CH3EchoDelay],a
	jp	CH3_CheckByte
	
.setRepeatPoint
	ld	a,l
	ld	[CH3RepeatPtr],a
	ld	a,h
	ld	[CH3RepeatPtr+1],a
	jp	CH3_CheckByte
	
.repeatSection
	ld	a,[CH3RepeatCount]
	and	a	; section currently repeating?
	jr	z,.notrepeating
	dec	a
	ld	[CH3RepeatCount],a
	and	a
	jr	z,.stoprepeating
	inc	hl
	jr	.dorepeat
.notrepeating
	ld	a,[hl+]
	dec	a
	ld	[CH3RepeatCount],a
	ld	a,1
	ld	[CH3DoRepeat],a
.dorepeat
	ld	hl,CH3RepeatPtr			; get loop pointer
	ld	a,[hl+]
	ld	[CH3Ptr],a
	ld	a,[hl]
	ld	[CH3Ptr+1],a
	jp	UpdateCH3
.stoprepeating
	xor	a
	ld	[CH3DoRepeat],a
.norepeat
	inc	hl
	jp	CH3_CheckByte
	
CH3_SetInstrument:
	ld	hl,InstrumentTable
	ld	e,a
	ld	d,0
	add	hl,de
	add	hl,de
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	; no reset flag
	ld	a,[hl+]
	and	3
	ld	[CH3Reset],a
	ld	b,a
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
	; wave table
	ld	a,[hl+]
	ld	[CH3WavePtr],a
	ld	a,[hl+]
	ld	[CH3WavePtr+1],a
	; vib table
	ld	a,[hl+]
	ld	[CH3VibPtr],a
	ld	a,[hl+]
	ld	[CH3VibPtr+1],a
	ld	hl,CH3VibPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[hl]
	ld	[CH3VibDelay],a
	ret

; ================================================================

UpdateCH4:
	ld	a,[CH4Enabled]
	and	a
	jp	z,DoneUpdating
	ld	a,[CH4Tick]
	and	a
	jr	z,.continue
	dec	a
	ld	[CH4Tick],a
	jp	DoneUpdating
.continue
	ld	hl,CH4Ptr	; get pointer
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
CH4_CheckByte:
	ld	a,[hl+]		; get byte
	cp	$ff
	jr	z,.endChannel
	cp	$c9
	jr	z,.retSection
	cp	release				; if release
	jr	z,.release
	cp	___
	jr	z,.nullnote
	cp	echo
	jr	z,.nullnote			; echo not applicable for ch4
	bit	7,a			; check for command
	jp	nz,.getCommand	
	; if we have a note...
.getNote
	ld	[CH4ModeBackup],a
	ld	a,[hl+]
	dec	a
	ld	[CH4Tick],a
	ld	a,l				; store back current pos
	ld	[CH4Ptr],a
	ld	a,h
	ld	[CH4Ptr+1],a
	xor	a
	ld	[CH4NoisePos],a
if !def(DisableDeflehacks)
	ld	[CH4WavePos],a
endc
	ld	a,[CH4Reset]
	bit	1,a
	jr	nz,.noresetvol
	xor	a
	ld	[CH4VolPos],a
	ld	[CH4VolLoop],a
.noresetvol
	if(UseFXHammer)
	ld	a,[FXHammer_SFXCH4]
	cp	3
	jp	z,.noupdate
	endc
	ldh	[rNR42],a
.noupdate
	ld	a,[CH4NoteCount]
	inc	a
	ld	[CH4NoteCount],a
	ld	b,a
	; check if instrument mode is 1 (alternating)
	ld	a,[CH4InsMode]
	and	a
	jr	z,.noInstrumentChange
	ld	a,b
	rra
	jr	nc,.notodd
	ld	a,[CH4Ins1]
	jr	.odd
.notodd
	ld	a,[CH4Ins2]
.odd
	call	CH4_SetInstrument
.noInstrumentChange
	jp	DoneUpdating
	
.endChannel
	xor	a
	ld	[CH4Enabled],a
	jp	DoneUpdating
	
.retSection
	ld	hl,CH4RetPtr
	ld	a,[hl+]
	ld	[CH4Ptr],a
	ld	a,[hl]
	ld	[CH4Ptr+1],a
	jp	UpdateCH4
	
.nullnote
	ld	a,[hl+]
	dec	a
	ld	[CH4Tick],a
	ld	a,l				; store back current pos
	ld	[CH4Ptr],a
	ld	a,h
	ld	[CH4Ptr+1],a
	jp	DoneUpdating
	
.release
	; follows FamiTracker's behavior except only the volume table will be affected
	ld	a,[hl+]
	dec	a
	ld	[CH4Tick],a		; set tick
	ld	a,l				; store back current pos
	ld	[CH4Ptr],a
	ld	a,h
	ld	[CH4Ptr+1],a
	ld	hl,CH4VolPos
	inc	[hl]
	jp	DoneUpdating
	
.getCommand
	cp	DummyCommand
	jp	nc,CH4_CheckByte
	; Not needed because function performs "add a" which discards bit 7
	; sub	$80
	call	JumpTableBelow
	
	dw	.setInstrument
	dw	.setLoopPoint
	dw	.gotoLoopPoint
	dw	.callSection
	dw	.setChannelPtr
	dw	.pitchBendUp
	dw	.pitchBendDown
	dw	.setSweep
	dw	.setPan
	dw	.setSpeed
	dw	.setInsAlternate
	dw	CH4_CheckByte	;.randomizeWave
	dw	.combineWaves
	dw	.enablePWM
	dw	.enableRandomizer
	dw	CH4_CheckByte	;.disableAutoWave
	dw	.arp
	dw	.toneporta
	dw	.chanvol
	dw	.setSyncTick
	dw	.setEchoDelay
	dw	.setRepeatPoint
	dw	.repeatSection
		
.setInstrument
	ld	a,[hl+]
	push	hl
	call	CH4_SetInstrument
	pop	hl
	xor	a
	ld	[CH4InsMode],a
	jp	CH4_CheckByte
	
.setLoopPoint
	ld	a,l
	ld	[CH4LoopPtr],a
	ld	a,h
	ld	[CH4LoopPtr+1],a
	jp	CH4_CheckByte
	
.gotoLoopPoint
	ld	hl,CH4LoopPtr
	ld	a,[hl+]
	ld	[CH4Ptr],a
	ld	a,[hl]
	ld	[CH4Ptr+1],a
	jp	UpdateCH4
	
.callSection
	ld	a,[hl+]
	ld	[CH4Ptr],a
	ld	a,[hl+]
	ld	[CH4Ptr+1],a
	ld	a,l
	ld	[CH4RetPtr],a
	ld	a,h
	ld	[CH4RetPtr+1],a
	jp	UpdateCH4
	
.setChannelPtr
	ld	a,[hl+]
	ld	[CH4Ptr],a
	ld	a,[hl]
	ld	[CH4Ptr+1],a
	jp	UpdateCH4

.pitchBendUp	; unused for ch4
.pitchBendDown	; unused for ch4
.setSweep		; unused for ch4
.enableRandomizer
.toneporta
	inc	hl
	jp	CH4_CheckByte

.setPan
	ld	a,[hl+]
	ld	[CH4Pan],a
	jp	CH4_CheckByte

.setSpeed
	ld	a,[hl+]
	dec	a
	ld	[GlobalSpeed1],a
	ld	a,[hl+]
	dec	a
	ld	[GlobalSpeed2],a
	jp	CH4_CheckByte
	
.setInsAlternate
	ld	a,[hl+]
	ld	[CH4Ins1],a
	ld	a,[hl+]
	ld	[CH4Ins2],a
	ld	a,1
	ld	[CH4InsMode],a
	jp	CH4_CheckByte
	
.combineWaves
	ld	a,l
	add	4
	ld	l,a
	jp	nc,CH4_CheckByte
	inc	h
	jp	CH4_CheckByte	
	
.enablePWM
.arp
	pop	hl
	inc	hl
	inc	hl
	jp	CH4_CheckByte

.chanvol
	ld	a,[hl+]
	and	$f
	ld	[CH4ChanVol],a
	jp	CH4_CheckByte
	
.setSyncTick
	ld	a,[hl+]
	ld	[SyncTick],a
	jp	CH4_CheckByte
	
.setEchoDelay
	inc	hl
	jp	CH4_CheckByte
	
.setRepeatPoint
	ld	a,l
	ld	[CH4RepeatPtr],a
	ld	a,h
	ld	[CH4RepeatPtr+1],a
	jp	CH4_CheckByte
	
.repeatSection
	ld	a,[CH4RepeatCount]
	and	a	; section currently repeating?
	jr	z,.notrepeating
	dec	a
	ld	[CH4RepeatCount],a
	and	a
	jr	z,.stoprepeating
	inc	hl
	jr	.dorepeat
.notrepeating
	ld	a,[hl+]
	dec	a
	ld	[CH4RepeatCount],a
	ld	a,1
	ld	[CH4DoRepeat],a
.dorepeat
	ld	hl,CH4RepeatPtr			; get loop pointer
	ld	a,[hl+]
	ld	[CH4Ptr],a
	ld	a,[hl]
	ld	[CH4Ptr+1],a
	jp	UpdateCH4
.stoprepeating
	xor	a
	ld	[CH4DoRepeat],a
.norepeat
	inc	hl
	jp	CH4_CheckByte

CH4_SetInstrument:
	ld	hl,InstrumentTable
	ld	e,a
	ld	d,0
	add	hl,de
	add	hl,de
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	; no reset flag
	ld	a,[hl+]
	and	3
	ld	[CH4Reset],a
	ld	b,a
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
if !def(DisableDeflehacks)
	ld	a,[hl+]
	ld	[CH4WavePtr],a
	ld	a,[hl+]
	ld	[CH4WavePtr+1],a
endc
	ret
	
; ================================================================

DoneUpdating:

UpdateRegisters:
	call	DoEchoBuffers

	; update panning
	xor	a
	ld	b,a
	ld	a,[CH1Pan]
	add	b
	ld	b,a
	ld	a,[CH2Pan]
	rla
	add	b
	ld	b,a
	ld	a,[CH3Pan]
	rla
	rla
	add	b
	ld	b,a
	ld	a,[CH4Pan]
	rla
	rla
	rla
	add	b
	ldh	[rNR51],a
	
	; update global volume + fade system
	ld	a,[FadeType]
	ld	b,a
	and	3 ; Check if no fade
	jr	z,.updateVolume ; Update volume
	
	bit	2,b ; Check if on first fade
	jr	z,.notfirstfade
	res	2,b
	ld	a,b
	ld	[FadeType],a
	dec	a
	dec	a ; If fading in (value 2), volume is 0 ; otherwise, it's 7
	jr	z,.gotfirstfadevolume
	ld	a,7
.gotfirstfadevolume
	ld	[GlobalVolume],a
.notfirstfade
	
	ld	a,[FadeTimer]
	and	a
	jr	z,.doupdate
	dec	a
	ld	[FadeTimer],a
	jr	.updateVolume
.doupdate
	ld	a,7
	ld	[FadeTimer],a
	ld	a,[FadeType]
	and 3
	dec	a
	jr	z,.fadeout
	dec	a
	jr	z,.fadein
	dec	a
	jr	nz,.updateVolume
.fadeoutstop
	ld	a,[GlobalVolume]
	and	a
	jr	z,.dostop
	dec	a
	ld	[GlobalVolume],a
	jr	.directlyUpdateVolume
.fadeout
	ld	a,[GlobalVolume]
	and	a
	jr	z,.directlyUpdateVolume
	dec	a
	ld	[GlobalVolume],a
	jr	.updateVolume
.fadein
	ld	a,[GlobalVolume]
	cp	7
	jr	z,.done
	inc	a
	ld	[GlobalVolume],a
	jr	.directlyUpdateVolume
.dostop
	call	DevSound_Stop
.done
	xor	a
	ld	[FadeType],a
.updateVolume
	ld	a,[GlobalVolume]
.directlyUpdateVolume ; Call when volume is already known
	and	7
	ld	b,a
	swap	a
	add	b
	ldh	[rNR50],a
	
CH1_UpdateRegisters:
	ld	a,[CH1Enabled]
	and	a
	jp	z,CH2_UpdateRegisters
	ld	a,[CH1NoteBackup]
	ld	[CH1Note],a
	cp	rest
	jr	nz,.norest
	ld	a,[CH1IsResting]
	and	a
	jp	nz,.done
	xor	a
	ldh	[rNR12],a
if def(Visualizer)
	ld	[CH1OutputLevel],a
	ld	[CH1TempEnvelope],a
endc
	ldh	a,[rNR14]
	or	%10000000
	ldh	[rNR14],a
	ld	a,1
	ld	[CH1IsResting],a
	jp	.done
.norest
	xor	a
	ld	[CH1IsResting],a
	jr	.updatearp
	
	; update arps
.updatearp
; Deflemask compatibility: if pitch bend is active, don't update arp and force the transpose of 0
if !def(DisableDeflehacks)
	ld	a,[CH1PortaType]
	and	a
	jr	z,.noskiparp
	xor	a
	ld	[CH1Transpose],a
	jr	.continue
endc
.noskiparp
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
	cp	$fe
	jr	nz,.noloop
	ld	a,[hl]
	ld	[CH1ArpPos],a
	jr	.updatearp
.noloop
	cp	$ff
	jr	z,.continue
	cp	$80
	jr	nc,.absolute
	sla	a
	sra	a
	jr	.donearp
.absolute
	and	$7f
	ld	[CH1Note],a
	xor	a
.donearp
	ld	[CH1Transpose],a
.noreset
	ld	a,[CH1ArpPos]
	inc	a
	ld	[CH1ArpPos],a
.continue
	
	; update sweep
	ld	a,[CH1Sweep]
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
	; convert pulse value
	and	3			; make sure value does not exceed 3
if def(Visualizer)
	ld	[CH1Pulse],a
endc
	rrca			; rotate right
	rrca			;   ""    ""
	ldh	[rNR11],a	; transfer to register
.noreset2
	ld	a,[CH1PulsePos]
	inc	a
	ld	[CH1PulsePos],a
	ld	a,[hl+]
	cp	$fe
	jr	nz,.updateNote
	ld	a,[hl]
	ld	[CH1PulsePos],a
	
; get note
.updateNote
	ld	a,[CH1DoEcho]
	and	a
	jr	z,.skipecho
	ld	a,[CH1EchoDelay]
	ld	b,a
	ld	a,[EchoPos]
	sub	b
	and	$3f
	ld	hl,CH1EchoBuffer
	add	l
	ld	l,a
	jr	nc,.nocarry3
	inc	h
.nocarry3
	ld	a,[hl]
	cp	$4a
	jr	nz,.getfrequency
	; TODO: Prevent null byte from being played
	jr	.getfrequency
.skipecho
	ld	a,[CH1PortaType]
	cp	2
	jr	c,.skippitchbend
	ld	a,[CH1Reset]
	bit	7,a
	jr	z,.pitchbend
.skippitchbend
	ld	a,[CH1Sweep]
	and	$70
	jr	z,.noskipsweep
	ld	a,[CH1Reset]
	bit	7,a
	jp	z,.updateVolume
.noskipsweep
	ld	a,[CH1Transpose]
	ld	b,a
	ld	a,[CH1Note]
	add	b
.getfrequency
	ld	c,a
	ld	b,0
	ld	hl,FreqTable
	add	hl,bc
	add	hl,bc
	ld	a,[hl+]
	ld	e,a
	ld	a,[hl]
	ld	d,a
	ld	a,[CH1PortaType]
	cp	2
	jr	c,.updateVibTable
	ld	a,e
	ld	[CH1TempFreq],a
	ld	a,d
	ld	[CH1TempFreq+1],a
	
.updateVibTable
	ld	a,[CH1VibDelay]
	and	a
	jr	z,.doVib
	dec	a
	ld	[CH1VibDelay],a
	jr	.setFreq
.doVib
	ld	hl,CH1VibPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH1VibPos]
	add	l
	ld	l,a
	jr	nc,.nocarry4
	inc	h
.nocarry4
	ld	a,[hl+]
	cp	$80
	jr	nz,.noloop2
	ld	a,[hl+]
	ld	[CH1VibPos],a
	jr	.doVib
.noloop2
	ld	[CH1FreqOffset],a
	ld	a,[CH1VibPos]
	inc	a
	ld	[CH1VibPos],a
	jr	.getPitchOffset
	
.pitchbend
	ld	a,[CH1PortaSpeed]
	ld	b,a
	ld	a,[CH1PortaType]
	and	1
	jr	nz,.sub2
	ld	a,[CH1TempFreq]
	add	b
	ld	e,a
	ld	a,[CH1TempFreq+1]
	jr	nc,.nocarry6
	inc	a
.nocarry6
	ld	d,a
	cp	8
	jr	c,.pitchbenddone
	ld	de,$7ff
	jr	.pitchbenddone
.sub2
	ld	a,[CH1TempFreq]
	sub	b
	ld	e,a
	ld	a,[CH1TempFreq+1]
	jr	nc,.nocarry7
	dec	a
.nocarry7
	ld	d,a
	cp	8
	jr	c,.pitchbenddone
	ld	de,0
.pitchbenddone
	ld	hl,CH1TempFreq
	ld	a,e
	ld	[hl+],a
	ld	[hl],d
	
.getPitchOffset
	ld	a,[CH1FreqOffset]
	bit	7,a
	jr	nz,.sub
	add	e
	ld	e,a
	jr	nc,.setFreq
	inc	d
	jr	.setFreq
.sub
	ld	c,a
	ld	a,e
	add	c
	ld	e,a
.setFreq
	ld	hl,CH1TempFreq
	ld	a,[CH1PortaType]
	and	a
	jr	z,.normal
	dec	a
	ld	a,e
	jr	nz,.donesetFreq

; toneporta
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH1PortaSpeed]
	ld	c,a
	ld	b,0
	ld	a,h
	cp	d
	jr	c,.lt
	jr	nz,.gt
	ld	a,l
	cp	e
	jr	z,.tonepordone
	jr	c,.lt
.gt
	ld	a,l
	sub	c
	ld	l,a
	jr	nc,.nocarry8
	dec	h
.nocarry8
	ld	a,h
	cp	d
	jr	c,.clamp
	jr	nz,.tonepordone
	ld	a,l
	cp	e
	jr	c,.clamp
	jr	.tonepordone
.lt
	add	hl,bc
	ld	a,h
	cp	d
	jr	c,.tonepordone
	jr	nz,.clamp
	ld	a,l
	cp	e
	jr	c,.tonepordone
.clamp
	ld	h,d
	ld	l,e
if def(Visualizer)
.tonepordone
	ld	a,l
	ld	[CH1TempFreq],a
	ld	[CH1ComputedFreq],a
	ldh	[rNR13],a
	ld	a,h
	ld	d,a	; for later restart uses
	ld	[CH1TempFreq+1],a
	ld	[CH1ComputedFreq+1],a
	ldh	[rNR14],a
	jr	.updateVolume
.normal
	ld	a,e
	ld	[hl+],a
	ld	[hl],d
.donesetFreq
	ld	[CH1ComputedFreq],a
	ldh	[rNR13],a
	ld	a,d
	ld	[CH1ComputedFreq+1],a
	ldh	[rNR14],a
else
.tonepordone
	ld	a,l
	ld	[CH1TempFreq],a
	ldh	[rNR13],a
	ld	a,h
	ld	d,a	; for later restart uses
	ld	[CH1TempFreq+1],a
	ldh	[rNR14],a
	jr	.updateVolume
.normal
	ld	a,e
	ld	[hl+],a
	ld	[hl],d
.donesetFreq
	ldh	[rNR13],a
	ld	a,d
	ldh	[rNR14],a
endc
	
	; update volume
.updateVolume
	ld	hl,CH1Reset
	res	7,[hl]
	ld	hl,CH1VolPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH1VolLoop]
	inc	a	; ended
	jp	z,.done
	ld	a,[CH1VolPos]
	add	l
	ld	l,a
	jr	nc,.nocarry5
	inc	h
.nocarry5
	ld	a,[hl+]
	cp	$ff
	jr	z,.loadlast
	cp	$fd
	jp	z,.done
	ld	b,a
if !def(DemoSceneMode) && !def(DisableZombieMode)
	ld	a,[CH1ChanVol]
	push	hl
	call	MultiplyVolume
	pop	hl
	ld	a,[CH1VolLoop]
	dec	a
	jr	z,.zombieatpos0
	ld	a,[CH1VolPos]
	and	a
	jr	z,.zombinit
.zombieatpos0
endc
	ld	a,[CH1Vol]
	cp	b
	jr	z,.noreset3
if !def(DemoSceneMode) && !def(DisableZombieMode)
	ld	c,a
	ld	a,b
	ld	[CH1Vol],a
if def(Visualizer)
	ld	[CH1OutputLevel],a
endc
	sub	c
	and	$f
	ld	c,a
	ld	a,8
.zombloop
	ldh	[rNR12],a
	dec	c
	jr	nz,.zombloop
	jr	.noreset3
.zombinit
endc
if def(Visualizer)
	ld	a,b
	ld	[CH1Vol],a
	ld	[CH1OutputLevel],a
	swap	a
	or	8
	ldh	[rNR12],a
	xor	a
	ld	[CH1TempEnvelope],a
	ld	a,d
	or	$80
	ldh	[rNR14],a
else
	ld	a,b
	ld	[CH1Vol],a
	swap	a
	or	8
	ldh	[rNR12],a
	ld	a,d
	or	$80
	ldh	[rNR14],a
endc
.noreset3
	ld	a,[CH1VolPos]
	inc	a
	ld	[CH1VolPos],a
	ld	a,[hl+]
	cp	$fe
	jr	nz,.done
	ld	a,[hl]
	ld	[CH1VolPos],a
if !def(DemoSceneMode) && !def(DisableZombieMode)
	ld	a,1
	ld	[CH1VolLoop],a
endc
	jr	.done
.loadlast
	ld	a,[hl]
if !def(DemoSceneMode) && !def(DisableZombieMode)
	push	af
	swap	a
	and	$f
	ld	b,a
	ld	a,[CH1ChanVol]
	call	MultiplyVolume
	swap	b
	pop	af
	and	$f
	or	b
endc
	ldh	[rNR12],a
if def(Visualizer)
	ld	b,a
	and	$f
	ld	[CH1TempEnvelope],a
	and	$7
	inc	a
	ld	[CH1EnvelopeCounter],a
	ld	a,b
	swap	a
	and	$f
	ld	[CH1OutputLevel],a
endc
	ld	a,d
	or	$80
	ldh	[rNR14],a
	ld	a,$ff
	ld	[CH1VolLoop],a
.done

; ================================================================

CH2_UpdateRegisters:
	ld	a,[CH2Enabled]
	and	a
	jp	z,CH3_UpdateRegisters
	
	if(UseFXHammer)
	ld	a,[FXHammer_SFXCH2]
	cp	3
	jr	z,.norest
	endc
	ld	a,[CH2NoteBackup]
	ld	[CH2Note],a
	cp	rest
	jr	nz,.norest
	ld	a,[CH2IsResting]
	and	a
	jp	nz,.done
	xor	a
	ldh	[rNR22],a
if def(Visualizer)
	ld	[CH2OutputLevel],a
	ld	[CH2TempEnvelope],a
endc
	ldh	a,[rNR24]
	or	%10000000
	ldh	[rNR24],a
	ld	a,1
	ld	[CH2IsResting],a
	jp	.done
.norest
	xor	a
	ld	[CH2IsResting],a


	; update arps
.updatearp
; Deflemask compatibility: if pitch bend is active, don't update arp and force the transpose of 0
if !def(DisableDeflehacks)
	ld	a,[CH2PortaType]
	and	a
	jr	z,.noskiparp
	xor	a
	ld	[CH2Transpose],a
	jr	.continue
endc
.noskiparp
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
	cp	$fe
	jr	nz,.noloop
	ld	a,[hl]
	ld	[CH2ArpPos],a
	jr	.updatearp
.noloop
	cp	$ff
	jr	z,.continue
	cp	$80
	jr	nc,.absolute
	sla	a
	sra	a
	jr	.donearp
.absolute
	and	$7f
	ld	[CH2Note],a
	xor	a
.donearp
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
	; convert pulse value
	and	3			; make sure value does not exceed 3
if def(Visualizer)
	ld	[CH2Pulse],a
endc
	rrca			; rotate right
	rrca			;   ""    ""
	if(UseFXHammer)
	ld	e,a
	ld	a,[FXHammer_SFXCH2]
	cp	3
	jp	z,.noreset2
	ld	a,e
	endc
	ldh	[rNR21],a	; transfer to register
.noreset2
	ld	a,[CH2PulsePos]
	inc	a
	ld	[CH2PulsePos],a
	ld	a,[hl+]
	cp	$fe
	jr	nz,.updateNote
	ld	a,[hl]
	ld	[CH2PulsePos],a

; get note
.updateNote
	ld	a,[CH2DoEcho]
	and	a
	jr	z,.skipecho
	ld	a,[CH2EchoDelay]
	ld	b,a
	ld	a,[EchoPos]
	sub	b
	and	$3f
	ld	hl,CH2EchoBuffer
	add	l
	ld	l,a
	jr	nc,.nocarry3
	inc	h
.nocarry3
	ld	a,[hl]
	cp	$4a
	jr	nz,.getfrequency
	; TODO: Prevent null byte from being played
	jr	.getfrequency
.skipecho
	ld	a,[CH2PortaType]
	cp	2
	jr	c,.skippitchbend
	ld	a,[CH2Reset]
	bit	7,a
	jr	z,.pitchbend
.skippitchbend
	ld	a,[CH2Transpose]
	ld	b,a
	ld	a,[CH2Note]
	add	b

.getfrequency
	ld	c,a
	ld	b,0
	ld	hl,FreqTable
	add	hl,bc
	add	hl,bc
	ld	a,[hl+]
	ld	e,a
	ld	a,[hl]
	ld	d,a
	ld	a,[CH2PortaType]
	cp	2
	jr	c,.updateVibTable
	ld	a,e
	ld	[CH2TempFreq],a
	ld	a,d
	ld	[CH2TempFreq+1],a
	
.updateVibTable
	ld	a,[CH2VibDelay]
	and	a
	jr	z,.doVib
	dec	a
	ld	[CH2VibDelay],a
	jr	.setFreq
.doVib
	ld	hl,CH2VibPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH2VibPos]
	add	l
	ld	l,a
	jr	nc,.nocarry4
	inc	h
.nocarry4
	ld	a,[hl+]
	cp	$80
	jr	nz,.noloop2
	ld	a,[hl+]
	ld	[CH2VibPos],a
	jr	.doVib
.noloop2
	ld	[CH2FreqOffset],a
	ld	a,[CH2VibPos]
	inc	a
	ld	[CH2VibPos],a
	jr	.getPitchOffset
	
.pitchbend
	ld	a,[CH2PortaSpeed]
	ld	b,a
	ld	a,[CH2PortaType]
	and	1
	jr	nz,.sub2
	ld	a,[CH2TempFreq]
	add	b
	ld	e,a
	ld	a,[CH2TempFreq+1]
	jr	nc,.nocarry6
	inc	a
.nocarry6
	ld	d,a
	cp	8
	jr	c,.pitchbenddone
	ld	de,$7ff
	jr	.pitchbenddone
.sub2
	ld	a,[CH2TempFreq]
	sub	b
	ld	e,a
	ld	a,[CH2TempFreq+1]
	jr	nc,.nocarry7
	dec	a
.nocarry7
	ld	d,a
	cp	8
	jr	c,.pitchbenddone
	ld	de,0
.pitchbenddone
	ld	hl,CH2TempFreq
	ld	a,e
	ld	[hl+],a
	ld	[hl],d
	
.getPitchOffset
	ld	a,[CH2FreqOffset]
	bit	7,a
	jr	nz,.sub
	add	e
	ld	e,a
	jr	nc,.setFreq
	inc	d
	jr	.setFreq
.sub
	ld	c,a
	ld	a,e
	add	c
	ld	e,a
.setFreq
	ld	hl,CH2TempFreq
	ld	a,[CH2PortaType]
	and	a
	jr	z,.normal
	dec	a
	ld	a,e
	jr	nz,.donesetFreq

; toneporta
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH2PortaSpeed]
	ld	c,a
	ld	b,0
	ld	a,h
	cp	d
	jr	c,.lt
	jr	nz,.gt
	ld	a,l
	cp	e
	jr	z,.tonepordone
	jr	c,.lt
.gt
	ld	a,l
	sub	c
	ld	l,a
	jr	nc,.nocarry8
	dec	h
.nocarry8
	ld	a,h
	cp	d
	jr	c,.clamp
	jr	nz,.tonepordone
	ld	a,l
	cp	e
	jr	c,.clamp
	jr	.tonepordone
.lt
	add	hl,bc
	ld	a,h
	cp	d
	jr	c,.tonepordone
	jr	nz,.clamp
	ld	a,l
	cp	e
	jr	c,.tonepordone
.clamp
	ld	h,d
	ld	l,e
.tonepordone
	if(UseFXHammer)
if def(Visualizer)
	ld	a,l
	ld	[CH2TempFreq],a
	ld	[CH2ComputedFreq],a
	ld	a,h
	ld	d,a	; for later restart uses
	ld	[CH2TempFreq+1],a
	ld	[CH2ComputedFreq+1],a
else
	ld	a,l
	ld	[CH2TempFreq],a
	ld	a,h
	ld	d,a	; for later restart uses
	ld	[CH2TempFreq+1],a
endc
	ld	a,[FXHammer_SFXCH2]
	cp	3
	jp	z,.updateVolume
	ld	a,l
	ldh	[rNR23],a
	ld	a,h
	ldh	[rNR24],a
	else
if def(Visualizer)
	ld	a,l
	ld	[CH2TempFreq],a
	ld	[CH2ComputedFreq],a
	ldh	[rNR23],a
	ld	a,h
	ld	d,a	; for later restart uses
	ld	[CH2TempFreq+1],a
	ld	[CH2ComputedFreq+1],a
	ldh	[rNR24],a
else
	ld	a,l
	ld	[CH2TempFreq],a
	ldh	[rNR23],a
	ld	a,h
	ld	d,a	; for later restart uses
	ld	[CH2TempFreq+1],a
	ldh	[rNR24],a
endc
	endc
	jr	.updateVolume
.normal
	ld	a,e
	ld	[hl+],a
	ld	[hl],d
.donesetFreq
	if(UseFXHammer)
	ld	a,[FXHammer_SFXCH2]
	cp	3
	ld	a,e
	jp	z,.updateVolume
	endc
if def(Visualizer)
	ld	[CH2ComputedFreq],a
	ldh	[rNR23],a
	ld	a,d
	ld	[CH2ComputedFreq+1],a
	ldh	[rNR24],a
else
	ldh	[rNR23],a
	ld	a,d
	ldh	[rNR24],a
endc

	; update volume
.updateVolume
	ld	hl,CH2Reset
	res	7,[hl]
	ld	hl,CH2VolPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH2VolLoop]
	ld	c,a
	inc	a	; ended
	jp	z,.done
	ld	a,[CH2VolPos]
	add	l
	ld	l,a
	jr	nc,.nocarry5
	inc	h
.nocarry5
	ld	a,[hl+]
	cp	$ff
	jr	z,.loadlast
	cp	$fd
	jp	z,.done
	ld	b,a
if !def(DemoSceneMode) && !def(DisableZombieMode)
	ld	a,[CH2ChanVol]
	push	hl
	call	MultiplyVolume
	pop	hl
	ld	a,[CH2VolLoop]
	dec	a
	jr	z,.zombieatpos0
	ld	a,[CH2VolPos]
	and	a
	jr	z,.zombinit
.zombieatpos0
endc
	ld	a,[CH2Vol]
	cp	b
	jr	z,.noreset3
if !def(DemoSceneMode) && !def(DisableZombieMode)
	ld	c,a
	ld	a,b
	ld	[CH2Vol],a
if def(Visualizer)
	ld	[CH2OutputLevel],a
endc
	sub	c
	and	$f
	ld	c,a
	ld	a,8
.zombloop
	ldh	[rNR22],a
	dec	c
	jr	nz,.zombloop
	jr	.noreset3
.zombinit
endc
if def(Visualizer)
	ld	a,b
	ld	[CH2Vol],a
	ld	[CH2OutputLevel],a
	swap	a
	or	8
	ldh	[rNR22],a
	xor	a
	ld	[CH2TempEnvelope],a
	ld	a,d
	or	$80
	ldh	[rNR24],a
else
	ld	a,b
	ld	[CH2Vol],a
	swap	a
	or	8
	ldh	[rNR22],a
	ld	a,d
	or	$80
	ldh	[rNR24],a
endc
.noreset3
	ld	a,[CH2VolPos]
	inc	a
	ld	[CH2VolPos],a
	ld	a,[hl+]
	cp	$fe
	jr	nz,.done
	ld	a,[hl]
	ld	[CH2VolPos],a
if !def(DemoSceneMode) && !def(DisableZombieMode)
	ld	a,1
	ld	[CH2VolLoop],a
endc
	jr	.done
.loadlast
	ld	a,[hl]
if !def(DemoSceneMode) && !def(DisableZombieMode)
	push	af
	swap	a
	and	$f
	ld	b,a
	ld	a,[CH2ChanVol]
	call	MultiplyVolume
	swap	b
	pop	af
	and	$f
	or	b
endc
	ldh	[rNR22],a
if def(Visualizer)
	ld	b,a
	and	$f
	ld	[CH2TempEnvelope],a
	and	$7
	inc	a
	ld	[CH2EnvelopeCounter],a
	ld	a,b
	swap	a
	and	$f
	ld	[CH2OutputLevel],a
endc
	ld	a,d
	or	$80
	ldh	[rNR24],a
	ld	a,$ff
	ld	[CH2VolLoop],a
.done

; ================================================================

CH3_UpdateRegisters:
	ld	a,[CH3Enabled]
	and	a
	jp	z,CH4_UpdateRegisters

	ld	a,[CH3NoteBackup]
	ld	[CH3Note],a
	cp	rest
	jr	nz,.norest
	ld	a,[CH3IsResting]
	and	a
	jp	nz,.done
	xor	a
	ldh	[rNR32],a
	ld	[CH3Vol],a
	ld	[CH3ComputedVol],a
	ldh	a,[rNR34]
	or	%10000000
	ldh	[rNR34],a
	ld	a,1
	ld	[CH3IsResting],a
	jp	.done
.norest
	xor	a
	ld	[CH3IsResting],a
	; update arps
.updatearp
; Deflemask compatibility: if pitch bend is active, don't update arp and force the transpose of 0
if !def(DisableDeflehacks)
	ld	a,[CH3PortaType]
	and	a
	jr	z,.noskiparp
	xor	a
	ld	[CH3Transpose],a
	jr	.continue
endc
.noskiparp
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
	cp	$fe
	jr	nz,.noloop
	ld	a,[hl]
	ld	[CH3ArpPos],a
	jr	.updatearp
.noloop
	cp	$ff
	jr	z,.continue
	cp	$80
	jr	nc,.absolute
	sla	a
	sra	a
	jr	.donearp
.absolute
	and	$7f
	ld	[CH3Note],a
	xor	a
.donearp
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
	ld	a,[CH3DoEcho]
	and	a
	jr	z,.skipecho
	ld	a,[CH3EchoDelay]
	ld	b,a
	ld	a,[EchoPos]
	sub	b
	and	$3f
	ld	hl,CH3EchoBuffer
	add	l
	ld	l,a
	jr	nc,.nocarry3
	inc	h
.nocarry3
	ld	a,[hl]
	cp	$4a
	jr	nz,.getfrequency
	; TODO: Prevent null byte from being played
	jr	.getfrequency
.skipecho	
	ld	a,[CH3PortaType]
	cp	2
	jr	c,.skippitchbend
	ld	a,[CH3Reset]
	bit	7,a
	jr	z,.pitchbend
.skippitchbend
	ld	a,[CH3Transpose]
	ld	b,a
	ld	a,[CH3Note]
	add	b

.getfrequency	
	ld	c,a
	ld	b,0
	ld	hl,FreqTable
	add	hl,bc
	add	hl,bc
	ld	a,[hl+]
	ld	e,a
	ld	a,[hl]
	ld	d,a
	ld	a,[CH3PortaType]
	cp	2
	jr	c,.updateVibTable
	ld	a,e
	ld	[CH3TempFreq],a
	ld	a,d
	ld	[CH3TempFreq+1],a
	
.updateVibTable
	ld	a,[CH3VibDelay]
	and	a
	jr	z,.doVib
	dec	a
	ld	[CH3VibDelay],a
	jr	.setFreq
.doVib
	ld	hl,CH3VibPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH3VibPos]
	add	l
	ld	l,a
	jr	nc,.nocarry4
	inc	h
.nocarry4
	ld	a,[hl+]
	cp	$80
	jr	nz,.noloop2
	ld	a,[hl+]
	ld	[CH3VibPos],a
	jr	.doVib
.noloop2
	ld	[CH3FreqOffset],a
	ld	a,[CH3VibPos]
	inc	a
	ld	[CH3VibPos],a
	jr	.getPitchOffset
	
.pitchbend
	ld	a,[CH3PortaSpeed]
	ld	b,a
	ld	a,[CH3PortaType]
	and	1
	jr	nz,.sub2
	ld	a,[CH3TempFreq]
	add	b
	ld	e,a
	ld	a,[CH3TempFreq+1]
	jr	nc,.nocarry6
	inc	a
.nocarry6
	ld	d,a
	cp	8
	jr	c,.pitchbenddone
	ld	de,$7ff
	jr	.pitchbenddone
.sub2
	ld	a,[CH3TempFreq]
	sub	b
	ld	e,a
	ld	a,[CH3TempFreq+1]
	jr	nc,.nocarry7
	dec	a
.nocarry7
	ld	d,a
	cp	8
	jr	c,.pitchbenddone
	ld	de,0
.pitchbenddone
	ld	hl,CH3TempFreq
	ld	a,e
	ld	[hl+],a
	ld	[hl],d
	
.getPitchOffset
	ld	a,[CH3FreqOffset]
	bit	7,a
	jr	nz,.sub
	add	e
	ld	e,a
	jr	nc,.setFreq
	inc	d
	jr	.setFreq
.sub
	ld	c,a
	ld	a,e
	add	c
	ld	e,a
.setFreq
	ld	hl,CH3TempFreq
	ld	a,[CH3PortaType]
	and	a
	jr	z,.normal
	dec	a
	ld	a,e
	jr	nz,.donesetFreq

; toneporta
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH3PortaSpeed]
	ld	c,a
	ld	b,0
	ld	a,h
	cp	d
	jr	c,.lt
	jr	nz,.gt
	ld	a,l
	cp	e
	jr	z,.tonepordone
	jr	c,.lt
.gt
	ld	a,l
	sub	c
	ld	l,a
	jr	nc,.nocarry8
	dec	h
.nocarry8
	ld	a,h
	cp	d
	jr	c,.clamp
	jr	nz,.tonepordone
	ld	a,l
	cp	e
	jr	c,.clamp
	jr	.tonepordone
.lt
	add	hl,bc
	ld	a,h
	cp	d
	jr	c,.tonepordone
	jr	nz,.clamp
	ld	a,l
	cp	e
	jr	c,.tonepordone
.clamp
	ld	h,d
	ld	l,e
if def(Visualizer)
.tonepordone
	ld	a,l
	ld	[CH3TempFreq],a
	ld	[CH3ComputedFreq],a
	ldh	[rNR33],a
	ld	a,h
	ld	d,a	; for later restart uses
	ld	[CH3TempFreq+1],a
	ld	[CH3ComputedFreq+1],a
	ldh	[rNR34],a
	jr	.updateVolume
.normal
	ld	a,e
	ld	[hl+],a
	ld	[hl],d
.donesetFreq
	ld	[CH3ComputedFreq],a
	ldh	[rNR33],a
	ld	a,d
	ld	[CH3ComputedFreq+1],a
	ldh	[rNR34],a
else
.tonepordone
	ld	a,l
	ld	[CH3TempFreq],a
	ldh	[rNR33],a
	ld	a,h
	ld	d,a	; for later restart uses
	ld	[CH3TempFreq+1],a
	ldh	[rNR34],a
	jr	.updateVolume
.normal
	ld	a,e
	ld	[hl+],a
	ld	[hl],d
.donesetFreq
	ldh	[rNR33],a
	ld	a,d
	ldh	[rNR34],a
endc
	
.updateVolume
	ld	hl,CH3Reset
	res	7,[hl]
	ld	hl,CH3VolPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH3VolPos]
	add	l
	ld	l,a
	jr	nc,.nocarry5
	inc	h
.nocarry5
	ld	a,[hl+]
	cp	$ff
	jr	z,.done
	cp	$fd
	jr	z,.done
	ld	b,a
if !def(DemoSceneMode)
	ld	a,[CH3ChanVol]
	push	hl
	call	MultiplyVolume
	pop	hl
endc
	ld	a,[CH3Vol]
	cp	b
if !def(DemoSceneMode) && !def(NoWaveVolumeScaling)
	ld	a,0
endc
	jr	z,.noreset3
	ld	a,b
	ld	[CH3Vol],a
if def(DemoSceneMode) || def(NoWaveVolumeScaling)
	and	a
	ld	b,a
	jr	z,.skip
	cp	8
	ld	b,%00100000
	jr	nc,.skip
	cp	4
	ld	b,%01000000
	jr	nc,.skip
	ld	b,%01100000
.skip
	ld	a,[CH3ComputedVol]
	cp	b
	jr	z,.noreset3
	ld	a,b
	ld	[CH3ComputedVol],a
	ld	[rNR32],a
	ld	a,d
	or	$80
	ldh	[rNR34],a
.noreset3
else
	ld	a,1
.noreset3
	ld	[WaveBufUpdateFlag],a
endc
	ld	a,[CH3VolPos]
	inc	a
	ld	[CH3VolPos],a
	ld	a,[hl+]
	cp	$fe
	jr	nz,.done
	ld	a,[hl]
	ld	[CH3VolPos],a
.done
	
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
	cp	$ff					; table end?
	jr	z,.updatebuffer
	ld	b,a
	ld	a,[CH3Wave]
	cp	b
if def(DemoSceneMode) || def(NoWaveVolumeScaling)
	jr	z,.noreset2
	ld	a,b
	ld	[CH3Wave],a
	cp	$c0
	push	hl
if def(DemoSceneMode) 
	jr	z,.noreset2			; if value = $c0, ignore (since this feature is disabled in DemoSceneMode)
else
	ld	hl,WaveBuffer
	jr	z,.wavebuf
endc
	ld	c,b
	ld	b,0
	ld	hl,WaveTable
	add	hl,bc
	add	hl,bc
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
.wavebuf
	call	LoadWave
	pop	hl
	ld	a,d
	or	%10000000
	ldh	[rNR34],a
.noreset2
else
	ld	c,0
	jr	z,.noreset2
	ld	a,b
	ld	[CH3Wave],a
	ld	c,1
.noreset2
	ld	a,[WaveBufUpdateFlag]
	or	c
	ld	[WaveBufUpdateFlag],a
endc
	ld	a,[CH3WavePos]
	inc	a
	ld	[CH3WavePos],a
	ld	a,[hl+]
	cp	$fe
	jr	nz,.updatebuffer
	ld	a,[hl]
	ld	[CH3WavePos],a

.updatebuffer
if !def(DemoSceneMode)
	call	DoPWM
	call	DoRandomizer
if !def(NoWaveVolumeScaling)
	ld	a,[WaveBufUpdateFlag]
	and	a
	jp	z,.noupdate
	ld	a,[CH3Wave]
	cp	$c0					; if value = $c0, use wave buffer
	jr	nz,.notwavebuf
	ld	bc,WaveBuffer
	jr	.multiplyvolume
.notwavebuf
	ld	c,a
	ld	b,0
	ld	hl,WaveTable
	add	hl,bc
	add	hl,bc
	ld	a,[hl+]
	ld	b,[hl]
	ld	c,a
.multiplyvolume
if def(Visualizer)
	push	bc
	ld	hl,VisualizerTempWave
	ld	e,16
.visuwavecopyloop
	ld	a,[bc]
	inc	bc
	cpl
	ld	[hl+],a
	dec	e
	jr	nz,.visuwavecopyloop
	pop	bc
endc
	ld	a,[CH3Vol]
	and	a
	jr	z,.mute
	cp	8
	ld	e,%00100000
	jr	nc,.skip
	add	a
	inc	a
	cp	8
	ld	e,%01000000
	jr	nc,.skip
	add	a
	inc	a
	ld	e,%01100000
.skip
	push	de
	srl	a
	push	af
	ld l, a
	ld h, 0
	add hl, hl ; x2
	add hl, hl ; x4
	add hl, hl ; x8
	add hl, hl ; x16
	ld de, VolumeTable
	add hl, de
	ld	d,h
	ld	e,l
	pop	af
	ld	a,16
	ld	hl,ComputedWaveBuffer
	jr	nc,.multnormal
.multswapped
	push	af
	ld	a,[bc]
	call	MultiplyVolume_
	swap	a
	and	$f
	ld	[hl],a
	ld	a,[bc]
	inc	bc
	swap	a
	call	MultiplyVolume_
	and	$f0
	or	[hl]
	ld	[hl+],a
	pop	af
	dec	a
	jr	nz,.multswapped
	jr	.multdone
.multnormal
	push	af
	ld	a,[bc]
	call	MultiplyVolume_
	and	$f
	ld	[hl],a
	ld	a,[bc]
	inc	bc
	swap	a
	call	MultiplyVolume_
	and	$f
	swap	a
	or	[hl]
	ld	[hl+],a
	pop	af
	dec	a
	jr	nz,.multnormal
.multdone
	pop	de
	ld	a,e
.mute
	ld	[CH3ComputedVol],a
	ld	[rNR32],a
	and	a
	call	nz,LoadWave
	xor	a
	ld	[WaveBufUpdateFlag],a
	ld	a,d
	or	$80
	ldh	[rNR34],a
.noupdate
endc
endc

; ================================================================

CH4_UpdateRegisters:
	ld	a,[CH4Enabled]
	and	a
	jp	z,DoneUpdatingRegisters
	
	if(UseFXHammer)
	ld	a,[FXHammer_SFXCH4]
	cp	3
	jr	z,.norest
	endc
	ld	a,[CH4ModeBackup]
	ld	[CH4Mode],a
	cp	rest
	jr	nz,.norest
	ld	a,[CH4IsResting]
	and	a
	jp	nz,.done
	xor	a
	ldh	[rNR42],a
if def(Visualizer)
	ld	[CH4OutputLevel],a
	ld	[CH4TempEnvelope],a
endc
	ldh	a,[rNR44]
	or	%10000000
	ldh	[rNR44],a
	ld	a,1
	ld	[CH4IsResting],a
	jp	.done
.norest
	xor	a
	ld	[CH4IsResting],a

	; update arps
.updatearp
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
	cp	$fe
	jr	nz,.noloop
	ld	a,[hl]
	ld	[CH4NoisePos],a
	jr	.updatearp
.noloop
	cp	$ff
	jr	z,.continue
	cp	$80
	jr	nc,.absolute
	sla	a
	sra	a
	jr	.donearp
.absolute
	and	$7f
	ld	[CH4Mode],a
	xor	a
.donearp
	ld	[CH4Transpose],a
.noreset
	ld	a,[CH4NoisePos]
	inc	a
	ld	[CH4NoisePos],a
.continue

	; update wave
if !def(DisableDeflehacks)
	ld	hl,CH4WavePtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH4WavePos]
	add	l
	ld	l,a
	jr	nc,.nocarry3
	inc	h
.nocarry3
	ld	a,[hl+]
	cp	$ff
	jr	z,.updateNote
	ld	[CH4Wave],a
	ld	a,[CH4WavePos]
	inc	a
	ld	[CH4WavePos],a
	ld	a,[hl+]
	cp	$fe
	jr	nz,.updateNote
	ld	a,[hl]
	ld	[CH4WavePos],a
endc
	
; get note
if def(DisableDeflehacks)
; don't do per noise mode arp clamping if deflemask compatibility mode
; is disabled so that relative arp with noise mode change is possible
.updateNote
	ld	a,[CH4Mode]
	ld	b,a
	ld	a,[CH4Transpose]
	bit	7,a
	jr	nz,.minus
	add	b
	cp	90
	jr	c,.noclamp
	ld	a,89
	jr	.noclamp
.minus
	add	b
	cp	90
	jr	c,.noclamp
	xor	a
.noclamp
else
.updateNote
	ld	c,0
	ld	a,[CH4Mode]
	cp	45
	ld	b,a
	jr	c,.noise15_2
	sub	45
	ld	b,a
	inc	c
.noise15_2
	ld	a,[CH4Transpose]
	bit	7,a
	jr	nz,.minus
	cp	45
	jr	c,.noise15_3
	sub	45
	ld	c,1
.noise15_3
	add	b
	cp	45
	jr	c,.noclamp
	ld	a,44
	jr	.noclamp
.minus
	add	b
	cp	45
	jr	c,.noclamp
	xor	a
.noclamp
	ld	b,a
	ld	a,[CH4Wave]
	or	c
	and	a
	jr	z,.noise15
	ld	a,45
.noise15
	add	b
endc
	
if def(Visualizer)
	ld	[CH4Noise],a
endc
	ld	hl,NoiseTable
	add	l
	ld	l,a
	jr	nc,.nocarry2
	inc	h
.nocarry2
	
	if(UseFXHammer)
	ld	a,[FXHammer_SFXCH4]
	cp	3
	jr	z,.updateVolume
	endc
	ld	a,[hl+]
	ldh	[rNR43],a	

	; update volume
.updateVolume
	ld	hl,CH4Reset
	res	7,[hl]
	ld	hl,CH4VolPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH4VolLoop]
	cp	$ff	; ended
	jp	z,.done
	ld	a,[CH4VolPos]
	add	l
	ld	l,a
	jr	nc,.nocarry5
	inc	h
.nocarry5
	ld	a,[hl+]
	cp	$ff
	jr	z,.loadlast
	cp	$fd
	jp	z,.done
	
	ld	b,a
if !def(DemoSceneMode) && !def(DisableZombieMode)
	ld	a,[CH4ChanVol]
	push	hl
	call	MultiplyVolume
	pop	hl
	ld	a,[CH4VolLoop]
	dec	a
	jr	z,.zombieatpos0
	ld	a,[CH4VolPos]
	and	a
	jr	z,.zombinit
.zombieatpos0
endc
	ld	a,[CH4Vol]
	cp	b
	jr	z,.noreset3
if !def(DemoSceneMode) && !def(DisableZombieMode)
	ld	c,a
	ld	a,b
	ld	[CH4Vol],a
if def(Visualizer)
	ld	[CH4OutputLevel],a
endc
	sub	c
	and	$f
	ld	c,a
	ld	a,8
.zombloop
	ldh	[rNR42],a
	dec	c
	jr	nz,.zombloop
	jr	.noreset3
.zombinit
endc
if def(Visualizer)
	ld	a,b
	ld	[CH4Vol],a
	ld	[CH4OutputLevel],a
	swap	a
	or	8
	ldh	[rNR42],a
	xor	a
	ld	[CH4TempEnvelope],a
	ld	a,$80
	ldh	[rNR44],a
else
	ld	a,b
	ld	[CH4Vol],a
	swap	a
	or	8
	ldh	[rNR42],a
	ld	a,$80
	ldh	[rNR44],a
endc
.noreset3
	ld	a,[CH4VolPos]
	inc	a
	ld	[CH4VolPos],a
	ld	a,[hl+]
	cp	$fe
	jr	nz,.done
	ld	a,[hl]
	ld	[CH4VolPos],a
if !def(DemoSceneMode) && !def(DisableZombieMode)
	ld	a,1
	ld	[CH4VolLoop],a
endc
	jr	.done
.loadlast
	ld	a,[hl]
if !def(DemoSceneMode)
	push	af
	swap	a
	and	$f
	ld	b,a
	ld	a,[CH4ChanVol]
	call	MultiplyVolume
	swap	b
	pop	af
	and	$f
	or	b
endc
	ldh	[rNR42],a
if def(Visualizer)
	ld	b,a
	and	$f
	ld	[CH4TempEnvelope],a
	and	$7
	inc	a
	ld	[CH4EnvelopeCounter],a
	ld	a,b
	swap	a
	and	$f
	ld	[CH4OutputLevel],a
endc
	ld	a,$80
	ldh	[rNR44],a
	ld	a,$ff
	ld	[CH4VolLoop],a
.done
	
DoneUpdatingRegisters:
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

; ================================================================
; Wave routines
; ================================================================

LoadWave:
if !def(DemoSceneMode) && !def(NoWaveVolumeScaling)
	ld	hl,ComputedWaveBuffer
else
if def(Visualizer)
	push	hl
	ld	bc,VisualizerTempWave
	ld	e,16
.visuwavecopyloop
	ld	a,[hl+]
	cpl
	ld	[bc],a
	inc	bc
	dec	e
	jr	nz,.visuwavecopyloop
	pop	hl
endc
endc
	ldh	a,[rNR51]
	ld	c,a
	and	%10111011
	ldh	[rNR51],a		; prevents spike
	xor	a
	ldh	[rNR30],a		; disable CH3
CUR_WAVE = _AUD3WAVERAM
rept 16
	ld a, [hl+]			; get byte from hl
	ldh [CUR_WAVE], a	; copy to wave ram
CUR_WAVE = CUR_WAVE + 1
endr
	ld	a,%10000000
	ldh	[rNR30],a		; enable CH3
	ld	a,c
	ldh	[rNR51],a
	ret
	
ClearWaveBuffer:
	ld	b,$20 ; spill to WaveBuffer too
	xor	a
	ld	hl,ComputedWaveBuffer
.loop
	ld	[hl+],a		; copy to wave ram
	dec	b
	jr	nz,.loop	; loop until done
	ret
	
if !def(DemoSceneMode)

; Combine two waves.
; INPUT: bc = first wave address
;		 de = second wave address

_CombineWaves:
	ld hl,WaveBuffer
	ld a,16
.loop
	push	af
	push	hl
	ld	a,[bc]
	and	$f
	ld	l,a
	ld	a,[de]
	and	$f
	add	l
	rra
	ld	l,a
	ld	a,[bc]
	inc	bc
	and	$f0
	ld	h,a
	ld	a,[de]
	inc	de
	and	$f0
	add	h
	rra
	and	$f0
	or	l
	pop	hl
	ld	[hl+],a
	pop	af
	dec	a
	jr	nz, .loop
	ld	a,[WaveBufUpdateFlag]
	or	1
	ld	[WaveBufUpdateFlag],a
	ret
	
; Randomize the wave buffer

_RandomizeWave:
	push	de
	ld	hl,NoiseData
	ld	de,WaveBuffer
	ld	b,$10
	ld	a,[WavePos]
	inc	a
	ld	[WavePos],a
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	ld	a,[hl+]
	ld	hl,NoiseData
	add	l
	ld	l,a
	jr	nc,.loop
	inc	h
.loop
	ld	a,[hl+]
	ld	[de],a
	inc	de
	dec	b
	jr	nz,.loop
	ld	a,[WaveBufUpdateFlag]
	or	1
	ld	[WaveBufUpdateFlag],a
	pop	de
	ret

; Do PWM
DoPWM:
	ld	a,[PWMEnabled]
	and	a
	ret	z	; if PWM is not enabled, return
	ld	a,[PWMTimer]
	dec	a
	ld	[PWMTimer],a
	and	a
	ret	nz
	ld	a,[PWMSpeed]
	ld	[PWMTimer],a
	ld	a,[PWMDir]
	and	a
	jr	nz,.decPos
.incPos	
	ld	a,[WavePos]
	inc	a
	ld	[WavePos],a
	cp	$1e
	jr	nz,.continue
	ld	a,[PWMDir]
	xor	1
	ld	[PWMDir],a
	jr	.continue
.decPos
	ld	a,[WavePos]
	dec	a
	ld	[WavePos],a
	and	a
	jr	nz,.continue2
	ld	a,[PWMDir]
	xor	1
	ld	[PWMDir],a
	jr	.continue2
.continue
	ld	hl,WaveBuffer
	ld	a,[WavePos]
	rra
	push	af
	and	$f
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	pop	af
	jr	c,.odd
.even
	ld	a,[PWMVol]
	swap	a
	ld	[hl],a
	jr	.done
.odd
	ld	a,[hl]
	ld	b,a
	ld	a,[PWMVol]
	or	b
	ld	[hl],a
	jr	.done
	
.continue2
	ld	hl,WaveBuffer
	ld	a,[WavePos]
	inc	a
	rra
	push	af
	and	$f
	add	l
	ld	l,a
	jr	nc,.nocarry2
	inc	h
.nocarry2
	pop	af
	jr	nc,.odd2
.even2
	ld	a,[PWMVol]
	swap	a
	ld	[hl],a
	jr	.done
.odd2
	xor	a
	ld	[hl],a
.done
	ld	a,[WaveBufUpdateFlag]
	or	1
	ld	[WaveBufUpdateFlag],a
	ret
	
DoRandomizer:
	ld	a,[RandomizerEnabled]
	and	a
	ret	z	; if randomizer is disabled, return
	ld	a,[RandomizerTimer]
	dec	a
	ld	[RandomizerTimer],a
	ret	nz
	ld	a,[RandomizerSpeed]
	ld	[RandomizerTimer],a
	call	_RandomizeWave
	ret
	
endc

; ================================================================
; Echo buffer routines
; ================================================================

DoEchoBuffers:
.ch1
	ld	hl,CH1EchoBuffer
	ld	a,[EchoPos]
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	ld	a,[CH1Note]
	ld	b,a
	cp	echo
	jr	nz,.continue1
	ld	a,___
	jr	.skiptranspose
.continue1
	ld	a,[CH1Transpose]
	add	b
	ld	b,a
.skiptranspose
	ld	[hl],a
.ch2
	ld	hl,CH2EchoBuffer
	ld	a,[EchoPos]
	add	l
	ld	l,a
	jr	nc,.nocarry2
	inc	h
.nocarry2
	ld	a,[CH2Note]
	ld	b,a
	cp	echo
	jr	nz,.continue2
	ld	a,___
	jr	.skiptranspose2
.continue2
	ld	a,[CH2Transpose]
	add	b
	ld	b,a
.skiptranspose2
	ld	[hl],a
.ch3
	ld	hl,CH3EchoBuffer
	ld	a,[EchoPos]
	add	l
	ld	l,a
	jr	nc,.nocarry3
	inc	h
.nocarry3
	ld	a,[CH3Note]
	ld	b,a
	cp	echo
	jr	nz,.continue3
	ld	a,___
	jr	.skiptranspose3
.continue3
	ld	a,[CH3Transpose]
	add	b
	ld	b,a
.skiptranspose3
	ld	[hl],a
	ld	a,[EchoPos]
	inc	a
	and	$3f
	ld	[EchoPos],a
	ret
	
ClearEchoBuffers:
	ld	hl,CH1EchoBuffer
	ld	b,(EchoPos-1)-CH1EchoBuffer
	xor	a
.loop
	ld	[hl+],a
	dec	b
	jr	nz,.loop
	ld	[EchoPos],a
	ld	[CH1EchoDelay],a
	ld	[CH2EchoDelay],a
	ld	[CH3EchoDelay],a
	ld	[CH1NotePlayed],a
	ld	[CH2NotePlayed],a
	ld	[CH3NotePlayed],a
	ret
	
; INPUT: a = note
CH1FillEchoBuffer:
	push	hl
	ld	b,a
	ld	a,1
	ld	[CH1NotePlayed],a
	ld	a,b
	ld	hl,CH1EchoBuffer
	jr	DoFillEchoBuffer
CH2FillEchoBuffer:
	push	hl
	ld	b,a
	ld	a,1
	ld	[CH2NotePlayed],a
	ld	a,b
	ld	hl,CH2EchoBuffer
	jr	DoFillEchoBuffer
CH3FillEchoBuffer:
	push	hl
	ld	b,a
	ld	a,1
	ld	[CH3NotePlayed],a
	ld	a,b
	ld	hl,CH3EchoBuffer
	; fall through to DoFillEchoBuffer
DoFillEchoBuffer:
	ld	b,64
.loop
	ld	[hl+],a
	dec	b
	jr	nz,.loop
	pop	hl
	ret
	
	
; ================================================================
; Misc routines
; ================================================================

JumpTableBelow:
; since the return pointer is now at the start of table,
; we can manipulate it to return to the address in the table instead
	pop	bc
	push	hl
	add	a ; It is recommended to use this to keep optimizations on the four channel's jumptables
	add	c
	ld	l,a
	jr	nc,.nocarry
	inc	b
.nocarry
	ld	h,b
	ld	a,[hl+]
	ld	b,[hl]
	ld	c,a
	pop	hl
	push	bc
	ret

ClearArpBuffer:
	ld	hl,arp_Buffer
	ld	[hl],$ff
	inc	hl
	ld	b,7
	xor	a
.loop
	ld	a,[hl+]
	dec	b
	jr	nz,.loop
	ret
	
DoArp:
	ld	de,arp_Buffer
	ld	a,[hl+]
	and	a
	jr	nz,.slow
.fast
	xor	a
	ld	[de],a
	inc	de
	ld	a,[hl]
	swap	a
	and	$f
	ld	[de],a
	inc	de
	ld	a,[hl+]
	and	$f
	ld	[de],a
	inc	de
	ld	a,$fe
	ld	[de],a
	inc	de
	xor	a
	ld	[de],a
	ret
.slow
	xor	a
	ld	[de],a
	inc	de
	ld	[de],a
	inc	de
	ld	a,[hl]
	swap	a
	and	$f
	ld	[de],a
	inc	de
	ld	[de],a
	inc	de
	ld	a,[hl+]
	and	$f
	ld	[de],a
	inc	de
	ld	[de],a
	inc	de
	ld	a,$fe
	ld	[de],a
	inc	de
	xor	a
	ld	[de],a
	ret
	
if !def(DemoSceneMode)
MultiplyVolume:
	srl	b
	push	af
	ld	l,b
	ld	h,0
	add	hl,hl	; x2
	add	hl,hl	; x4
	add	hl,hl	; x8
	add	hl,hl	; x16
	ld	bc,VolumeTable
	add	hl,bc
	ld	c,a
	ld	b,0
	add	hl,bc
	pop	af
	ld	a,[hl]
	jr	nc,.noswap
	swap	a
.noswap
	and	$f
	ld	b,a
	ret
	
MultiplyVolume_:
; short version of MultiplyVolume for ch3 wave update
	push	de
	and	$f
	add	e
	ld	e,a
	jr	nc,.nocarry
	inc	d
.nocarry
	ld a,[de]
	pop	de
	ret
	
endc
	
; ================================================================
; Frequency table
; ================================================================

FreqTable:
;	     C-x  C#x  D-x  D#x  E-x  F-x  F#x  G-x  G#x  A-x  A#x  B-x
	dw	$02c,$09c,$106,$16b,$1c9,$223,$277,$2c6,$312,$356,$39b,$3da ; octave 1
	dw	$416,$44e,$483,$4b5,$4e5,$511,$53b,$563,$589,$5ac,$5ce,$5ed ; octave 2
	dw	$60a,$627,$642,$65b,$672,$689,$69e,$6b2,$6c4,$6d6,$6e7,$6f7 ; octave 3
	dw	$706,$714,$721,$72d,$739,$744,$74f,$759,$762,$76b,$773,$77b ; octave 4
	dw	$783,$78a,$790,$797,$79d,$7a2,$7a7,$7ac,$7b1,$7b6,$7ba,$7be ; octave 5
	dw	$7c1,$7c4,$7c8,$7cb,$7ce,$7d1,$7d4,$7d6,$7d9,$7db,$7dd,$7df ; octave 6
	dw	$7e1,$7e3,$7e4,$7e6,$7e7,$7e9,$7ea,$7eb,$7ec,$7ed,$7ee,$7ef ; octave 7 (not used directly, is slightly out of tune)
	
NoiseTable:	; taken from deflemask
	db	$a4	; 15 steps
	db	$97,$96,$95,$94,$87,$86,$85,$84,$77,$76,$75,$74,$67,$66,$65,$64
	db	$57,$56,$55,$54,$47,$46,$45,$44,$37,$36,$35,$34,$27,$26,$25,$24
	db	$17,$16,$15,$14,$07,$06,$05,$04,$03,$02,$01,$00
	db	$ac	; 7 steps
	db	$9f,$9e,$9d,$9c,$8f,$8e,$8d,$8c,$7f,$7e,$7d,$7c,$6f,$6e,$6d,$6c
	db	$5f,$5e,$5d,$5c,$4f,$4e,$4d,$4c,$3f,$3e,$3d,$3c,$2f,$2e,$2d,$2c
	db	$1f,$1e,$1d,$1c,$0f,$0e,$0d,$0c,$0b,$0a,$09,$08
	
if !def(DemoSceneMode)
	
VolumeTable: ; used for volume multiplication
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 10
	db $10,$10,$10,$10,$10,$10,$10,$10
	db $00,$00,$00,$00,$10,$11,$11,$11 ; 32
	db $21,$21,$21,$22,$32,$32,$32,$32
	db $00,$00,$10,$11,$11,$21,$22,$22 ; 54
	db $32,$32,$33,$43,$43,$44,$54,$54
	db $00,$00,$11,$11,$22,$22,$32,$33 ; 76
	db $43,$44,$54,$54,$65,$65,$76,$76
	db $00,$00,$11,$21,$22,$33,$43,$44 ; 98
	db $54,$55,$65,$76,$77,$87,$98,$98
	db $00,$11,$11,$22,$33,$43,$44,$55 ; ba
	db $65,$76,$77,$87,$98,$a9,$a9,$ba
	db $00,$11,$22,$33,$43,$44,$55,$66 ; dc
	db $76,$87,$98,$99,$a9,$ba,$cb,$dc
	db $00,$11,$22,$33,$44,$55,$66,$77 ; fe
	db $87,$98,$a9,$ba,$cb,$dc,$ed,$fe
	
endc

; ================================================================
; misc stuff
; ================================================================
	
DefaultRegTable:
	; global flags
	db	0,7,0,0,0,0,0,1,1,1,1,1,0,0,0,0
	; ch1
	dw	DummyTable,DummyTable,DummyTable,DummyTable,DummyTable
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	; ch2
	dw	DummyTable,DummyTable,DummyTable,DummyTable,DummyTable
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	; ch3
	dw	DummyTable,DummyTable,DummyTable,DummyTable,DummyTable
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	; ch4
if def(DisableDeflehacks)
	dw	DummyTable,DummyTable,DummyTable
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
else
	dw	DummyTable,DummyTable,DummyTable,DummyTable
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
endc
	
DefaultWave:	db	$01,$23,$45,$67,$89,$ab,$cd,$ef,$fe,$dc,$ba,$98,$76,$54,$32,$10

NoiseData:		incbin	"NoiseData.bin"
	
; ================================================================
; Dummy data
; ================================================================
	
DummyTable:	db	$ff,0
vib_Dummy:	db	0,0,$80,1

DummyChannel:
	db	EndChannel
	
; ================================================================
; Song data
; ================================================================

if	!def(DontIncludeSongData)
	include	"DevSound_SongData.asm"
endc
