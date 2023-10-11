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

	errorPre:	db 'error: ', 0
	statusPre:	db 'view: ', 0

	errorMes1	db 'file could not be open', 0Ah, 0
	errorMes2	db 'unknown argument', 0Ah, 0

	debug:		db 'debug, yayyy!', 0Ah, 0

section .text
global _start

;=================================================
; _start
;=================================================

_start:
	pop	rbx		; pop argc
	cmp	rbx, 2		; is there more than 2?
	jl	noArgs		; call use if no args
	add	rsp, 8		; skip over argv[0]
	pop	rsp		; argv[1]
	cmp	[rsp], byte 45	; does it begin with "-"?
	je	argsParse	; if so, let's parse it
	call	fileSetup	; else, it must be a filename

argsParse:
	inc	rsp
	cmp	[rsp], byte 104	; h? (help)
	je	noArgs
	cmp	[rsp], byte 72	; uppercase h?
	je	noArgs
	cmp	[rsp], byte 118	; v? (version)
	je	ver
	cmp	[rsp], byte 86	; uppercase v?
	je	ver
	mov	rsi, errorPre
	call	write
	mov	rsi, errorMes2	; unknown argument then
	call	write
	call	use

fileSetup:
	mov	rsi, debug
	call	write
	call	exitSuccess

noArgs:
	call	use

; displays the usage of the program on request or on error
use:
	mov	rsi, fileName
	call	write
	mov	rsi, usage
	call	write
	mov	rsi, flagsEx
	call	write
        call	exitFailure

; displays name, version, and a small description on request
ver:
	mov	rsi, fileName
	call	write
	call	exitSuccess

;=================================================
; subroutines and shorthands
;=================================================

; exit subroutines. self-explanatory
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
