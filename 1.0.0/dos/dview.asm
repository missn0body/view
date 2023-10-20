%define NEWLINE	13, 10
%define ENDL 13, 10, '$'

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
	cmp	[81H + 1], byte 45	; is the argv[1][0] a '-'?
	je	argsParse
	mov	ah, 3DH			; then argv[1] must be a filename. set mode to open file
	mov	al, 0			; set to read-only mode
	lea	dx, [81H + 1]		; args is filename to open
	int	21H
	jnc	validOpen		; carry flag is set if there is an error
	lea	dx, [errorPre]		; there must be an error if we've reached here
	call	puts
	lea	dx, [errorMes3]
	call	puts
	call	_end

validOpen:
	mov	bx, ax			; set file handle to read from, the one we just got
	mov	cx, bufsize		; set number of bytes to read
	mov	dx, buf			; set block of data to put file in
	push	ax			; save file handle for later
	mov	ah, 3FH			; we want to read our file now
	int	21H
	jnc	validRead		; carry flag is set if failure on read
	lea	dx, [errorPre]		; past here, we must have gotten an error
	call	puts
	lea	dx, [errorMes4]
	call	puts
	call	_end

validRead:
	xor	bx, bx
	mov	byte [bx + buf], '$'	; set end of buffer block with dollar sign
	mov	dx, buf
	call	puts			; print contents of buffer
	mov	ah, 3EH			; set mode to close file
	pop	bx			; recall file handle
	int	21H
	call	_end			; done!

noArgs:
	lea	dx, [errorPre]
	call	puts
	lea	dx, [errorMes2]
	call	puts
	call	_end

argsParse:
	cmp     [81H + 2], byte 104	; is it equal to 'h'?
        je      useMes			; then show usage
        cmp     [81H + 2], byte 118	; is it equal to 'v'?
	je	verMes
	lea	dx, [errorPre]		; we don't know argument
	call	puts
	lea	dx, [errorMes1]
	call	puts
	jmp	useMes			; make sure the user knows
	call	_end			; how to use the program

; displays name, version and usage information
useMes:
	lea	dx, [fileName]
        call    puts
        lea     dx, [usage]
        call    puts
        lea     dx, [flagsEx]
        call    puts
        call    _end

verMes:
	lea     dx, [fileName]
        call    puts
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

	fileName:       db 'Terminal File VIEWer '
        version:        db '(v. 1.0.0): '
        signature:      db 'a barebones assembly schtick by anson.', ENDL
        usage:          db 'Usage: view <file> <-h> <-v>', ENDL
        flagsEx:        db 09H, '<-h> : display help', NEWLINE, 09H, '<-v> : set verbose mode', ENDL

	errorMes1:      db 'unknown argument', ENDL
        errorMes2:      db 'not enough arguments', ENDL
        errorMes3:      db 'file could not be open', ENDL
        errorMes4:      db 'file could not be read', ENDL

	bufsize		equ 8192

section .bss:
	buf		resb 8192
