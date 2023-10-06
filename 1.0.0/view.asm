section .data

	fileName:	db 'Terminal File VIEWer '
	version: 	db '(v. 1.0.0): '
	signature:	db 'a barebones assembly schtick by anson.', 0Ah
	; calculate the lengths of both lines above
	firstLen	equ $ - fileName

	usage: 		db 'Usage: view <file> <-h> <-v>', 0Ah
	usageLen	equ $ - usage

	flagsEx:	db 09h, '<-h> : display help', 0Ah, 09h, '<-v> : set verbose mode', 0Ah
	flagsExLen	equ $ - flagsEx

	errorPrefix:	db 'error: ', 0
	statusPrefix:	db 'view: ', 0

	errorMes1	db 'file could not be open', 0Ah, 0


section .text
global _start

_start:

	mov	rsi, fileName
	xor	rdx, rdx	; ensure that rdx is set to zero
	mov	rdx, firstLen
	call 	write

	mov	rsi, usage
	mov	rdx, usageLen
	call	write
	mov	rsi, flagsEx
	mov	rdx, flagsExLen
	call 	write

	; exit
	mov	rax, 60		; we want to execute exit()
	mov	rdi, 0		; exit code
	syscall

; short hand for printing a string of (rdx) length to stdout
; rdx = length of string
; rsi = address of string
write:
	mov	rax, 1
	mov	rdi, 1
	syscall
	ret
