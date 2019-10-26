; ================================================================
; DevSound song data
; ================================================================

; =================================================================
; Song speed table
; =================================================================

SongSpeedTable:
	db	4,3			; triumph
	db	4,3			; insert title here (NOTE: Actual song name.)
	db	4,4			; vibrato test
;	db	2,2			; asterix egypt
	db	4,4			; flash title
	db	6,6			; RainbowDevs logo (porta test)
	db	6,6			; monty mode test
SongSpeedTable_End


SongPointerTable:
	dw	PT_Triumph
	dw	PT_InsertTitleHere
	dw	PT_EchoTest
;	dw	PT_Egypt
	dw	PT_FlashTitle
	dw	PT_RDLogo
	dw	PT_MontyTest
SongPointerTable_End

if(SongSpeedTable_End-SongSpeedTable) < (SongPointerTable_End-SongPointerTable)
	fail "SongSpeedTable does not have enough entries for SongPointerTable"
endc

if(SongSpeedTable_End-SongSpeedTable) > (SongPointerTable_End-SongPointerTable)
	warn "SongSpeedTable has extra entries"
endc

; =================================================================
; Volume sequences
; =================================================================

; For pulse and noise instruments, volume control is software-based by default.
; However, when the table execution ends ($FF) the value after that terminator
; will be loaded as a hardware volume and envelope. Please be cautious that the
; envelope speed won't be scaled along the channel volume.

; For wave instruments, volume has the same range as the above (that's right,
; this is possible by scaling the wave data) except that it won't load the
; value after the terminator as a final volume.
; WARNING: since there's no way to rewrite the wave data without restarting
; the wave so make sure that the volume doesn't change too fast that it
; unintentionally produces sync effect.
; NOTE: If the DisableWaveScaling flag is enabled, the above does not apply.
; Instead, there are four volume values (including 0). These values can be
; selected with w0-w3.

w0	equ	0
w1	equ	3
w2	equ	7
w3	equ	15

vol_Gadunk: 		db	15,5,10,5,2,6,10,15,12,6,10,7,8,9,10,15,4,3,2,1,$fe,0
vol_Arp:			db	8,8,8,7,7,7,6,6,6,5,5,5,4,4,4,4,3,3,3,3,3,2,2,2,2,2,2,1,1,1,1,1,1,1,1,0,$ff,0
vol_OctArp:			db	12,11,10,9,9,8,8,8,7,7,6,6,7,7,6,6,5,5,5,5,5,5,4,4,4,4,4,4,4,3,3,3,3,3,3,2,2,2,2,2,2,1,1,1,1,1,1,0,$ff,0
vol_Bass1:			db	w3,$ff
vol_Bass2:			db	w3,w3,w3,w3,w1,$ff
vol_Bass3:			db	w3,w3,w3,w3,w3,w3,w3,w2,w2,w2,w2,w1,$ff
vol_PulseBass:		db	15,15,14,14,13,13,12,12,11,11,10,10,9,9,8,8,8,7,7,7,6,6,6,5,5,5,4,4,4,4,3,3,3,3,2,2,2,2,2,1,1,1,1,1,1,0,$ff,0
vol_PulseBass2:		db	15,14,13,12,11,11,10,10,9,9,8,8,7,7,7,6,6,6,5,5,5,5,4,4,4,4,3,3,3,3,3,2,2,2,2,2,2,1,1,1,1,1,1,1,1,0,$ff,0

vol_Tom:			db	$ff,$f1
vol_Tom2:			db	$ff,$f3
vol_WaveLeadShort:	db	w3,w3,w3,w3,w2,$ff
vol_WaveLeadMed:	db	w3,w3,w3,w3,w3,w3,w3,w2,$ff
vol_WaveLeadLong:	db	w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w2,$ff
vol_WaveLeadLong2:	db	w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w3,w2,w2,w2,w2,w2,w2,w2,w2,w2,w2,w2,w2,w2,w2,w1,$ff
vol_Arp2:			db	$ff,$f2

vol_Kick:			db	$ff,$81
vol_Snare:			db	$ff,$d1
vol_OHH:			db	$ff,$84
vol_CymbQ:			db	$ff,$a6
vol_CymbL:			db	$ff,$f3

