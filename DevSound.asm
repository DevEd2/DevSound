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
	push	af		; Preserve song ID

	xor	a
	ldh	[rNR52],a	; disable sound
	ld	[PWMEnabled],a
	ld	[RandomizerEnabled],a
	ld	[WaveBufUpdateFlag],a

	; init sound RAM area
	ld	de,DefaultRegTable
	ld	hl,InitVarsStart
	ld	c,DSVarsEnd-InitVarsStart
.initLoop
	ld	a,[de]
	ld	[hl+],a
	inc	de
	dec	c
	jr	nz,.initLoop
	xor	a
	ld	c,DSBufVarsEnd-DSBufVars
.initLoop2
	ld	[hl+],a
	dec	c
	jr	nz,.initLoop2

	; load default waveform
	ld	hl,DefaultWave
	call	LoadWave
	; clear buffers
	call	ClearWaveBuffer
	call	ClearArpBuffer
	call	ClearEchoBuffers
	pop	af
	add	a
	ld	e,a
	adc	a,0
	sub	e
	ld	d,a
	; set up song pointers
	ld	hl,SongPointerTable
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
	ld	a,low(DummyChannel)
	ld	[CH1RetPtr],a
	ld	[CH2RetPtr],a
	ld	[CH3RetPtr],a
	ld	[CH4RetPtr],a
	ld	a,high(DummyChannel)
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
	xor	a
	ld	[CH1Enabled],a
	ld	[CH2Enabled],a
	ld	[CH3Enabled],a
	ld	[CH4Enabled],a
	ld	[SoundEnabled],a
	dec	a		; Set a to $FF
	ld	[c],a	; all sound channels to left+right speakers
	dec	c
	and	$77
	ld	[c],a	; VIN output off + master volume max
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
	ld	a,[GlobalSpeed2]
	jr	.setTimer
.odd
	ld	a,[GlobalSpeed1]
.setTimer
	ld	[GlobalTimer],a		; store timer value
	jr	UpdateCH1			; continue ahead

.noupdate
	dec	a					; subtract 1 from timer
	ld	[GlobalTimer],a		; store timer value
	jp	DoneUpdating		; done

; ================================================================

UpdateChannel: macro
IS_PULSE_CHANNEL equ (\1 == 1) || (\1 == 2)
IS_WAVE_CHANNEL   equ \1 == 3
IS_NOISE_CHANNEL  equ \1 == 4

	ld	a,[CH\1Enabled]
	and	a
	jp	z,CH\1Updated		; if channel is disabled, skip to next one
	ld	a,[CH\1Tick]
	and	a
	jr	z,.continue			; if channel tick = 0, then jump ahead
	dec	a					; otherwise...
	ld	[CH\1Tick],a		; decrement channel tick...
	jp	CH\1Updated			; ...and do echo buffer.
.continue
	ld	hl,CH\1Ptr			; get pointer
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
CH\1_CheckByte:
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
if !IS_NOISE_CHANNEL
	ld	b,a
	xor	a
	ld	[CH\1DoEcho],a
	ld	a,b
endc
.getNote
if IS_NOISE_CHANNEL
	ld	[CH\1ModeBackup],a
else
	ld	[CH\1NoteBackup],a	; set note
	ld	b,a
	ld	a,[CH\1NotePlayed]
	and	a
	jr	nz,.skipfill
	ld	a,b
	call	CH\1FillEchoBuffer
.skipfill
endc
	ld	a,[hl+]				; get note length
	dec	a					; subtract 1
	ld	[CH\1Tick],a		; set channel tick
	ld	a,l					; store back current pos
	ld	[CH\1Ptr],a
	ld	a,h
	ld	[CH\1Ptr+1],a
if !IS_NOISE_CHANNEL
	ld	a,[CH\1PortaType]
	dec	a					; if toneporta, don't reset everything
	jr	z,.noreset
endc

if !IS_WAVE_CHANNEL
	if ((\1 == 2) || (\1 == 4)) && UseFXHammer
	ld	a,[FXHammer_SFXCH\1]
	cp	3
	jr	z,.noupdate
	endc
	xor	a
else
	ld	a, $FF
	ld	[CH\1Wave],a
	ld	a,[CH\1ComputedVol]		; Fix for volume not updating when unpausing
endc
	ldh	[rNR\12],a
.noupdate

	xor	a
