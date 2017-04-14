; ================================================================
; Song data
; TODO: Separate this data to its own file so users don't have to
; scroll through this entire file
; ================================================================
	
; =================================================================
; Song speed table
; =================================================================

SongSpeedTable:
	db	4,3			; triumph
	db	4,3			; insert title here (NOTE: Actual song name.)
	db	6,6			; gadunk
	

	
SongPointerTable:
	dw	PT_Triumph
	dw	PT_InsertTitleHere
	dw	PT_Gadunk
	
; =================================================================
; Volume sequences
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

vol_Gadunk: 		db	15,5,10,5,2,6,10,15,12,6,10,7,8,9,10,15,4,3,2,1,$8f,0
vol_Arp:			db	8,8,8,7,7,7,6,6,6,5,5,5,4,4,4,4,3,3,3,3,3,2,2,2,2,2,2,1,1,1,1,1,1,1,1,0,$ff
vol_OctArp:			db	12,11,10,9,9,8,8,8,7,7,6,6,7,7,6,6,5,5,5,5,5,5,4,4,4,4,4,4,4,3,3,3,3,3,3,2,2,2,2,2,2,1,1,1,1,1,1,0,$ff
vol_HWEnvTest:		db	$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$77,$ff
vol_Bass1:			db	w3,$ff
vol_Bass2:			db	w3,w3,w3,w3,w1,$ff
vol_Bass3:			db	w3,w3,w3,w3,w3,w3,w3,w2,w2,w2,w2,w1,$ff
vol_PulseBass:		db	15,15,14,14,13,13,12,12,11,11,10,10,9,9,8,8,8,7,7,7,6,6,6,5,5,5,4,4,4,4,3,3,3,3,2,2,2,2,2,1,1,1,1,1,1,0,$ff
vol_Tom:			db	$1f,$ff
vol_WaveLeadShort:	db	w3,w3,w3,w3,w2,$ff
vol_WaveLeadMed:	db	w3,w3,w3,w3,w3,w3,w3,w2,$ff
vol_WaveLeadLong:	db	w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w2,$ff
vol_WaveLeadLong2:	db	w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w2,w2,w2,w2,w2,w2,w2,w2,w2,w2,w2,w2,w2,w2,w1,$ff
vol_Arp2:			db	$2f,$ff

vol_Kick:		db	$18,$ff
vol_Snare:		db	$1d,$ff
vol_OHH:		db	$48,$ff
vol_CymbQ:		db	$6a,$ff
vol_CymbL:		db	$3f,$ff

; =================================================================
; Arpeggio sequences
; =================================================================

arp_Gadunk: 	db	20,22,19,14,20,5,0,15,20,$ff
arp_Pluck059:	db	19,0,5,5,9,9,0,$80,1
arp_Pluck047:	db	19,0,4,4,7,7,0,$80,1
arp_Octave:		db	0,19,12,12,0,0,0,0,12,$80,2
arp_Pluck:		db	12,0,$ff
arp_037:		db	0,0,3,3,7,7,$80,0
arp_038:		db	0,0,3,3,8,8,$80,0
arp_Tom:		db	22,20,18,16,14,12,10,9,7,6,4,3,2,1,0,$ff

; =================================================================
; Noise sequences
; =================================================================

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
; Pulse sequences
; =================================================================

pulse_Dummy:	db	0,$ff
pulse_Arp:		db	2,2,2,1,1,1,0,0,0,3,3,3,$80,0
pulse_OctArp:	db	2,2,2,1,1,2,$ff

pulse_Bass:		db	1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,0,0,0,0,0,0,$80,0
pulse_Square:	db	2,$ff
pulse_Arp2:		db	0,0,0,1,1,1,2,2,2,3,3,3,2,2,2,1,1,1,$80,00

; =================================================================
; Vibrato sequences
; =================================================================
	
vib_Dummy
	dw	0,$80,$00

; =================================================================
; Wave sequences
; =================================================================

WaveTable:
	dw	wave_Bass
	dw	DefaultWave
	dw	wave_PulseLead
	
wave_Bass:		db	$00,$01,$11,$11,$22,$11,$00,$02,$57,$76,$7a,$cc,$ee,$fc,$b1,$23
wave_PulseLead:	db	$ff,$ff,$ff,$ff,$ff,$f0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

waveseq_Bass:		db	0,$ff
waveseq_Tri:		db	1,$ff
waveseq_PulseLead:	db	2,$ff

