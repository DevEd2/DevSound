; ================================================================
; Variables
; ================================================================

if !def(incVars)
incVars	set	1

SECTION	"Variables",BSS

; ================================================================
; Global variables
; ================================================================

GBType				ds	1	; current Game Boy model
GBTestRun			ds	1	; flag set when GB type test is run
sys_btnHold			ds	1	; held buttons
sys_btnPress		ds	1	; pressed buttons
CurrentFrame		ds	1	; current frame

; ================================================================
; Project-specific variables
; ================================================================

; Insert project-specific variables here.

CurrentSong			ds	1

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
OAM_DMA				ds	8

endc