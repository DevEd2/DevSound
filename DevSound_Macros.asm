; ================================================================
; SimpleSound constants
; ================================================================

if !def(incSSMacros)
incSSMacros	set	1

Instrument:		macro
	db	\1,\2
	dw	\3,\4,\5,\6
	endm

Drum:			macro
	db	SetInstrument,\1,fix,\2
	endm
	
endc