if IS_NOISE_CHANNEL
	ld	[CH\1NoisePos],a
	if !def(DisableDeflehacks)
	ld	[CH\1WavePos],a
	endc
else
	ld	[CH\1ArpPos],a		; reset arp position
	inc	a
	ld	[CH\1VibPos],a		; reset vibrato position

	ld	hl,CH\1VibPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[hl]					; get vibrato delay
	ld	[CH\1VibDelay],a		; set delay
endc

	xor	a
	ld	hl,CH\1Reset
if !IS_NOISE_CHANNEL
	bit	0,[hl]
	jr	nz,.noreset_checkvol
	if IS_PULSE_CHANNEL
	ld	[CH\1PulsePos],a
	elif IS_WAVE_CHANNEL
	ld	[CH\1WavePos],a
	endc
.noreset_checkvol
endc
	bit	1,[hl]
	jr	nz,.noreset
	ld	[CH\1VolPos],a
if !IS_WAVE_CHANNEL
	ld	[CH\1VolLoop],a
endc
.noreset
	ld	a,[CH\1NoteCount]
	inc	a
	ld	[CH\1NoteCount],a
	ld	b,a

	; check if instrument mode is 1 (alternating)
	ld	a,[CH\1InsMode]
	and	a
	jr	z,.noInstrumentChange
	ld	a,b
	rra
	jr	nc,.notodd
	ld	a,[CH\1Ins1]
	jr	.odd
.notodd
	ld	a,[CH\1Ins2]
.odd
	call	CH\1_SetInstrument
.noInstrumentChange
if !IS_NOISE_CHANNEL
	ld	hl,CH\1Reset
	set	7,[hl]			; signal the start of note for pitch bend
endc
	jp	CH\1Updated

.endChannel
	xor	a
	ld	[CH\1Enabled],a
	jp	CH\1Updated

.retSection
	ld	hl,CH\1RetPtr
	ld	a,[hl+]
	ld	[CH\1Ptr],a
	ld	a,[hl]
	ld	[CH\1Ptr+1],a
	jp	UpdateCH\1

.echo ; Not applicable to CH4
if !IS_NOISE_CHANNEL
	ld	b,a
	ld	a,1
	ld	[CH\1DoEcho],a
	ld	a,b
	jp	.getNote
endc

.nullnote
if !IS_NOISE_CHANNEL
	xor	a
	ld	[CH\1DoEcho],a
endc
	ld	a,[hl+]
	dec	a
	ld	[CH\1Tick],a		; set tick
	ld	a,l				; store back current pos
	ld	[CH\1Ptr],a
	ld	a,h
	ld	[CH\1Ptr+1],a
	jp	CH\1Updated

.release
	; follows FamiTracker's behavior except only the volume table will be affected
if !IS_NOISE_CHANNEL
	xor	a
	ld	[CH\1DoEcho],a
endc
	ld	a,[hl+]
	dec	a
	ld	[CH\1Tick],a		; set tick
	ld	a,l				; store back current pos
	ld	[CH\1Ptr],a
	ld	a,h
	ld	[CH\1Ptr+1],a
	ld	hl,CH\1VolPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	b,0
.releaseloop
	ld	a,[hl+]
	inc	b
	cp	$ff
	jr	z,.norelease
	cp	$fe
	jr	nz,.releaseloop
	ld	a,b
	inc	a
	ld	[CH\1VolPos],a
.norelease
	jp	CH\1Updated

.getCommand
if !IS_NOISE_CHANNEL
	ld	b,a
	xor	a
	ld	[CH\1DoEcho],a
	ld	a,b
endc
	cp	DummyCommand
	jp	nc, CH\1_CheckByte
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
if IS_WAVE_CHANNEL && !def(DemoSceneMode)
	dw	.randomizeWave
else
	dw	CH\1_CheckByte
endc
	dw	.combineWaves
	dw	.enablePWM
	dw	.enableRandomizer
if IS_WAVE_CHANNEL && !def(DemoSceneMode)
	dw	.disableAutoWave
else
	dw	CH\1_CheckByte
endc
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
	call	CH\1_SetInstrument
	pop	hl						; restore HL
	xor	a
	ld	[CH\1InsMode],a			; reset instrument mode
	jp	CH\1_CheckByte

.setLoopPoint
	ld	a,l
	ld	[CH\1LoopPtr],a
	ld	a,h
	ld	[CH\1LoopPtr+1],a
	jp	CH\1_CheckByte