; =================================================================
; Instruments
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
	
	dw	ins_Kick
	dw	ins_Snare
	dw	ins_CHH
	dw	ins_OHH
	dw	ins_CymbQ
	dw	ins_CymbL
	
	dw	ins_PulseBass
	dw	ins_Tom
	dw	ins_Arp037
	dw	ins_Arp038
	dw	ins_WaveLeadShort
	dw	ins_WaveLeadMed
	dw	ins_WaveLeadLong
	dw	ins_WaveLeadLong2

; Instrument format: [no reset flag],[wave mode (ch3 only)],[voltable id],[arptable id],[pulsetable/wavetable id],[vibtable id]
; note that wave mode must be 0 for non-wave instruments
; !!! REMEMBER TO ADD INSTRUMENTS TO THE INSTRUMENT POINTER TABLE !!!
ins_Gadunk:			Instrument	0,0,vol_Gadunk,arp_Gadunk,pulse_Dummy,vib_Dummy
ins_Arp1:			Instrument	0,0,vol_Arp,arp_Pluck059,pulse_Arp,vib_Dummy
ins_Arp2:			Instrument	0,0,vol_Arp,arp_Pluck047,pulse_Arp,vib_Dummy
ins_OctArp:			Instrument	0,0,vol_OctArp,arp_Octave,pulse_OctArp,vib_Dummy
ins_Bass1:			Instrument	0,0,vol_Bass1,arp_Pluck,waveseq_Bass,vib_Dummy
ins_Bass2:			Instrument	0,0,vol_Bass2,arp_Pluck,waveseq_Bass,vib_Dummy
ins_Bass3:			Instrument	0,0,vol_Bass3,arp_Pluck,waveseq_Bass,vib_Dummy
ins_GadunkWave:		Instrument	0,0,vol_Bass1,arp_Gadunk,waveseq_Tri,vib_Dummy
ins_Kick:			Instrument	0,0,vol_Kick,noiseseq_Kick,DummyTable,DummyTable	; pulse/waveseq and vibrato unused by noise instruments
ins_Snare:			Instrument	0,0,vol_Snare,noiseseq_Snare,DummyTable,DummyTable
ins_CHH:			Instrument	0,0,vol_Kick,noiseseq_Hat,DummyTable,DummyTable
ins_OHH:			Instrument	0,0,vol_OHH,noiseseq_Hat,DummyTable,DummyTable
ins_CymbQ:			Instrument	0,0,vol_CymbQ,noiseseq_Hat,DummyTable,DummyTable
ins_CymbL:			Instrument	0,0,vol_CymbL,noiseseq_Hat,DummyTable,DummyTable

ins_PulseBass:		Instrument	0,0,vol_PulseBass,arp_Pluck,pulse_Bass,vib_Dummy
ins_Tom:			Instrument	0,0,vol_Tom,arp_Tom,pulse_Square,vib_Dummy
ins_Arp037:			Instrument	0,0,vol_Arp2,arp_037,pulse_Arp2,vib_Dummy
ins_Arp038:			Instrument	0,0,vol_Arp2,arp_038,pulse_Arp2,vib_Dummy

ins_WaveLeadShort:	Instrument	0,0,vol_WaveLeadShort,arp_Pluck,waveseq_PulseLead,vib_Dummy
ins_WaveLeadMed:	Instrument	0,0,vol_WaveLeadMed,arp_Pluck,waveseq_PulseLead,vib_Dummy
ins_WaveLeadLong:	Instrument	0,0,vol_WaveLeadLong,arp_Pluck,waveseq_PulseLead,vib_Dummy
ins_WaveLeadLong2:	Instrument	0,0,vol_WaveLeadLong2,arp_Pluck,waveseq_PulseLead,vib_Dummy

_ins_Gadunk			equ	0
_ins_Arp1			equ	1
_ins_Arp2			equ	2
_ins_OctArp			equ	3
_ins_Bass1			equ	4
_ins_Bass2			equ	5
_ins_Bass3			equ	6
_ins_GadunkWave		equ	7
_ins_Kick			equ	8
_ins_Snare			equ	9
_ins_CHH			equ	10
_ins_OHH			equ	11
_ins_CymbQ			equ	12
_ins_CymbL			equ	13
_ins_PulseBass		equ	14
_ins_Tom			equ	15
_ins_Arp037			equ	16
_ins_Arp038			equ	17
_ins_WaveLeadShort	equ	18
_ins_WaveLeadMed	equ	19
_ins_WaveLeadLong	equ	20
_ins_WaveLeadLong2	equ	21

Kick				equ	_ins_Kick
Snare				equ	_ins_Snare
CHH					equ	_ins_CHH
OHH					equ	_ins_OHH
CymbQ				equ	_ins_CymbQ
CymbL				equ	_ins_CymbL


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
	
PT_Triumph:
	dw	Triumph_CH1,Triumph_CH2,Triumph_CH3,Triumph_CH4
	
