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