.gotoLoopPoint
	ld	hl,CH\1LoopPtr			; get loop pointer
	ld	a,[hl+]
	ld	[CH\1Ptr],a
	ld	a,[hl]
	ld	[CH\1Ptr+1],a
	jp	UpdateCH\1

.callSection
	ld	a,[hl+]
	ld	[CH\1Ptr],a
	ld	a,[hl+]
	ld	[CH\1Ptr+1],a
	ld	a,l
	ld	[CH\1RetPtr],a
	ld	a,h
	ld	[CH\1RetPtr+1],a
	jp	UpdateCH\1

.setChannelPtr
	ld	a,[hl+]
	ld	[CH\1Ptr],a
	ld	a,[hl]
	ld	[CH\1Ptr+1],a
	jp	UpdateCH\1

if !IS_NOISE_CHANNEL
.pitchBendUp
	ld	a,[hl+]
	ld	[CH\1PortaSpeed],a
	and	a
	jr	z,.loadPortaType
	ld	a,2
	jr	.loadPortaType

.pitchBendDown
	ld	a,[hl+]
	ld	[CH\1PortaSpeed],a
	and	a
	jr	z,.loadPortaType
	ld	a,3
	jr	.loadPortaType

.toneporta
	ld	a,[hl+]
	ld	[CH\1PortaSpeed],a
	and	a
	jr	z,.loadPortaType
	ld	a,1
.loadPortaType
	ld	[CH\1PortaType],a
	jp	CH\1_CheckByte
endc

if \1 == 1
.setSweep
	ld	a,[hl+]
	ld	[CH\1Sweep],a
	jp	CH\1_CheckByte
endc

.setPan
	ld	a,[hl+]
	ld	[CH\1Pan],a
	jp	CH\1_CheckByte

.setSpeed
	ld	a,[hl+]
	dec	a
	ld	[GlobalSpeed1],a
	ld	a,[hl+]
	dec	a
	ld	[GlobalSpeed2],a
	jp	CH\1_CheckByte

.setInsAlternate
	ld	a,[hl+]
	ld	[CH\1Ins1],a
	ld	a,[hl+]
	ld	[CH\1Ins2],a
	ld	a,1
	ld	[CH\1InsMode],a
	jp	CH\1_CheckByte

if IS_WAVE_CHANNEL && !def(DemoSceneMode)
.randomizeWave
	push	hl
	call	_RandomizeWave
	pop	hl
	jp	CH\1_CheckByte

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
	jp	CH\1_CheckByte

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
	jp	CH\1_CheckByte

.enableRandomizer
	push	hl
	call	ClearWaveBuffer
	pop	hl
	ld	a,[hl+]
	ld	[RandomizerSpeed],a
	xor	a
	ld	[PWMEnabled],a
	inc a
	ld	[RandomizerTimer],a
	ld	[RandomizerEnabled],a
	jp	CH\1_CheckByte

.disableAutoWave
	xor	a
	ld	[PWMEnabled],a
	ld	[RandomizerEnabled],a
	jp	CH\1_CheckByte
else
.combineWaves
	inc hl
	inc hl
.enablePWM
	if IS_NOISE_CHANNEL
.arp
	endc
	inc	hl
.enableRandomizer
endc
if IS_NOISE_CHANNEL
.pitchBendUp
.pitchBendDown
.toneporta
.setEchoDelay
endc
if \1 != 1
.setSweep
endc
	inc	hl
	jp	CH\1_CheckByte

.setSyncTick
	ld	a,[hl+]
	ld	[SyncTick],a
	jp	CH\1_CheckByte

.chanvol
	ld	a,[hl+]
	and	$f
	ld	[CH\1ChanVol],a
	jp	CH\1_CheckByte

if !IS_NOISE_CHANNEL
.arp
	call	DoArp
	jp	CH\1_CheckByte

.setEchoDelay
	ld	a,[hl+]
	and	$3f
	ld	[CH\1EchoDelay],a
	jp	CH\1_CheckByte
endc

.setRepeatPoint
	ld	a,l
	ld	[CH\1RepeatPtr],a
	ld	a,h
	ld	[CH\1RepeatPtr+1],a
	jp	CH\1_CheckByte

.repeatSection
	ld	a,[CH\1RepeatCount]
	and	a	; section currently repeating?
	jr	z,.notrepeating
	dec	a
	ld	[CH\1RepeatCount],a
	and	a
	jr	z,.stoprepeating
	inc	hl
	jr	.dorepeat