vol_Echo1:			db	12,$fd,3,$fe,2
vol_Echo2:			db	4,$fd,1,$fe,2
vol_c7:				db	$ff,$c7

vol_McAlbyKick:		db	15,15,13,9,7,5,$ff,$41
vol_McAlbyCHH:		db	8,6,4,$ff,$23
vol_McAlbyOHH:		db	10,6,3,$ff,$23
vol_McAlbySnare:	db	15,15,15,10,3,4,$ff,$53
vol_McAlbyCymb:		db	12,8,6,$ff,$54

vol_EgyptBass:		db	15,15,15,15,15,15,15,15,$51,$fe,$8

; =================================================================
; Arpeggio/Noise sequences
; =================================================================

s7	equ	$2d

; Noise values are the same as Deflemask, but with one exception:
; To convert 7-step noise values (noise mode 1 in deflemask) to a
; format usable by DevSound, take the corresponding value in the
; arpeggio macro and add s7.
; Example: db s7+128+32 = noise value 32 with step lengh 7
; Note that each noiseseq must be terminated with a loop command
; ($fe) otherwise the noise value will reset!

arp_Gadunk: 	db	20,22,19,14,20,5,0,15,20,$ff
arp_Pluck059:	db	19,0,5,5,9,9,0,$fe,1
arp_Pluck047:	db	19,0,4,4,7,7,0,$fe,1
arp_Octave:		db	0,19,12,12,0,0,0,0,12,$fe,2
arp_Pluck:		db	12,0,$ff
arp_Tom:		db	22,20,18,16,14,12,10,9,7,6,4,3,2,1,0,$ff

arp__017C:		db	12,12,7,7,1,1,0,0,$fe,0
arp__057C:		db	12,12,7,7,5,5,0,0,$fe,0
arp__950:		db	9,5,0,9,9,5,5,0,0,$fe,3
arp__740:		db	7,4,0,7,7,4,4,0,0,$fe,3
arp__830:		db	8,3,0,8,8,3,3,0,0,$fe,3

arp_Kick:	db	$a0,$9a,$a5,$fe,2
arp_Snare:	db	s7+$9d,s7+$97,s7+$94,$a3,$fe,3
arp_Hat:	db	$a9,$ab,$fe,1

arp_McAlbyKick:	db	$aa,$9c,$98,$94,$8c,$94,$9c,$fe,6
arp_McAlbySnare:	db	$9c,$98,$9c,$a0,$a4,$a8,$a8,$fe,6
arp_McAlbyHat:		db	$a8,$aa,$ac,$fe,2
arp_McAlbyCymb:	db	$a8,$aa,$a4,$fe,2

arp_RDLNoise:	db	$ac,$ac,$ac,$ac,$ac,$ab,$ab,$ab,$ab,$aa,$aa,$aa,$aa,$aa,$a8,$a8,$a8,$a8,$a4,$a4,$a4,$a4,$a4,$a0,$a0,$a0,$a0
				db	$98,$98,$98,$98,$98,$94,$94,$94,$94,$90,$90,$90,$90,$90,$8c,$8c,$8c,$8c,$88,$88,$88,$88,$88,$84,$84,$84,$84,$80,$fe,54

; =================================================================
; Pulse/Wave sequences
; =================================================================

WaveTable:
	dw	wave_Bass
	dw	DefaultWave
	dw	wave_PWMB
	dw	wave_PseudoSquare
	dw	wave_GSCWave3

wave_Bass:			db	$00,$01,$11,$11,$22,$11,$00,$02,$57,$76,$7a,$cc,$ee,$fc,$b1,$23
wave_PWMB:			db	$ff,$ff,$ff,$ff,$ff,$f0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
wave_PseudoSquare:	db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$44,$44,$00,$00,$00
wave_GSCWave3:		db	$02,$46,$8a,$cd,$ef,$fe,$de,$ff,$ee,$dc,$ba,$98,$76,$54,$32,$10