Triumph_CH1:
	db	SetInstrument,_ins_OctArp
	db	SetLoopPoint
	db	F_5,6,D#5,6,F_5,8,F_5,4,G#5,4,F_5,4,D#5,4,C#5,4,D#5,4,F_5,4,D#5,6,C#5,6,A#4,4
	db	C#5,20,A#4,4,C#5,4,D#5,4,F_5,6,F#5,6,F_5,4,C#5,8,D#5,8
	db	F_5,6,D#5,6,F_5,8,F_5,4,G#5,4,F_5,4,D#5,4,C#5,4,D#5,4,F_5,4,D#5,6,C#5,6,A#4,4
	db	C#5,20,C#5,4,D#5,4,C#5,4,A#5,6,B_5,6,A#5,4,F#5,8,G#5,8
	db	GotoLoopPoint
	db	EndChannel
	
Triumph_CH2:
	db	SetLoopPoint
	db	$80,1,G#4,6,G#4,6,G#4,12,G#4,4,G#4,4,$80,2,G#4,4,G#4,4,G#4,4,$80,1,G#4,4,$80,2,G#4,6,G#4,6,$80,1,G#4,4
	db	$80,2,B_4,6,B_4,6,B_4,12,$80,1,B_4,4,$80,2,B_4,4,F#4,4,F#4,4,F#4,4,$80,1,F#4,4,$80,2,F#4,6,$80,1,E_4,6,F#4,4
	db	$80,1,G#4,6,G#4,6,G#4,12,G#4,4,G#4,4,$80,2,G#4,4,G#4,4,G#4,4,$80,1,G#4,4,$80,2,G#4,6,G#4,6,$80,1,G#4,4
	db	$80,2,B_4,6,B_4,6,B_4,12,$80,1,B_4,4,$80,2,B_4,4,F#5,4,F#5,4,F#5,4,$80,1,F#5,4,$80,2,F#5,6,$80,1,E_5,6,F#5,4
	db	GotoLoopPoint
	db	EndChannel
	
Triumph_CH3:
	db	SetInstrument,4
	db	SetLoopPoint
	db	C#3,4,C#4,2,$80,5,C#3,2,$80,4,G#3,4,C#4,4,C#3,4,$80,6,C#4,4,$80,4,G#3,4,C#4,4
	db	G#2,4,G#3,2,$80,5,G#2,2,$80,4,D#3,4,G#3,4,G#2,4,$80,6,G#3,4,$80,4,G#2,4,A#2,4
	db	B_2,4,B_3,2,$80,5,B_2,2,$80,4,F#3,4,B_3,4,B_2,4,$80,6,B_3,4,$80,4,C#4,4,B_3,4
	db	F#2,4,F#3,2,$80,5,F#2,2,$80,4,C#3,4,F#3,4,F#2,4,$80,6,F#3,4,$80,4,B_2,4,B_3,4
	db	GotoLoopPoint
	db	EndChannel
	
Triumph_CH4:
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

PT_InsertTitleHere:
	dw	InsertTitleHere_CH1,InsertTitleHere_CH2,InsertTitleHere_CH3,InsertTitleHere_CH4
	
InsertTitleHere_CH1:	; TODO: Implement a way to optimize this, as it is it's a redundant mess.
	db	CallSection
	dw	.block0
	db	CallSection
	dw	.block0
	db	SetLoopPoint
	db	CallSection
	dw	.block0
	db	CallSection
	dw	.block0
	db	CallSection
	dw	.block0
	db	CallSection
	dw	.block0
	db	CallSection
	dw	.block1
	db	CallSection
	dw	.block1
	db	CallSection
	dw	.block1
	db	CallSection
	dw	.block1
	db	GotoLoopPoint
	db	EndChannel

.block0
	db	$80,14,E_2,6,$80,15,fix,4,$80,14,E_2,6,E_3,2,$80,15,fix,4,$80,14,E_3,2
	db	$80,14,C_2,6,$80,15,fix,4,$80,14,C_2,6,C_3,2,$80,15,fix,4,$80,14,C_3,2
	db	$80,14,G_2,6,$80,15,fix,4,$80,14,G_2,6,G_3,2,$80,15,fix,4,$80,14,G_3,2
	db	$80,14,D#2,6,$80,15,fix,4,$80,14,D#2,6,D#3,2,$80,15,fix,4,$80,14,D#3,2
	ret