.notrepeating
	ld	a,[hl+]
	dec	a
	ld	[CH\1RepeatCount],a
	ld	a,1
	ld	[CH\1DoRepeat],a
.dorepeat
	ld	hl,CH\1RepeatPtr		; get loop pointer
	ld	a,[hl+]
	ld	[CH\1Ptr],a
	ld	a,[hl]
	ld	[CH\1Ptr+1],a
	jp	UpdateCH\1
.stoprepeating
	xor	a
	ld	[CH\1DoRepeat],a
.norepeat
	inc	hl
	jp	CH\1_CheckByte

CH\1_SetInstrument:
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
	ld	[CH\1Reset],a
	ld	b,a
	; vol table
	ld	a,[hl+]
	ld	[CH\1VolPtr],a
	ld	a,[hl+]
	ld	[CH\1VolPtr+1],a

	; arp table
	ld	a,[hl+]
if IS_NOISE_CHANNEL
	ld	[CH\1NoisePtr],a
else
	ld	[CH\1ArpPtr],a
endc
	ld	a,[hl+]
if IS_NOISE_CHANNEL
	ld	[CH\1NoisePtr+1],a
else
	ld	[CH\1ArpPtr+1],a
endc

if !IS_NOISE_CHANNEL || !def(DisableDeflehacks)
	; pulse table
	ld	a,[hl+]
	if IS_PULSE_CHANNEL
	ld	[CH\1PulsePtr],a
	else
	ld	[CH\1WavePtr],a
	endc
	ld	a,[hl+]
	if IS_PULSE_CHANNEL
	ld	[CH\1PulsePtr+1],a
	else
	ld	[CH\1WavePtr+1],a
	endc
endc
if !IS_NOISE_CHANNEL
	; vib table
	ld	a,[hl+]
	ld	[CH\1VibPtr],a
	ld	a,[hl+]
	ld	[CH\1VibPtr+1],a
	ld	hl,CH\1VibPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[hl]
	ld	[CH\1VibDelay],a
endc
	ret

CH\1Updated:

	PURGE IS_PULSE_CHANNEL
	PURGE IS_WAVE_CHANNEL
	PURGE IS_NOISE_CHANNEL
endm

; ================================================================

UpdateCH1:
	UpdateChannel 1

UpdateCH2:
	UpdateChannel 2

UpdateCH3:
	UpdateChannel 3

UpdateCH4:
	UpdateChannel 4

; ================================================================

DoneUpdating:

	call	DoEchoBuffers
	; update panning
	ld	a,[CH4Pan]
	add	a
	ld	b,a
	ld	a,[CH3Pan]
	or	b
	add	a
	ld	b,a
	ld	a,[CH2Pan]
	or	b
	add	a
	ld	b,a
	ld	a,[CH1Pan]
	or	b
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
.fadeout
	ld	a,[GlobalVolume]
	and	a
	jr	z,.fadeFinished
.decrementVolume
	dec	a
	ld	[GlobalVolume],a
	jr	.directlyUpdateVolume
.fadein
	ld	a,[GlobalVolume]
	cp	7
	jr	z,.fadeFinished
	inc	a
	ld	[GlobalVolume],a
	jr .directlyUpdateVolume
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
	ld	a,[GlobalVolume]
	jr	nz,.directlyUpdateVolume
.fadeoutstop
	and	a
	jr	nz,.decrementVolume
	call	DevSound_Stop
	xor a
.fadeFinished
	; a is zero
	ld	[FadeType],a
.updateVolume
	ld	a,[GlobalVolume]
.directlyUpdateVolume
	and	7
	ld	b,a
	swap	a
	or	b
	ldh	[rNR50],a

; ================================================================

UpdateRegisters: macro
	ld	a,[CH\1Enabled]
	and	a
	jp	z,CH\1RegistersUpdated

if ((\1 == 2) || (\1 == 4)) && UseFXHammer
	ld	a,[FXHammer_SFXCH\1]
	cp	3
	jr	z,.norest
endc
if \1 != 4
	ld	a,[CH\1NoteBackup]
	ld	[CH\1Note],a
else
	ld	a,[CH\1ModeBackup]
	ld	[CH\1Mode],a
endc
	cp	rest
	jr	nz,.norest
	ld	a,[CH\1IsResting]
	and	a
	jp	nz,.done
	xor	a
	ldh	[rNR\12],a
