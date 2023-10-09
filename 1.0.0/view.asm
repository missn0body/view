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
	firstLen	equ $ - fileName

	usage: 		db 'Usage: view <file> <-h> <-v>', 0Ah, 0
	usageLen	equ $ - usage

	flagsEx:	db 09h, '<-h> : display help', 0Ah, 09h, '<-v> : set verbose mode', 0Ah, 0
	flagsExLen	equ $ - flagsEx

	errorPrefix:	db 'error: ',
	statusPrefix:	db 'view: ',

	errorMes1	db 'file could not be open', 0Ah, 0
	errMes1Len:	equ $ - errorMes1:


section .text
global _start

;=================================================
; _start
;=================================================

_start:
	call 	use
	call 	exitSuccess

;=================================================
; subroutines specificaly for this program
;=================================================

; displays the usage of the program on request or on error
use:
        mov     rsi, fileName
        xor     rdx, rdx        ; ensure that rdx is set to zero
        mov     rdx, firstLen
        call    write

        mov     rsi, usage
        mov     rdx, usageLen
        call    write
        mov     rsi, flagsEx
        mov     rdx, flagsExLen
        call    write
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
; rdx = length of string
; rsi = address of string
write:
	mov	rax, 1
	mov	rdi, 1
	syscall
	ret

; implementation of libc 'strlen'
; rdi = address of string
strlen:
	; TODO
	ret
