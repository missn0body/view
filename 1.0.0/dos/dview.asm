%define NEWLINE	13, 10

	bits 16
	cpu 8086
	org 100H

; A COM binary starts at 0x100, and expects code first.
section .text:
global _start

_start:
	xor	bx, bx			; ensure that offset register is zero
	mov	bl, [80H]		; load args byte counter into BL
	cmp	bl, 0			; do we have any arguments?
	je	noArgs
	cmp	bl, 7EH			; counter overflow; args higher than 127 bytes?
	ja	_end
	mov	byte [bx + 81H], '$'	; set end of args to dollar sign
	lea	dx, [81H]		; load address of args string
	call	puts			; print it
	call	_end

noArgs:
	lea	dx, [errorPre]
	call	puts
	lea	dx, [noArgsMes]
	call	puts
	call	_end

longArgs:
	lea     dx, [errorPre]
        call    puts
	lea	dx, [highArgsMes]
	call	puts
	call	_end

_end:
        mov     ax, 4C00H
        int     21H

; shorthand for printing strings
; dx: address of string
puts:
	mov	ah, 9			; we want to write a string
	int	21H			; address of string should be loaded
	xor	ah, ah
	ret

section .data:
	mesPre:		db 'view: $'
	errorPre:	db 'error: $'

	noArgsMes: 	db 'no args given', NEWLINE, '$'
	highArgsMes: 	db 'argument count higher than 127 bytes, aborting...', NEWLINE, '$'
