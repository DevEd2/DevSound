; ================================================================
; Constants
; ================================================================

if !def(incConsts)
incConsts	set	1

; ================================================================
; Global constants
; ================================================================

sys_DMG		equ	0
sys_GBP		equ	1
sys_SGB		equ	2
sys_SGB2	equ	3
sys_GBC		equ	4
sys_GBA		equ	5

btnA		equ	0
btnB		equ	1
btnSelect	equ	2
btnStart	equ	3
btnRight	equ	4
btnLeft		equ	5
btnUp		equ	6
btnDown		equ	7

; ================================================================
; Carillon Player-specific constants
; ================================================================

InitPlayer	equ	$4000
StartMusic	equ	$4003
StopMusic	equ	$4006
SelectSong	equ	$400c
UpdateMusic	equ	$4100

; ================================================================
; Project-specific constants
; ================================================================

endc