; use $c0 to use the wave buffer
waveseq_Bass_:		db	0,$ff
waveseq_Tri:		db	1,$ff
waveseq_PulseLead:	db	2,$ff
waveseq_Square_:	db	$c0,$ff
waveseq_GSCWave3:	db	4,$ff

waveseq_Arp:		db	2,2,2,1,1,1,0,0,0,3,3,3,$fe,0
waveseq_OctArp:		db	2,2,2,1,1,2,$ff

waveseq_Bass:		db	1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,0,0,0,0,0,0,$fe,0
waveseq_Square:		db	2,$ff
waveseq_Arp2:		db	0,0,0,0,1,1,1,2,2,2,2,3,3,3,2,2,2,2,1,1,1,$fe,00

waveseq_EchoTest:	db	1,$ff

; =================================================================
; Vibrato sequences
; Must be terminated with a loop command!
; =================================================================

vib_Test:	db	4,2,4,6,8,6,4,2,0,-2,-4,-6,-8,-6,-4,-2,0,$80,1
vib_Test2:	db	8,3,6,6,3,0,-3,-6,-6,-3,0,$80,1

; =================================================================
; Instruments
; =================================================================

InstrumentTable:
	const_def
	dins	Gadunk
	dins	Arp1
	dins	Arp2
	dins	OctArp
	dins	Bass1
	dins	Bass2
	dins	Bass3
	dins	GadunkWave

	dins	Kick
	dins	Snare
	dins	CHH
	dins	OHH
	dins	CymbQ
	dins	CymbL

	dins	PulseBass
	dins	Tom
	dins	Arp
	dins	WaveLeadShort
	dins	WaveLeadMed
	dins	WaveLeadLong
	dins	WaveLeadLong2

	dins	Echo1
	dins	Echo2

	dins	AKick
	dins	ASnare
	dins	ACHH
	dins	AOHH
	dins	ACymb

	dins	Tom2
	dins	PWM1
	dins	Arp017C
	dins	Arp057C
	dins	PulseBass2
	dins	Arp950
	dins	Arp740
	dins	Arp830

	dins	RDLPulse1
	dins	RDLPulse2
	dins	RDLWave
	dins	RDLNoise

	dins	EgyptBass1
	dins	EgyptBass2
	
	dins	MontyTest1
	dins	MontyTest2

; Instrument format: [no reset flag],[voltable id],[arptable id],[wavetable id],[vibtable id]
; _ for no table
; !!! REMEMBER TO ADD INSTRUMENTS TO THE INSTRUMENT POINTER TABLE !!!
ins_Gadunk:			Instrument	0,Gadunk,Gadunk,Bass_,_
ins_Arp1:			Instrument	0,Arp,Pluck059,Arp,_
ins_Arp2:			Instrument	0,Arp,Pluck047,Arp,_
ins_OctArp:			Instrument	0,OctArp,Octave,OctArp,_
ins_Bass1:			Instrument	0,Bass1,Pluck,Bass_,_
ins_Bass2:			Instrument	0,Bass2,Pluck,Bass_,_
ins_Bass3:			Instrument	0,Bass3,Pluck,Bass_,_
ins_GadunkWave:		Instrument	0,Bass1,Gadunk,Tri,_
ins_Kick:			Instrument	0,Kick,Kick,_,_
ins_Snare:			Instrument	0,Snare,Snare,_,_
ins_CHH:			Instrument	0,Kick,Hat,_,_
ins_OHH:			Instrument	0,OHH,Hat,_,_
ins_CymbQ:			Instrument	0,CymbQ,Hat,_,_
ins_CymbL:			Instrument	0,CymbL,Hat,_,_

ins_PulseBass:		Instrument	0,PulseBass,Pluck,Bass,_
ins_Tom:			Instrument	0,Tom,Tom,Square,_
ins_Arp:			Instrument	0,Arp2,Buffer,Arp2,_

ins_WaveLeadShort:	Instrument	0,WaveLeadShort,Pluck,PulseLead,_
ins_WaveLeadMed:	Instrument	0,WaveLeadMed,Pluck,PulseLead,_
ins_WaveLeadLong:	Instrument	0,WaveLeadLong,Pluck,PulseLead,_
ins_WaveLeadLong2:	Instrument	0,WaveLeadLong2,Pluck,PulseLead,_