if \1 == 3
	ld	[CH\1Vol],a
	ld	[CH\1ComputedVol],a
elif def(Visualizer)
	ld	[CH\1OutputLevel],a
	ld	[CH\1TempEnvelope],a
endc
	ldh	a,[rNR\14]
	or	%10000000
	ldh	[rNR\14],a
	ld	a,1
	ld	[CH\1IsResting],a
	jp	.done
.norest
	xor	a
	ld	[CH\1IsResting],a

	; update arps
.updatearp
; Deflemask compatibility: if pitch bend is active, don't update arp and force the transpose of 0
if \1 != 4 && !def(DisableDeflehacks)
	ld	a,[CH\1PortaType]
	and	a
	jr	z,.noskiparp
	xor	a
	ld	[CH\1Transpose],a
	jr	.continue
endc
.noskiparp
if \1 != 4
	ld	hl,CH\1ArpPtr
else
	ld	hl,CH\1NoisePtr
endc
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
if \1 != 4
	ld	a,[CH\1ArpPos]
else
	ld	a,[CH\1NoisePos]
endc
	add	l
	ld	l,a
	jr	nc,.nocarry
	inc	h
.nocarry
	ld	a,[hl+]
	cp	$fe
	jr	nz,.noloop
	ld	a,[hl]
if \1 != 4
	ld	[CH\1ArpPos],a
else
	ld	[CH\1NoisePos],a
endc
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
if \1 != 4
	ld	[CH\1Note],a
else
	ld	[CH\1Mode],a
endc
	xor	a
.donearp
	ld	[CH\1Transpose],a
.noreset
if \1 != 4
	ld	hl,CH\1ArpPos
else
	ld	hl,CH\1NoisePos
endc
	inc	[hl]
.continue

if \1 == 1
	; update sweep
	ld	a,[CH\1Sweep]
	ldh	[rNR\10],a
elif \1 == 3
	ld	a,$80
	ldh	[rNR\10],a
endc

if \1 == 4
	if !def(DisableDeflehacks)
	ld	hl,CH\1WavePtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH\1WavePos]
	add	l
	ld	l,a
	jr	nc,.nocarry3
	inc	h
.nocarry3
	ld	a,[hl+]
	cp	$ff
	jr	z,.updateNote
	ld	[CH\1Wave],a
	ld	a,[CH\1WavePos]
	inc	a
	ld	[CH\1WavePos],a
	ld	a,[hl+]
	cp	$fe
	jr	nz,.updateNote
	ld	a,[hl]
	ld	[CH\1WavePos],a
	endc
elif \1 != 3
	; update pulse
	ld	hl,CH\1PulsePtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH\1PulsePos]
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
	ld	[CH\1Pulse],a
	endc
	rrca			; rotate right
	rrca			;   ""    ""
	if (\1 == 2) && UseFXHammer
	ld	e,a
	ld	a,[FXHammer_SFXCH\1]
	cp	3
	jr	z,.noreset2
	ld	a,e
	endc
	ldh	[rNR\11],a	; transfer to register
.noreset2
	ld	a,[CH\1PulsePos]
	inc	a
	ld	[CH\1PulsePos],a
	ld	a,[hl+]
	cp	$fe
	jr	nz,.updateNote
	ld	a,[hl]
	ld	[CH\1PulsePos],a
endc

; get note
.updateNote
if \1 != 4
	ld	a,[CH\1DoEcho]
	and	a
	jr	z,.skipecho
	ld	a,[CH\1EchoDelay]
	ld	b,a
	ld	a,[EchoPos]
	sub	b
	and	$3f
	ld	hl,CH\1EchoBuffer
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
	ld	a,[CH\1PortaType]
	cp	2
	jr	c,.skippitchbend
	ld	a,[CH\1Reset]
	bit	7,a
	jr	z,.pitchbend
.skippitchbend
	if \1 == 1
	ld	a,[CH\1Sweep]
	and	$70
	jr	z,.noskipsweep
	ld	a,[CH\1Reset]
	bit	7,a
	jp	z,.updateVolume
.noskipsweep
	endc
	ld	a,[CH\1Transpose]
	ld	b,a
	ld	a,[CH\1Note]
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
	ld	a,[CH\1PortaType]
	cp	2
	jr	c,.updateVibTable
	ld	a,e
	ld	[CH\1TempFreq],a
	ld	a,d
	ld	[CH\1TempFreq+1],a

