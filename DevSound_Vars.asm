; ================================================================
; DevSound variable definitions
; ================================================================

if !def(incDSVars)
incDSVars	set	1

SECTION	"DevSound variables",WRAM0

DSVarsStart:
FadeType				ds	1
InitVarsStart:
FadeTimer				ds	1
GlobalVolume			ds	1
GlobalSpeed1			ds	1
GlobalSpeed2			ds	1
GlobalTimer				ds	1
TickCount				ds	1
SyncTick				ds	1
SoundEnabled			ds	1

CH1Enabled				ds	1
CH2Enabled				ds	1
CH3Enabled				ds	1
CH4Enabled				ds	1

CH1IsResting			ds	1
CH2IsResting			ds	1
CH3IsResting			ds	1
CH4IsResting			ds	1

CH1Ptr					ds	2
CH1VolPtr				ds	2
CH1PulsePtr				ds	2
CH1ArpPtr				ds	2
CH1VibPtr				ds	2
CH1VolPos				ds	1
CH1VolLoop				ds	1
CH1PulsePos				ds	1
CH1ArpPos				ds	1
CH1VibPos				ds	1
CH1VibDelay				ds	1
CH1LoopPtr				ds	2
CH1RetPtr				ds	2
CH1LoopCount			ds	1
CH1Tick					ds	1
CH1Reset				ds	1
CH1Note					ds	1
CH1NoteBackup			ds	1
CH1Transpose			ds	1
CH1FreqOffset			ds	1
CH1TempFreq				ds	2
CH1PortaType			ds	1
CH1PortaSpeed			ds	1
CH1Vol					ds	1
CH1ChanVol				ds	1
CH1Pan					ds	1
CH1Sweep				ds	1
CH1NoteCount			ds	1
CH1InsMode				ds	1
CH1Ins1					ds	1
CH1Ins2					ds	1

CH2Ptr					ds	2
CH2VolPtr				ds	2
CH2PulsePtr				ds	2
CH2ArpPtr				ds	2
CH2VibPtr				ds	2
CH2VolPos				ds	1
CH2VolLoop				ds	1
CH2PulsePos				ds	1
CH2ArpPos				ds	1
CH2VibPos				ds	1
CH2VibDelay				ds	1
CH2LoopPtr				ds	2
CH2RetPtr				ds	2
CH2LoopCount			ds	1
CH2Tick					ds	1
CH2Reset				ds	1
CH2Note					ds	1
CH2NoteBackup			ds	1
CH2Transpose			ds	1
CH2FreqOffset			ds	1
CH2TempFreq				ds	2
CH2PortaType			ds	1
CH2PortaSpeed			ds	1
CH2Vol					ds	1
CH2ChanVol				ds	1
CH2Pan					ds	1
CH2NoteCount			ds	1
CH2InsMode				ds	1
CH2Ins1					ds	1
CH2Ins2					ds	1

CH3Ptr					ds	2
CH3VolPtr				ds	2
CH3WavePtr				ds	2
CH3ArpPtr				ds	2
CH3VibPtr				ds	2
CH3VolPos				ds	1
CH3WavePos				ds	1
CH3ArpPos				ds	1
CH3VibPos				ds	1
CH3VibDelay				ds	1
CH3LoopPtr				ds	2
CH3RetPtr				ds	2
CH3LoopCount			ds	1
CH3Tick					ds	1
CH3Reset				ds	1
CH3Note					ds	1
CH3NoteBackup			ds	1
CH3Transpose			ds	1
CH3FreqOffset			ds	1
CH3TempFreq				ds	2
CH3PortaType			ds	1
CH3PortaSpeed			ds	1
CH3Vol					ds	1
CH3ChanVol				ds	1
CH3ComputedVol			ds	1
CH3Wave					ds	1
CH3Pan					ds	1
CH3NoteCount			ds	1
CH3InsMode				ds	1
CH3Ins1					ds	1
CH3Ins2					ds	1

CH4Ptr					ds	2
CH4VolPtr				ds	2
if !def(DisableDeflehacks)
CH4WavePtr				ds	2
endc
CH4NoisePtr				ds	2
CH4VolPos				ds	1
CH4VolLoop				ds	1
if !def(DisableDeflehacks)
CH4WavePos				ds	1
endc
CH4NoisePos				ds	1
CH4LoopPtr				ds	2
CH4RetPtr				ds	2
CH4LoopCount			ds	1
CH4Mode					ds	1
CH4ModeBackup			ds	1
CH4Tick					ds	1
CH4Reset				ds	1
CH4Transpose			ds	1
CH4Vol					ds	1
CH4Wave					ds	1
CH4ChanVol				ds	1
CH4Pan					ds	1
CH4NoteCount			ds	1
CH4InsMode				ds	1
CH4Ins1					ds	1
CH4Ins2					ds	1

ComputedWaveBuffer		ds	16
WaveBuffer				ds	16
WavePos					ds	1
WaveBufUpdateFlag		ds	1
PWMEnabled				ds	1
PWMVol					ds	1
PWMSpeed				ds	1
PWMTimer				ds	1
PWMDir					ds	1
RandomizerEnabled		ds	1
RandomizerTimer			ds	1
RandomizerSpeed			ds	1

arp_Buffer				ds	8
DSVarsEnd

if	!def(SimpleEchoBuffer)
CH1DoEcho			ds	1
CH2DoEcho			ds	1
CH3DoEcho			ds	1
CH1EchoBuffer		ds	64
CH2EchoBuffer		ds	64
CH3EchoBuffer		ds	64
EchoPos				ds	1
CH1EchoDelay		ds	1
CH2EchoDelay		ds	1
CH3EchoDelay		ds	1
else
CH1DoEcho			ds	1
CH2DoEcho			ds	1
CH3DoEcho			ds	1
CH1EchoBuffer		ds	3
CH2EchoBuffer		ds	3
CH3EchoBuffer		ds	3
EchoPos				ds	1
endc

endc