ins_Echo1:			Instrument	0,Echo1,Pluck,EchoTest,Test
ins_Echo2:			Instrument	0,Echo2,Pluck,EchoTest,Test

ins_AKick:			Instrument	0,McAlbyKick,McAlbyKick,_,_
ins_ASnare:			Instrument	0,McAlbySnare,McAlbySnare,_,_
ins_ACHH:			Instrument	0,McAlbyCHH,McAlbyHat,_,_
ins_AOHH:			Instrument	0,McAlbyOHH,McAlbyHat,_,_
ins_ACymb:			Instrument	0,McAlbyCymb,McAlbyCymb,_,_

ins_Tom2:			Instrument	0,Tom2,Tom,Square,_
ins_PWM1:			Instrument	0,WaveLeadShort,Pluck,Square_,_
ins_Arp017C:		Instrument	0,PulseBass2,_017C,OctArp,_
ins_Arp057C:		Instrument	0,PulseBass2,_057C,OctArp,_
ins_PulseBass2:		Instrument	0,PulseBass2,Pluck,Bass,_
ins_Arp950:			Instrument	0,PulseBass2,_950,OctArp,_
ins_Arp740:			Instrument	0,PulseBass2,_740,OctArp,_
ins_Arp830:			Instrument	0,PulseBass2,_830,OctArp,_

ins_RDLPulse1:		Instrument	0,Echo1,_,Bass_,_
ins_RDLPulse2:		Instrument	0,c7,_,Bass_,_
ins_RDLWave:		Instrument	0,Bass1,_,GSCWave3,_
ins_RDLNoise:		Instrument	0,Echo1,RDLNoise,_,_

ins_EgyptBass1:		Instrument	0,EgyptBass,Pluck,PulseLead,_
ins_EgyptBass2:		Instrument	0,EgyptBass,Pluck,Bass_,_

ins_MontyTest1:		Instrument	0,Echo1,_,EchoTest,Test2
ins_MontyTest2:		Instrument	0,Echo1,_740,EchoTest,Test2

; =================================================================

PT_Triumph:	dw	Triumph_CH1,Triumph_CH2,Triumph_CH3,Triumph_CH4

Triumph_CH1:
	db	SetInstrument,id_OctArp
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
	dbw	SetChannelPtr,.block1
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
	dbw	SetChannelPtr,.block0
	db	EndChannel

; =================================================================

PT_InsertTitleHere:	dw	InsertTitleHere_CH1,InsertTitleHere_CH2,InsertTitleHere_CH3,InsertTitleHere_CH4

InsertTitleHere_CH1:
	dbw	CallSection,.block0
	dbw	CallSection,.block0
	db	SetLoopPoint
	db	SetRepeatPoint
	dbw	CallSection,.block0
	db	RepeatSection,4
	db	SetRepeatPoint
	dbw	CallSection,.block1
	db	RepeatSection,4
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
	db	SetInstrument,id_Arp
	dbw	CallSection,.block0
	dbw	CallSection,.block0
	db	SetLoopPoint
	db	SetRepeatPoint
	dbw	CallSection,.block0
	db	RepeatSection,4
	db	SetRepeatPoint
	dbw	CallSection,.block1
	db	RepeatSection,4
	db	GotoLoopPoint
	db	EndChannel

.block0
	db	Arp,1,$37
	db	E_4,10,E_4,8,E_4,6
	db	Arp,1,$38
	db	E_4,10,E_4,8,E_4,6
	db	B_3,10,B_3,8,B_3,6
	db	D#4,10,D#4,8,D#4,6
	ret
.block1
	db	Arp,1,$37
	db	F#4,10,F#4,8,F#4,6
	db	Arp,1,$38
	db	F#4,10,F#4,8,F#4,6
	db	C#4,10,C#4,8,C#4,6
	db	F_4,10,F_4,8,F_4,6
	ret

