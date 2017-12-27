; ================================================================
; Macros
; ================================================================

if	!def(incMacros)
incMacros	set	1

; ================================================================
; Global macros
; ================================================================

CopyBytes:				macro
	ld	hl,\1
	ld	de,\2
	ld	bc,\3
	call	_CopyBytes
	endm
	
; Copy a tileset to a specified VRAM address.
; USAGE: CopyTileset [tileset],[VRAM address],[number of tiles to copy]
; "tiles" refers to any tileset.
CopyTileset:	macro
	ld	bc,$10*\3		; number of tiles to copy
	ld	hl,\1			; address of tiles to copy
	ld	de,$8000+\2		; address to copy to
	call	_CopyBytes
	endm
	
; Copy a 1BPP tileset to a specified VRAM address.
; USAGE: CopyTileset1BPP [tileset],[VRAM address],[number of tiles to copy]
; "tiles" refers to any tileset.
CopyTileset1BPP:	macro
	ld	bc,$10*\3		; number of tiles to copy
	ld	hl,\1			; address of tiles to copy
	ld	de,$8000+\2		; address to copy to
	call	_CopyTileset1BPP
	endm

; ================================================================
; Project-specific macros
; ================================================================

; Insert project-specific macros here.


endc
