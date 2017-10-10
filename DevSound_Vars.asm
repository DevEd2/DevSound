; ================================================================
; DevSound variable definitions
; ================================================================

if !def(incDSVars)
incDSVars	set	1

SECTION	"DevSound variables",WRAM0

DSVarsStart

GlobalVolume	ds	1
GlobalSpeed1	ds	1
GlobalSpeed2	ds	1
GlobalTimer		ds	1
TickCount		ds	1
FadeTimer		ds	1
FadeType		ds	1
SoundEnabled	ds	1

CH1Enabled		ds	1
CH2Enabled		ds	1
CH3Enabled		ds	1
CH4Enabled		ds	1

CH1Ptr			ds	2
CH1VolPtr		ds	2
CH1PulsePtr		ds	2
CH1ArpPtr		ds	2
CH1VibPtr		ds	2
CH1VolPos		ds	1
CH1VolLoop		ds	1
CH1PulsePos		ds	1
CH1ArpPos		ds	1
CH1VibPos		ds	1
CH1VibDelay		ds	1
CH1LoopPtr		ds	2
CH1RetPtr		ds	2
CH1Tick			ds	1
CH1Reset		ds	1
CH1Note			ds	1
CH1Transpose	ds	1
CH1FreqOffset	ds	1
CH1Vol			ds	1
CH1Pan			ds	1
CH1Sweep		ds	1
CH1NoteCount	ds	1
CH1InsMode		ds	1
CH1Ins1			ds	1
CH1Ins2			ds	1

CH2Ptr			ds	2
CH2VolPtr		ds	2
CH2PulsePtr		ds	2
CH2ArpPtr		ds	2
CH2VibPtr		ds	2
CH2VolPos		ds	1
CH2VolLoop		ds	1
CH2PulsePos		ds	1
CH2ArpPos		ds	1
CH2VibPos		ds	1
CH2VibDelay		ds	1
CH2LoopPtr		ds	2
CH2RetPtr		ds	2
CH2Tick			ds	1
CH2Reset		ds	1
CH2Note			ds	1
CH2Transpose	ds	1
CH2FreqOffset	ds	1
CH2Vol			ds	1
CH2Pan			ds	1
CH2NoteCount	ds	1
CH2InsMode		ds	1
CH2Ins1			ds	1
CH2Ins2			ds	1

CH3Ptr			ds	2
CH3VolPtr		ds	2
CH3WavePtr		ds	2
CH3ArpPtr		ds	2
CH3VibPtr		ds	2
CH3VolPos		ds	1
CH3WavePos		ds	1
CH3ArpPos		ds	1
CH3VibPos		ds	1
CH3VibDelay		ds	1
CH3LoopPtr		ds	2
CH3RetPtr		ds	2
CH3Tick			ds	1
CH3Reset		ds	1
CH3Note			ds	1
CH3Transpose	ds	1
CH3FreqOffset	ds	1
CH3Vol			ds	1
CH3ComputedVol	ds	1
CH3Wave			ds	1
CH3Pan			ds	1
CH3NoteCount	ds	1
CH3InsMode		ds	1
CH3Ins1			ds	1
CH3Ins2			ds	1

CH4Ptr			ds	2
CH4VolPtr		ds	2
CH4NoisePtr		ds	2
CH4VolPos		ds	1
CH4VolLoop		ds	1
CH4NoisePos		ds	1
CH4LoopPtr		ds	2
CH4RetPtr		ds	2
CH4Mode			ds	1
CH4Tick			ds	1
CH4Reset		ds	1
CH4Transpose	ds	1
CH4Vol			ds	1
CH4Pan			ds	1
CH4NoteCount	ds	1
CH4InsMode		ds	1
CH4Ins1			ds	1
CH4Ins2			ds	1
DSVarsEnd

ComputedWaveBuffer	ds	16
WaveBuffer			ds	16
WavePos				ds	1
WaveBufUpdateFlag	ds	1
PWMEnabled			ds	1
PWMVol				ds	1
PWMSpeed			ds	1
PWMTimer			ds	1
PWMDir				ds	1
RandomizerEnabled	ds	1
RandomizerTimer		ds	1
RandomizerSpeed		ds	1

arp_Buffer			ds	8
endc