InsertTitleHere_CH3:
	db	rest,192
	db	SetLoopPoint
	db	$80,19,B_5,6,A_5,6,$80,18,G_5,4,$80,17,A_5,2,$80,18,G_5,4,$80,17,E_5,2
	db	$80,18,D_5,4,$80,17,E_5,2,$80,18,G_5,4,$80,20,D_5,12,$80,17,B_4,2
	db	$80,19,D_5,6,B_4,6,$80,18,D_5,4,$80,17,B_4,2,$80,18,D_5,4,$80,17,B_4,2
	db	$80,19,D#5,6,B_4,6,$80,18,D#5,4,$80,17,B_4,2,$80,18,A_4,4,$80,17,B_4,2
	db	$80,20,E_4,18,rest,78
	db	$80,19,B_5,6,A_5,6,$80,18,G_5,4,$80,17,A_5,2,$80,18,G_5,4,$80,17,E_5,2
	db	$80,18,B_5,4,$80,17,A_5,2,$80,18,G_5,4,$80,20,D_5,12,$80,17,E_5,2
	db	$80,19,G_5,6,E_5,6,$80,18,G_5,4,$80,19,A_5,6,$80,17,A#5,2
	db	$80,19,B_5,6,A_5,6,$80,18,D#5,4,$80,19,G_5,6,$80,17,D_5,2
	db	$80,20,E_5,18,rest,78
	dbw	CallSection,.block1
	db	rest,10
	db	$80,17,C#5,2,$80,18,E_5,4,$80,17,C#5,2,$80,18,E_5,4,$80,17,C#5,2,$80,18,B_4,4,$80,17,C#5,2
	dbw	CallSection,.block1
	db	rest,30
	db	GotoLoopPoint
	db	EndChannel

.block1
	db	$80,20,F#5,10,E_5,8,$80,19,C#5,6
	db	D_5,6,$80,18,E_5,4,$80,19,D_5,6,$80,17,A_4,2,$80,18,D_5,4,$80,17,E_5,2
	db	$80,20,A_5,10,F#5,8,$80,19,C#5,6
	db	$80,18,E_5,4,$80,17,F#5,2,$80,18,E_5,4,$80,17,F#5,2,$80,18,A_5,4,$80,17,F#5,2,$80,18,E_5,4,$80,17,C#5,2
	db	$80,20,F#5,10,E_5,8,$80,19,C#5,6
	db	A_5,6,$80,18,B_5,4,$80,19,A_5,6,$80,17,F#5,2,$80,18,E_5,4,$80,17,F#5,2
	db	$80,20,E_5,18
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

; =================================================================

PT_EchoTest:	dw	EchoTest_CH1,DummyChannel,DummyChannel,DummyChannel

EchoTest_CH1:
	db	SetInsAlternate,id_Echo1,id_Echo2
	db	SetEchoDelay,$18
	db	SetLoopPoint
	;db	SetPan,$11
	db	C_3,2,echo,2
	db	D_3,2,echo,2
	;db	SetPan,$01
	db	E_3,2,echo,2
	db	F_3,2,echo,2
	;db	SetPan,$11
	db	G_3,2,echo,2
	db	A_3,2,echo,2
	;db	SetPan,$10
	db	B_3,2,echo,2
	db	C_4,2,echo,2
	db	GotoLoopPoint

; =================================================================

PT_Egypt:	dw	Egypt_CH1,Egypt_CH2,Egypt_CH3,Egypt_CH4

Egypt_CH1:
;	db	SetLoopPoint
;	db	SetInsAlternate,id_EgyptBass1,id_EgyptBass2
;	dbw	CallSection,.block1
;	dbw	CallSection,.block1
;	dbw	CallSection,.block1
;	dbw	CallSection,.block2
;	dbw	CallSection,.block3
;	dbw	CallSection,.block3
;	dbw	CallSection,.block1
;	db	G#2,8,G#3,8,D#3,8,G#3,8
;	dbw	CallSection,.block3
;	dbw	CallSection,.block1
;	db	GotoLoopPoint
	db	EndChannel

