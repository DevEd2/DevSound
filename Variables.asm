; ================================================================
; Variables
; ================================================================

if !def(incVars)
incVars	set	1

SECTION	"Variables",HRAM

; ================================================================
; Global variables
; ================================================================

VBACheck			ds	1	; variable used to determine if we're running in VBA
sys_btnHold			ds	1	; held buttons
sys_btnPress		ds	1	; pressed buttons
RasterTime			ds	1
if EngineSpeed != -1
VBlankOccurred		ds	1
endc


; ================================================================
; Project-specific variables
; ================================================================

; Insert project-specific variables here.

CurrentSong			ds	1

SECTION "Visualizer Variables",WRAM0[$c000]

if def(Visualizer)
Sprites:			ds  160
WaveDisplayBuffer	ds	64
VisualizerTempWave	ds	16
DepackedWaveDelta	ds	33
VisualizerVarsStart:
CH1Pulse			ds	1
CH2Pulse			ds	1
CH4Noise			ds	1
CH1ComputedFreq		ds	2
CH2ComputedFreq		ds	2
CH3ComputedFreq		ds	2
CH1PianoPos			ds	1
CH2PianoPos			ds	1
CH3PianoPos			ds	1
CH1OutputLevel		ds	1
CH2OutputLevel		ds	1
CH4OutputLevel		ds	1
CH1TempEnvelope		ds	1
CH2TempEnvelope		ds	1
CH4TempEnvelope		ds	1
CH1EnvelopeCounter	ds	1
CH2EnvelopeCounter	ds	1
CH4EnvelopeCounter	ds	1
EnvelopeTimer		ds	1
VisualizerVarsEnd:
RasterTimeChar		ds	2
SongIDChar			ds	3
endc
EmulatorCheck		ds	1

; ================================================================

SECTION "Temporary register storage space",HRAM

tempAF				ds	2
tempBC				ds	2
tempDE				ds	2
tempHL				ds	2
tempSP				ds	2
tempPC				ds	2
tempIF				ds	1
tempIE				ds	1
OAM_DMA				ds	10

endc