.updateVibTable
	ld	a,[CH\1VibDelay]
	and	a
	jr	z,.doVib
	dec	a
	ld	[CH\1VibDelay],a
	jr	.setFreq
.doVib
	ld	hl,CH\1VibPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH\1VibPos]
	add	l
	ld	l,a
	jr	nc,.nocarry4
	inc	h
.nocarry4
	ld	a,[hl+]
	cp	$80
	jr	nz,.noloop2
	ld	a,[hl+]
	ld	[CH\1VibPos],a
	jr	.doVib
.noloop2
	ld	[CH\1FreqOffset],a
	ld	a,[CH\1VibPos]
	inc	a
	ld	[CH\1VibPos],a
	jr	.getPitchOffset

.pitchbend
	ld	a,[CH\1PortaSpeed]
	ld	b,a
	ld	a,[CH\1PortaType]
	and	1
	jr	nz,.sub2
	ld	a,[CH\1TempFreq]
	add	b
	ld	e,a
	ld	a,[CH\1TempFreq+1]
	jr	nc,.nocarry6
	inc	a
.nocarry6
	ld	d,a
	cp	8
	jr	c,.pitchbenddone
	ld	de,$7ff
	jr	.pitchbenddone
.sub2
	ld	a,[CH\1TempFreq]
	sub	b
	ld	e,a
	ld	a,[CH\1TempFreq+1]
	jr	nc,.nocarry7
	dec	a
.nocarry7
	ld	d,a
	cp	8
	jr	c,.pitchbenddone
	ld	de,0
.pitchbenddone
	ld	hl,CH\1TempFreq
	ld	a,e
	ld	[hl+],a
	ld	[hl],d

.getPitchOffset
	ld	a,[CH\1FreqOffset]
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
	ld	hl,CH\1TempFreq
	ld	a,[CH\1PortaType]
	and	a
	jr	z,.normal
	dec	a
	ld	a,e
	jr	nz,.donesetFreq

; toneporta
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH\1PortaSpeed]
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
	ld	a,l
	ld	[CH\1TempFreq],a
	if def(Visualizer)
	ld	[CH\1ComputedFreq],a
	endc
	if \1 != 2 || !UseFXHammer
	ldh	[rNR\13],a
	endc
	ld	a,h
	ld	d,a	; for later restart uses
	ld	[CH\1TempFreq+1],a
	if def(Visualizer)
	ld	[CH\1ComputedFreq+1],a
	endc
	if \1 != 2 || !UseFXHammer
	ldh	[rNR\14],a
	elif UseFXHammer
	ld	a,[FXHammer_SFXCH\1]
	cp	3
	jr	z,.updateVolume
	ld	a,l
	ldh	[rNR\13],a
	ld	a,h
	ldh	[rNR\14],a
	endc
	jr	.updateVolume
.normal
	ld	a,e
	ld	[hl+],a
	ld	[hl],d
.donesetFreq
	if \1 == 2 && UseFXHammer
	ld	a,[FXHammer_SFXCH\1]
	cp	3
	ld	a,e
	jr	z,.updateVolume
	endc
	if def(Visualizer)
	ld	[CH\1ComputedFreq],a
	endc
	ldh	[rNR\13],a
	ld	a,d
	if def(Visualizer)
	ld	[CH\1ComputedFreq+1],a
	endc
	ldh	[rNR\14],a
else
	; don't do per noise mode arp clamping if deflemask compatibility mode
	; is disabled so that relative arp with noise mode change is possible
	ld	a,[CH\1Mode]
CLAMP_VALUE = 90
	if !def(DisableDeflehacks)
CLAMP_VALUE = 45
	cp	CLAMP_VALUE
	ld	c,0
	jr	c,.noise15_2
	sub	CLAMP_VALUE
	inc	c
.noise15_2
	endc
	ld	b,a
	ld	a,[CH\1Transpose]
	bit	7,a
	jr	nz,.minus
	if !def(DisableDeflehacks)
	cp	CLAMP_VALUE
	jr	c,.noise15_3
	sub	CLAMP_VALUE
	ld	c,1
.noise15_3
	endc
	add	b
	cp	CLAMP_VALUE
	jr	c,.noclamp
	ld	a,CLAMP_VALUE - 1
	jr	.noclamp
.minus
	add	b
	cp	CLAMP_VALUE
	jr	c,.noclamp
	xor	a
