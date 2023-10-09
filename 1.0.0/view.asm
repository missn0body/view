	bits 64
	cpu x64

;=================================================
; File VIEWer, similar to 'cat'
; Made by anson, in fall of 2023
;=================================================

section .data

	fileName:	db 'Terminal File VIEWer '
	version: 	db '(v. 1.0.0): '
	signature:	db 'a barebones assembly schtick by anson.', 0Ah, 0

	usage: 		db 'Usage: view <file> <-h> <-v>', 0Ah, 0

	flagsEx:	db 09h, '<-h> : display help', 0Ah, 09h, '<-v> : set verbose mode', 0Ah, 0

	errorPrefix:	db 'error: ',
	statusPrefix:	db 'view: ',

	errorMes1	db 'file could not be open', 0Ah, 0

section .text
global _start

;=================================================
; _start
;=================================================

_start:
	pop	rbx
	cmp	rbx, 2
	jl	noArgs
	call 	exitSuccess

noArgs:
	call	use
	call	exitFailure

;=================================================
; subroutines specificaly for this program
;=================================================

; displays the usage of the program on request or on error
use:
	mov	rsi, fileName
	call	write
	mov	rsi, usage
	call	write
	mov	rsi, flagsEx
	call	write
        ret

;=================================================
; basic subroutines and shorthands
;=================================================

exitSuccess:
	mov	rax, 60
	mov	rdi, 0		; exit code
	syscall

exitFailure:
        mov     rax, 60
        mov     rdi, 1          ; exit code
        syscall

; short hand for printing a string of (rdx) length to stdout
; rdi = address of string
write:
	xor	rax, rax
	mov	rdi, rsi
	call	strlen
	mov	rdx, rax
	mov	rax, 1
	mov	rdi, 1
	syscall
	ret

; implementation of libc 'strlen'
; rdi = address of string
; rax = length of string
strlen:
	push	rcx
	xor	rcx, rcx

strlen_loop:
	cmp	[rdi], byte 0
	jz	strlen_exit
	inc	rcx
	inc	rdi
	jmp	strlen_loop

strlen_exit:
	mov	rax, rcx
	pop	rcx
	ret
