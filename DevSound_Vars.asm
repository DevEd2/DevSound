; ================================================================
; SimpleSound variable definitions
; ================================================================

if !def(incDSVars)
incDSVars	set	1

SECTION	"DevSound varialbes",BSS

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
CH1Pos			ds	1
CH1VolPos		ds	1
CH1PulsePos		ds	1
CH1ArpPos		ds	1
CH1VibPos		ds	1
CH1VibDelay		ds	1
CH1LoopPos		ds	1
CH1RetPtr		ds	2
CH1RetPos		ds	1
CH1Tick			ds	1
CH1Reset		ds	1
CH1Note			ds	1
CH1Transpose	ds	1
CH1Sweep		ds	1

CH2Ptr			ds	2
CH2VolPtr		ds	2
CH2PulsePtr		ds	2
CH2ArpPtr		ds	2
CH2VibPtr		ds	2
CH2Pos			ds	1
CH2VolPos		ds	1
CH2PulsePos		ds	1
CH2ArpPos		ds	1
CH2VibPos		ds	1
CH2VibDelay		ds	1
CH2LoopPos		ds	1
CH2RetPtr		ds	2
CH2RetPos		ds	1
CH2Tick			ds	1
CH2Reset		ds	1
CH2Note			ds	1
CH2Transpose	ds	1

CH3Ptr			ds	2
CH3VolPtr		ds	2
CH3WavePtr		ds	2
CH3ArpPtr		ds	2
CH3VibPtr		ds	2
CH3Pos			ds	1
CH3VolPos		ds	1
CH3WavePos		ds	1
CH3ArpPos		ds	1
CH3VibPos		ds	1
CH3VibDelay		ds	1
CH3LoopPos		ds	1
CH3RetPtr		ds	2
CH3RetPos		ds	1
CH3Tick			ds	1
CH3Reset		ds	1
CH3Note			ds	1
CH3Transpose	ds	1
CH3Vol			ds	1
CH3Wave			ds	1
CH3Pan			ds	1
CH3Mode			ds	1

CH4Ptr			ds	2
CH4VolPtr		ds	2
CH4NoisePtr		ds	2
CH4Pos			ds	1
CH4VolPos		ds	1
CH4NoisePos		ds	1
CH4LoopPos		ds	1
CH4RetPtr		ds	2
CH4RetPos		ds	1
CH4Mode			ds	1
CH4Tick			ds	1
CH4Reset		ds	1
CH4Transpose	ds	1
CH4Pan			ds	1

DSVarsEnd

endc