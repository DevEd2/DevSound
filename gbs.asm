GBS = 1

SECTION "GBS Header", ROM0[$f90]
	db	"GBS"		;signature
	db	1			;version
	db	NUM_MUSIC	;number of songs
	db	1			;first song
	dw	$1000		;load address
	dw	DS_Init		;init address
	dw	DS_Play		;play address
	dw	$fffe		;stack pointer
	db	0			;rTMA
	db	0			;rTAC (both 0 = VBlank)
GBS_TitleText:
	db "DevSound Demo"
	ds GBS_TitleText - @ + 32
GBS_AuthorText:
	db "DevEd"
	ds GBS_AuthorText - @ + 32
GBS_CopyrightText:
	db "2017 DevEd"
	ds GBS_CopyrightText - @ + 32
