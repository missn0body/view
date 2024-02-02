	bits 64
	cpu x64

;=================================================
; File VIEWer, similar to 'cat'
; Version 1.0.5
; Made by anson, in Feb 2024
;=================================================

section .data

	; since our strlen() keeps looking until
	; we get a null byte, a single call to
	; our puts() will allow us to print the
	; next three strings

	fileName:       db 'Terminal File VIEWer '
        version:        db '(v. 1.0.5): '
        signature:      db 'a barebones assembly schtick by anson.', 0Ah, 0
        usage:          db 'Usage: view (file) -h (--help) -v (--version)', 0Ah, 0

        errorPre:       db 'error: ', 0
        statusPre:      db 'view: ', 0

	; error messages down below
        badArgsError:	db 'unknown argument', 0Ah, 0
        noArgsError:	db 'too few arguments, try --help', 0Ah, 0
        badOpenError:	db 'file could not be open', 0Ah, 0
        badReadError:	db 'file could not be read', 0Ah, 0

	; simple debug message
        debug:          db 'debug, yayyy!', 0Ah, 0
        nl:             db 0Ah, 0

	ansiError:	db 1Bh, '[31m', 0
	ansiReset:	db 1Bh, '[0m', 0

        bufsize         equ 8192

section .text
global _start

_start:
	pop	rcx		; pop off argc
	cmp	rcx, 2		; is it less than 2?
	jl	noArgs		; if so, no arguments, print error
	add	rsp, 8		; align stack and skip argv[0]

argsLoop:
	pop	rdi		; grab the next argv[] on the stack
	cmp	rdi, byte 0	; does it start with a null character?
	je	argsEnd		; if so, exit loop
	cmp	[rdi], byte 45	; does the character begin with a hyphen?
	je	argsParse	; go for further processing
	jmp	argsLoop

argsParse:
	inc	rdi		; move the pointer up one
	cmp	[rdi], byte 45	; long option?
	je	longArgsParse	; if so, move to different section
	cmp	[rdi], byte 0	; does the argument just end?
	je	argsLoop	; if so, continue back to loop

	; essentially a debug statement below
	call	puts
	mov	rdi, nl
	call	puts
	jmp	argsLoop

longArgsParse:
	inc	rdi		; move the pointer up one
	cmp	[rdi], byte 45	; are there even more hyphens???
	je	argsLoop	; if so, trash it, go back

	; essentially a debug statement blow
	call	puts
	mov	rdi, nl
	call	puts
	jmp	argsLoop

argsEnd:
	call	exitSuccess

noArgs:
	mov	rdi, errorPre
	call	puts
	mov	rdi, noArgsError
	call	puts
	call	exitSuccess

; basic implementation of libc puts()
; NOTE, requires a null-terminated string
; rdi = address of null-terminated string
puts:
	xor	rax, rax	; make sure register is clear for length
	call	strlen		; rdi should already contain address
	mov	rdx, rax	; move the count given into its place
	mov	rsi, rdi	; ready the address for the write() call
	mov	rax, 1		; we want to write...
	mov	rdi, 1		; ... to stdout
	syscall
	ret

; implementation of libc strlen()
; rdi = address of string
; rax = length of string
strlen:
	lea	rax, [rdi + 1]	; load input, as well as incrementing

strlen_loop:
	mov	cl, byte [rax]	; and move the first character into the lowest part of rcx
	inc	rax		; increment length
	test	cl, cl		; is the current byte null?
	jnz	strlen_loop	; if not, keep repeating
	sub	rax, rdi
	ret

; implementation of libc strcmp()
; NOTE: requires null-terminated strings
; rsi = address of string
; rdi = address of string

; exit with return code 0
exitSuccess:
        mov     rax, 60
        mov     rdi, 0
        syscall

; exit with return code -1
exitFailure:
        mov     rax, 60
        mov     rdi, -1
        syscall

section .bss
        buf             resb 8192
