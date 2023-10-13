        bits 64
        cpu x64

;=================================================
; File VIEWer, similar to 'cat'
; Made by anson, in fall of 2023
;=================================================

section .data

        fileName:       db 'Terminal File VIEWer '
        version:        db '(v. 1.0.0): '
        signature:      db 'a barebones assembly schtick by anson.', 0Ah, 0
        usage:          db 'Usage: view <file> <-h> <-v>', 0Ah, 0
        flagsEx:        db 09h, '<-h> : display help', 0Ah, 09h, '<-v> : set verbose mode', 0Ah, 0

        errorPre:       db 'error: ', 0
        statusPre:      db 'view: ', 0

        errorMes1:      db 'unknown argument', 0Ah, 0
	errorMes2:	db 'not enough arguments', 0Ah, 0
        errorMes3:      db 'file could not be open', 0Ah, 0
        errorMes4:      db 'file could not be read', 0Ah, 0

        debug:          db 'debug, yayyy!', 0Ah, 0
	nl:		db 0Ah, 0

        bufsize		equ 8192

section .text
global _start

_start:
	pop	rcx		; get argc off the stack
	cmp	rcx, 2		; do we have more than 1 arg?
	jl	noArgs		; if not, display usage and exit
	add	rsp, 8		; skip argv[0]
	pop	rsi		; put argv[1] into rsi
	cmp	[rsi], byte 45	; is the first character a hyphen?
	je	argsParse	; parse it then
	mov	rdi, rsi	; otherwise it must be a filename
	mov	rsi, 0		; read only mode
	mov	rdx, 666o	; chmod value, read-only for everyone
	mov	rax, 2		; rax will hold our file handle
	syscall
	test	rax, rax	; is the fd <= 0? anything below is invalid
	jge	validOpen	; go to label for further processing
	mov	rsi, errorPre	; otherwise we got an error
	call	puts
	mov	rsi, errorMes3
	call	puts
	call	exitFailure

validOpen:
	mov	rdi, rax	; rax holds our file handle
	mov	rax, 0		; we want to read from file now
	mov	rsi, buf	; load our big ol buffer
	mov	rdx, bufsize	; size of our big ol buffer
	syscall
	cmp	rax, -1		; did we get an error?
	jg	validRead	; if not, go to further processing
	mov	rax, 3
	syscall			; close file
	mov	rsi, errorPre
	call	puts
	mov	rsi, errorMes4	; display error
	call	puts
	call	exitFailure

validRead:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, buf
	mov	rdx, bufsize
	syscall
	mov	rax, 3
	syscall			; close file
	call	exitSuccess

noArgs:
	mov	rsi, errorPre
	call	puts
	mov	rsi, errorMes2	; put the address of error message
	call	puts		; write it to string
	call	useMes		; and display usage
	call	exitFailure

argsParse:
	inc	rsi		; move pointer up to argv[1][1]
	cmp	[rsi], byte 104 ; is it equal to 'h'?
	je	useMes		; then show usage
	cmp	[rsi], byte 118 ; is it equal to 'v'?
	je	verMes		; then show version
	mov	rsi, errorPre	; unknown argument then
	call	puts
	mov	rsi, errorMes1
	call	puts
	call	useMes		; make sure user knows how to use program


; displays name and usage on exit or request
useMes:
	mov	rsi, fileName
	call	puts
	mov	rsi, usage
	call 	puts
	mov	rsi, flagsEx
	call	puts
	call	exitFailure

; displays version on request
verMes:
	mov	rsi, fileName
	call	puts
	call	exitFailure

; basic implementation of libc puts()
; NOTE, requires a null-terminated string
; rsi = address of null-terminated string
puts:
	push	rax
	push	rdx
	mov	rax, 1		; we want to write
	mov	rdi, rsi	; ready address for strlen()
	xor	rdx, rdx	; make sure our count is zero
	call	strlen
	mov	rdi, 1
	syscall			; rsi should already have address
	pop	rdx
	pop	rax
        ret

; implementation of libc strlen()
; rdx = length of string
; rdi = address of string
strlen:
	push 	rcx		; rcx will be our counter
	push	rsi		; and our temp buffer for address
	mov	rsi, rdi
	xor	rcx, rcx	; make sure that counter is zero

strlen_loop:
	cmp	[rsi], byte 0	; is it null?
	je	strlen_done	; if so, get out of loop
	inc	rcx		; increment counter
	inc	rsi		; and pointer
	jmp	strlen_loop

strlen_done:
	mov	rdx, rcx
	pop 	rsi
	pop 	rcx
	ret

; exit with return code 0
exitSuccess:
	mov	rax, 60
	mov	rdi, 0
	syscall

; exit with return code -1
exitFailure:
	mov	rax, 60
	mov	rdi, -1
	syscall


section .bss
	buf 		resb 8192