.noclamp
	if !def(DisableDeflehacks)
	ld	b,a
	ld	a,[CH\1Wave]
	or	c
	and	a
	jr	z,.noise15
	ld	a,CLAMP_VALUE
.noise15
	add	b
	endc
	if def(Visualizer)
	ld	[CH\1Noise],a
	endc
	ld	hl,NoiseTable
	add	l
	ld	l,a
	jr	nc,.nocarry2
	inc	h
.nocarry2
	if UseFXHammer
	ld	a,[FXHammer_SFXCH\1]
	cp	3
	jr	z,.updateVolume
	endc
	ld	a,[hl+]
	ldh	[rNR\13],a
endc

	; update volume
.updateVolume
	ld	hl,CH\1Reset
	res	7,[hl]
	ld	hl,CH\1VolPtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
if \1 != 3
	ld	a,[CH\1VolLoop]
	inc	a	; ended
	jp	z,.done
endc
	ld	a,[CH\1VolPos]
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
if !def(DemoSceneMode)
	if !def(DisableZombieMode) || (\1 == 3)
	ld	a,[CH\1ChanVol]
	push	hl
	call	MultiplyVolume
	pop	hl
	endc
	if !def(DisableZombieMode) && (\1 != 3)
	ld	a,[CH\1VolLoop]
	dec	a
	jr	z,.zombieatpos0
	ld	a,[CH\1VolPos]
	and	a
	jr	z,.zombinit
.zombieatpos0
	endc
endc
	ld	a,[CH\1Vol]
	sub	b
	jr	z,.noreset3
if \1 != 3
	if !def(DemoSceneMode) && !def(DisableZombieMode)
	or ~$0f
	ld	c,a
	ld	a,b
	ld	[CH\1Vol],a
		if def(Visualizer)
	ld	[CH\1OutputLevel],a
		endc
	ld	a,8
.zombloop
	ldh	[rNR\12],a
	inc	c
	jr	nz,.zombloop
	jr	.noreset3
.zombinit
	endc
	ld	a,b
	ld	[CH\1Vol],a
	if def(Visualizer)
	ld	[CH\1OutputLevel],a
	endc
	swap	a
	or	8
	ldh	[rNR\12],a
	if def(Visualizer) && (\1 != 3)
	xor	a
	ld	[CH\1TempEnvelope],a
	endc
	ld	a,d
	or	$80
	ldh	[rNR\14],a
.noreset3
else
	ld	a,b
	ld	[CH\1Vol],a
	if def(DemoSceneMode) || def(NoWaveVolumeScaling)
	and	a
	jr	z,.skip
	cp	8
	ld	b,%00100000
	jr	nc,.skip
	cp	4
	ld	b,%01000000
	jr	nc,.skip
	ld	b,%01100000
.skip
	ld	a,[CH\1ComputedVol]
	cp	b
	jr	z,.noreset3
	ld	a,b
	ld	[CH\1ComputedVol],a
	ld	[rNR\12],a
	ld	a,d
	or	$80
	ldh	[rNR\14],a
.noreset3
	else
	ld	a,1
.noreset3
	ld	[WaveBufUpdateFlag],a
	endc
endc
	ld	a,[CH\1VolPos]
	inc	a
	ld	[CH\1VolPos],a
	ld	a,[hl+]
	cp	$fe
	jr	nz,.done
	ld	a,[hl]
	ld	[CH\1VolPos],a
if \1 != 3
	if !def(DemoSceneMode) && !def(DisableZombieMode)
	ld	a,1
	ld	[CH\1VolLoop],a
	endc
	jr	.done
.loadlast
	ld	a,[hl]
	if !def(DemoSceneMode) && !def(DisableZombieMode)
	push	af
	swap	a
	and	$f
	ld	b,a
	ld	a,[CH\1ChanVol]
	call	MultiplyVolume
	swap	b
	pop	af
	and	$f
	or	b
	endc
	ldh	[rNR\12],a
	if def(Visualizer)
	ld	b,a
	and	$f
	ld	[CH\1TempEnvelope],a
	and	$7
	inc	a
	ld	[CH\1EnvelopeCounter],a
	ld	a,b
	swap	a
	and	$f
	ld	[CH\1OutputLevel],a
	endc
	ld	a,d
	or	$80
	ldh	[rNR\14],a
	ld	a,$ff
	ld	[CH\1VolLoop],a