;.block1
;	db	C_2,8,C_3,8,G_2,8,C_3,8
;	db	C_2,8,C_3,8,G_2,8,C_3,8
;	ret
;.block2
;	db	F_2,8,F_3,8,C_3,8,F_3,8
;	db	F_2,8,F_3,8,C_3,8,F_3,8
;	ret
;.block3
;	db	G_2,8,G_3,8,D_3,8,G_3,8
;	ret

Egypt_CH2:
	db	EndChannel

Egypt_CH3:
	db	EndChannel

Egypt_CH4:
	db	SetLoopPoint
	dbw	CallSection,.block0
	dbw	CallSection,.block0
	Drum	AKick,4
	Drum	ACHH,4
	Drum	ACHH,4
	Drum	ACHH,4
	Drum	ASnare,4
	Drum	ACHH,4
	Drum	AOHH,2
	Drum	AOHH,2
	Drum	ACHH,4
	Drum	AKick,4
	Drum	ACHH,4
	Drum	ACymb,4
	Drum	ACHH,4
	Drum	ASnare,4
	Drum	ACHH,4
	Drum	ACymb,4
	Drum	ACHH,4
	db	GotoLoopPoint
.block0
	Drum	AKick,4
	Drum	ACHH,4
	Drum	ACHH,4
	Drum	ACHH,4
	Drum	ASnare,4
	Drum	ACHH,4
	Drum	ACHH,4
	Drum	ACHH,4
	ret

; =================================================================

PT_FlashTitle:	dw	FlashTitle_CH1,FlashTitle_CH2,FlashTitle_CH3,FlashTitle_CH4

FlashTitle_CH1:
	db	SetLoopPoint
	dbw	CallSection,.block0
	dbw	CallSection,.block0
	dbw	CallSection,.block1
	db	GotoLoopPoint

.block0
	db	SetInstrument,id_PulseBass2
	db	A#2,4
	db	A#2,4
	Drum	Tom2,4
	db	SetInstrument,id_PulseBass2
	db	A#2,4
	db	A#2,4
	db	A#2,4
	Drum	Tom2,4
	db	SetInstrument,id_PulseBass2
	db	A#2,4
	db	A#2,2
	db	A#2,2
	db	A#2,4
	Drum	Tom2,4
	db	SetInstrument,id_PulseBass2
	db	A#2,4
	db	A#2,4
	db	A#2,4
	Drum	Tom2,4
	db	SetInstrument,id_PulseBass2
	db	A#2,4
	ret

.block1
	Drum	Tom2,4
	db	rest,2
	Drum	Tom2,4
	db	rest,2
	Drum	Tom2,4
	db	rest,2
	Drum	Tom2,4
	db	rest,2
	Drum	Tom2,2
	Drum	Tom2,2
	Drum	Tom2,2
	Drum	Tom2,2
	ret

FlashTitle_CH2:
	db	SetLoopPoint
	dbw	CallSection,.block0
	dbw	CallSection,.block0
	dbw	CallSection,.block1
	db	GotoLoopPoint
.block0
	db	SetInstrument,id_Arp017C
	db	A#4,4
	db	A#4,4
	db	A#4,4
	db	A#4,4
	db	A#4,4
	db	A#4,4
	db	A#4,4
	db	A#4,4
	db	SetInstrument,id_Arp057C
	db	A#4,4
	db	A#4,4
	db	A#4,4
	db	A#4,4
	db	A#4,4
	db	A#4,4
	db	A#4,4
	db	A#4,4
	ret
.block1
	db	SetInstrument,id_Arp950
	db	G#4,6
	db	SetInstrument,id_Arp740
	db	G#4,6
	db	SetInstrument,id_Arp950
	db	A#4,6
	db	G#4,6
	db	SetInstrument,id_Arp830
	db	F_4,4
	db	D#4,4
	ret
FlashTitle_CH3:
	db	EnablePWM,$f,7
	db	SetInstrument,id_PWM1
	db	SetLoopPoint
	dbw	CallSection,.block0
	dbw	CallSection,.block0
	dbw	CallSection,.block0
	dbw	CallSection,.block0
	dbw	CallSection,.block1
	dbw	CallSection,.block0
	dbw	CallSection,.block0
	dbw	CallSection,.block2
	dbw	CallSection,.block2
	dbw	CallSection,.block1
	db	GotoLoopPoint
	db	EndChannel
