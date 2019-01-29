SECTION "GBS Header", ROM0[$3f90]
	db	"GBS"											; signature
	db	1												; version
	db	(SongPointerTable_End-SongPointerTable)/2		; number of songs
	db	1												; first song
	dw	$4000											; load address
	dw	DS_Init											; init address
	dw	DS_Play											; play address
	dw	$fffe											; stack pointer
if EngineSpeed == -1
	db	0												; rTMA
	db	0												; rTAC (both 0 = VBlank)
else
	db	EngineSpeed										; rTMA
	db	TACF_START + TACF_4KHZ							; rTAC
endc
GBS_TitleText:
	db "DevSound Demo"
rept GBS_TitleText - @ + 32
	db	0												; if ds is used, $ff will be filled instead 
endr
GBS_AuthorText:
	db "DevEd"
rept GBS_AuthorText - @ + 32
	db	0
endr
GBS_CopyrightText:
	db "2017 DevEd"
rept GBS_CopyrightText - @ + 32
	db	0
endr