else
.loadlast
endc

.done

if \1 == 3
	; Update wave
	ld	hl,CH\1WavePtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[CH\1WavePos]
	add	l
	ld	l,a
	jr	nc,.nocarry2
	inc	h
.nocarry2
	ld	a,[hl+]
	cp	$ff					; table end?
	jr	z,.updatebuffer
	ld	b,a
	ld	a,[CH\1Wave]
	cp	b
	if def(DemoSceneMode) || def(NoWaveVolumeScaling)
	jr	z,.noreset2
	ld	a,b
	ld	[CH\1Wave],a
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
	ldh	[rNR\34],a
.noreset2
	else
	ld	c,0
	jr	z,.noreset2
	ld	a,b
	ld	[CH\1Wave],a
	ld	c,1
.noreset2
	ld	a,[WaveBufUpdateFlag]
	or	c
	ld	[WaveBufUpdateFlag],a
	endc
	ld	a,[CH\1WavePos]
	inc	a
	ld	[CH\1WavePos],a
	ld	a,[hl+]
	cp	$fe
	jr	nz,.updatebuffer
	ld	a,[hl]
	ld	[CH\1WavePos],a

.updatebuffer
	if !def(DemoSceneMode)
	call	DoPWM
	call	DoRandomizer
		if !def(NoWaveVolumeScaling)
	ld	a,[WaveBufUpdateFlag]
	and	a
	jp	z,.noupdate
	ld	a,[CH\1Wave]
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
	ld	a,[CH\1Vol]
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
	ld	[CH\1ComputedVol],a
	ld	[rNR\12],a
	and	a
	call	nz,LoadWave
	xor	a
	ld	[WaveBufUpdateFlag],a
	ld	a,d
	or	$80
	ldh	[rNR\14],a
.noupdate
		endc
	endc
endc

CH\1RegistersUpdated:

endm

CH1_UpdateRegisters:
	UpdateRegisters 1

CH2_UpdateRegisters:
	UpdateRegisters 2

CH3_UpdateRegisters:
	UpdateRegisters 3

CH4_UpdateRegisters:
	UpdateRegisters 4

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
elif def(Visualizer)
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
	ldh	a,[rNR51]
	ld	c,a
	and	%10111011		; Remove CH3 from final mixing while it's disabled
	ldh	[rNR51],a		; prevents spike on GBA
	xor	a
	ldh	[rNR30],a		; disable CH3
CUR_WAVE = _AUD3WAVERAM
rept 16
	ld a, [hl+]			; get byte from hl
	ldh [CUR_WAVE], a	; copy to wave ram
CUR_WAVE = CUR_WAVE + 1
endr
PURGE CUR_WAVE
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
	ld	[hl+],a
	dec	b
	jr	nz,.loop
	ret

if !def(DemoSceneMode)

; Combine two waves.
; INPUT: bc = first wave address
;		 de = second wave address

_CombineWaves:
	ld hl,WaveBuffer
.loop
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
	ld	a,l
	cp	LOW(WaveBuffer+16)
	jr	nz, .loop
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
	; Fall through

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
	ret	nz
	ld	a,[PWMSpeed]
	ld	[PWMTimer],a
	ld	a,[PWMDir]
	and	a
	ld	a,[WavePos]
	jr	nz,.decPos
.incPos
	inc	a
	ld	[WavePos],a
	cp	$1e
	jr	nz,.continue
	ld	a,[PWMDir]
	xor	1
	ld	[PWMDir],a
	jr	.continue
.decPos
	dec	a
	ld	[WavePos],a
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
	jr	nc,.even
.odd
	ld	a,[hl]
	ld	b,a
	ld	a,[PWMVol]
	or	b
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
.even
	ld	a,[PWMVol]
	swap	a
	jr	.done
.odd2
	xor	a
.done
	ld	[hl],a
	ld	a,[WaveBufUpdateFlag]
	or	1
	ld	[WaveBufUpdateFlag],a
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
	ld	[hl+],a
	dec	b
	jr	nz,.loop
	ret

DoArp:
	ld	de,arp_Buffer
	xor a
	ld [de], a
	inc de
	ld	a,[hl+]
	and	a
	jr	nz,.slow
.fast
	ld	a,[hl]
	swap	a
	and	$f
	ld	[de],a
	inc	de
	ld	a,[hl+]
	and	$f
	jr .continue
.slow
	xor a
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
.continue
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