.block0
	db	A#5,2
	db	D#6,2
	db	F_6,2
	db	rest,2
	db	F_6,2
	db	A#5,2
	db	B_5,2
	db	F_6,2
	db	rest,2
	db	A#5,2
	db	B_5,2
	db	F_6,2
	db	A#5,4
	db	A#5,2
	db	rest,2
	ret
.block1
	db	F_6,6
	db	D#6,2
	db	rest,4
	db	G_6,6
	db	G#6,2
	db	rest,4
	db	C#6,4
	db	B_5,2
	db	C#6,1
	db	B_5,1
	ret
.block2
	db	A#6,2
	db	D#7,2
	db	F_7,2
	db	rest,2
	db	F_7,2
	db	A#6,2
	db	B_6,2
	db	F_7,2
	db	rest,2
	db	A#6,2
	db	B_6,2
	db	F_7,2
	db	A#6,4
	db	A#6,2
	db	rest,2
	ret

FlashTitle_CH4:
	db	SetLoopPoint
	dbw	CallSection,.block0
	dbw	CallSection,.block0
	dbw	CallSection,.block1
	db	GotoLoopPoint

.block0
	Drum	Kick,4
	Drum	OHH,4
	Drum	Snare,4
	Drum	Kick,4
	Drum	OHH,4
	Drum	Kick,4
	Drum	Snare,4
	Drum	Kick,4
	Drum	Kick,2
	Drum	Kick,2
	Drum	OHH,4
	Drum	Snare,4
	Drum	Kick,4
	Drum	CHH,4
	Drum	OHH,4
	Drum	Snare,4
	Drum	OHH,4
	ret

.block1
	Drum	Snare,6
	Drum	Snare,6
	Drum	Snare,6
	Drum	Snare,6
	Drum	Snare,2
	Drum	Snare,2
	Drum	Snare,2
	Drum	Snare,2
	ret

; =================================================================

PT_RDLogo:	dw	RDLogo_CH1,RDLogo_CH2,RDLogo_CH3,RDLogo_CH4

RDLogo_CH1:
	db	SetInstrument,id_RDLPulse1
	db	PitchBendDown,15
	db	D_4,16
	db	TonePorta,15
	db	A_3,16
	db	TonePorta,0
	db	SetInstrument,id_RDLPulse2
	db	A_3,16
	db	rest,1
	db	EndChannel

RDLogo_CH2:
	db	SetInstrument,id_RDLPulse1
	db	PitchBendDown,15
	db	A_3,16
	db	TonePorta,15
	db	D_3,16
	db	TonePorta,0
	db	SetInstrument,id_RDLPulse2
	db	D_3,16
	db	rest,1
	db	EndChannel

RDLogo_CH3:
	db	SetInstrument,id_RDLWave
	db	PitchBendDown,15
	db	D_4,16
	db	TonePorta,15
	db	D_3,32
	db	rest,1
	db	EndChannel

RDLogo_CH4:
	db	SetInstrument,id_RDLNoise
	db	fix,10,rest,1
	db	EndChannel

; =================================================================

PT_MontyTest:	dw	MontyTest_CH1,MontyTest_CH2,MontyTest_CH3,MontyTest_CH4

MontyTest_CH1:
	db	SetInstrument,id_MontyTest1
	db	SetMontyMode,1
	db	C_5,16
	db	PitchBendDown,1
	db	___,16
	db	rest,8
	
	db	EndChannel
	
MontyTest_CH2:
	db	SetInstrument,id_MontyTest1
	db	SetMontyMode,2
	db	rest,40
	db	Arp,1,$47
	db	G_4,16
	db	PitchBendUp,2
	db	___,16
	db	rest,8
	db	EndChannel
	
MontyTest_CH3:
	db	SetInstrument,id_PWM1
	db	SetMontyMode,4
	db	EnablePWM,$f,7
	db	rest,80
	db	C_6,16
	db	PitchBendDown,5
	db	___,16
	db	rest,8
	db	EndChannel
	
MontyTest_CH4:
	db	EndChannel