.block1
	db	$80,14,F#2,6,$80,15,fix,4,$80,14,F#2,6,F#3,2,$80,15,fix,4,$80,14,F#3,2
	db	$80,14,D_2,6,$80,15,fix,4,$80,14,D_2,6,D_3,2,$80,15,fix,4,$80,14,B_2,2
	db	$80,14,A_2,6,$80,15,fix,4,$80,14,A_2,6,A_3,2,$80,15,fix,4,$80,14,A_3,2
	db	$80,14,F_2,6,$80,15,fix,4,$80,14,F_2,6,F_3,2,$80,15,fix,4,$80,14,C#3,2
	ret
	
InsertTitleHere_CH2:
	db	CallSection
	dw	.block0
	db	CallSection
	dw	.block0
	db	SetLoopPoint
	db	CallSection
	dw	.block0
	db	CallSection
	dw	.block0
	db	CallSection
	dw	.block0
	db	CallSection
	dw	.block0
	db	CallSection
	dw	.block1
	db	CallSection
	dw	.block1
	db	CallSection
	dw	.block1
	db	CallSection
	dw	.block1
	db	GotoLoopPoint
	db	EndChannel

.block0
	db	$80,16,E_4,10,E_4,8,E_4,6,$80,17,E_4,10,E_4,8,E_4,6
	db	B_3,10,B_3,8,B_3,6,D#4,10,D#4,8,D#4,6
	ret
.block1
	db	$80,16,F#4,10,F#4,8,F#4,6,$80,17,F#4,10,F#4,8,F#4,6
	db	C#4,10,C#4,8,C#4,6,F_4,10,F_4,8,F_4,6
	ret

; _ins_PulseBass		equ	14
; _ins_Tom				equ	15
; _ins_Arp037			equ	16
; _ins_Arp038			equ	17
; _ins_WaveLeadShort	equ	18
; _ins_WaveLeadMed		equ	19
; _ins_WaveLeadLong		equ	20
; _ins_WaveLeadLong2	equ	21

InsertTitleHere_CH3:
	db	rest,192
	db	SetLoopPoint
	db	$80,20,B_5,6,A_5,6,$80,19,G_5,4,$80,18,A_5,2,$80,19,G_5,4,$80,18,E_5,2
	db	$80,19,D_5,4,$80,18,E_5,2,$80,19,G_5,4,$80,21,D_5,12,$80,18,B_4,2
	db	$80,20,D_5,6,B_4,6,$80,19,D_5,4,$80,18,B_4,2,$80,19,D_5,4,$80,18,B_4,2
	db	$80,20,D#5,6,B_4,6,$80,19,D#5,4,$80,18,B_4,2,$80,19,A_4,4,$80,18,B_4,2
	db	$80,21,E_4,18,rest,78
	db	$80,20,B_5,6,A_5,6,$80,19,G_5,4,$80,18,A_5,2,$80,19,G_5,4,$80,18,E_5,2
	db	$80,19,B_5,4,$80,18,A_5,2,$80,19,G_5,4,$80,21,D_5,12,$80,18,E_5,2
	db	$80,20,G_5,6,E_5,6,$80,19,G_5,4,$80,20,A_5,6,$80,18,A#5,2
	db	$80,20,B_5,6,A_5,6,$80,19,D#5,4,$80,20,G_5,6,$80,18,D_5,2
	db	$80,21,E_5,18,rest,78
	db	CallSection
	dw	.block1
	db	rest,10
	db	$80,18,C#5,2,$80,19,E_5,4,$80,18,C#5,2,$80,19,E_5,4,$80,18,C#5,2,$80,19,B_4,4,$80,18,C#5,2
	db	CallSection
	dw	.block1
	db	rest,30
	db	GotoLoopPoint
	db	EndChannel

.block1
	db	$80,21,F#5,10,E_5,8,$80,20,C#5,6
	db	D_5,6,$80,19,E_5,4,$80,20,D_5,6,$80,18,A_4,2,$80,19,D_5,4,$80,18,E_5,2
	db	$80,21,A_5,10,F#5,8,$80,20,C#5,6
	db	$80,19,E_5,4,$80,18,F#5,2,$80,19,E_5,4,$80,18,F#5,2,$80,19,A_5,4,$80,18,F#5,2,$80,19,E_5,4,$80,18,C#5,2
	db	$80,21,F#5,10,E_5,8,$80,20,C#5,6
	db	A_5,6,$80,19,B_5,4,$80,20,A_5,6,$80,18,F#5,2,$80,19,E_5,4,$80,18,F#5,2
	db	$80,21,E_5,18
	ret
	
InsertTitleHere_CH4:
	db	SetLoopPoint
	Drum	Kick,4
	Drum	CHH,2
	Drum	Snare,4
	Drum	CHH,2
	Drum	Kick,4
	Drum	Kick,2
	Drum	Snare,4
	Drum	CHH,2
	db	GotoLoopPoint
	db	EndChannel