	bits 64
	cpu x64

;=================================================
; File VIEWer, similar to 'cat'
; Version 1.1.0
; Made by anson, in April 2024
;=================================================

%include "lib/io.asm"
%include "lib/defs.asm"

;=================================================
; MACROS BEGIN HERE
;=================================================

%macro	error 1
	push	rdi
	mov	rdi, errorPre
	call	puts
	mov	rdi, %1
	call	puts
	pop	rdi
%endmacro

%macro	error_r 1
	error	%1
	call	exitFailure
%endmacro

%macro	fastmov 1
	xor	%1, %1
	inc	%1
%endmacro

%macro	teststr	1
	mov	rsi, %1
	call	strcmp
	test	rax, rax
%endmacro

;=================================================
; MACROS END HERE
;=================================================

section .data

	; since our strlen() keeps looking until
	; we get a null byte, a single call to
	; our puts() will allow us to print the
	; next three strings

	fileName:       db 'Terminal File VIEWer '
	version:        db '(v. 1.1.0): '
	signature:      db 'a barebones assembly schtick.', 0Ah
			db 'created by anson <thesearethethingswesaw@gmail.com>', 0Ah, 0Ah, 0
	usage:          db 'Usage:', 0Ah, 09h, 'view (-h / --help)', 0Ah
			db 09h, 'view (-v / --version)', 0Ah
			db 09h, 'view [-x] <filename>', 0Ah
			db 09h, 'view -c <count> <filename>', 0Ah, 0Ah
			db 'Options:', 0Ah, 09h, '-c, --count', 09h, 'the amount of characters to display', 0Ah
			db 09h, '-x, --hex', 09h, 'displays a hex dump of the file', 0Ah, 0Ah, 0
	footer:		db 'this product refuses a license, see UNLICENSE for related details', 0Ah, 0

	errorPre:       db 'view: ', 0

	; error messages down below
	badArgsError:	db 'unknown argument', 0Ah, 0
	noArgsError:	db 'too few arguments, try "--help"', 0Ah, 0
	noOptError:	db 'no option argument', 0Ah, 0
	badOptError:	db 'option argument not a number', 0Ah, 0
	ignoreError:	db 'non-argument string ignored', 0Ah, 0
	badOpenError:	db 'file could not be open', 0Ah, 0
	badReadError:	db 'file could not be read', 0Ah, 0

	; long argument strings for testing
	helpString:	db 'help', 0
	versionString:	db 'version', 0
	countString:	db 'count', 0
	hexString:	db 'hex', 0

	nl:		db 0Ah, 0
	space:		db 20h, 0

	inbufsize	equ 1
	bufsize		equ 64

section .text
global _start

_start:
	xor	rbx, rbx	; reset rbx, itll count non-args
	pop	rcx		; pop off argc
	cmp	rcx, 2		; is it less than 2?
	jl	noArgs		; if so, no arguments, print error
	add	rsp, 8		; align stack and skip argv[0]

;=================================================
; ARGUMENT PARSING BEGINS HERE
;=================================================

argsLoop:
	pop	rdi		; grab the next argv[] on the stack
	test	rdi, rdi	; does it start with a null character?
	je	openFile	; if so, exit loop
	cmp	[rdi], byte '-'	; does the character begin with a hyphen?
	je	argsParse	; go for further processing
	inc	rbx		; increment count, for each non argument string
	cmp	rbx, 2
	jge	ignoreNonArgs	; if we've gotten more than two non-args, tell the user
	mov	[inFile], rdi	; otherwise the first non-arg is a filename, save it
	jmp	argsLoop	; keep checking for more args

argsParse:
	inc	rdi		; move the pointer up one
	cmp	[rdi], byte '-'	; long option?
	je	longArgsParse	; if so, move to different section
	cmp	[rdi], byte 0	; does the argument just end?
	je	argsLoop	; if so, continue back to loop

	; the character itself is in rdi

	cmp	[rdi], byte 'h'	; first, test 'h'
	je	printUsage
	cmp	[rdi], byte 'v'	; do we want to print version info?
	je	printVersion
	cmp	[rdi], byte 'c'	; test for 'c'
	je	countParse	; and jump ahead for further processing
	cmp	[rdi], byte 'x'
	je	sethex
	call	unknownArgs
	jmp	argsLoop

longArgsParse:
	inc	rdi		; move the pointer up one
	cmp	[rdi], byte '-'	; are there even more hyphens???
	je	argsLoop	; if so, trash it, go back
	cmp	[rdi], byte 0	; does the arg consist of just two hyphens?
	je	argsLoop

	; the string begins at rdi, and is already null-terminated
	; at least, it plays nice with this implementation of puts()

	teststr helpString	; does the argument equal 'help'?
	je	printUsage	; if so, jump to usage
	teststr	versionString	; does the argument equal 'version'?
	je	printVersion	; if so, jump to version
	teststr	countString	; does the argument equal 'count'?
	je	countParse	; if so, jump to further processing
	teststr	hexString	; does the argument equal 'hex'?
	je	sethex		; if so, jump to further processing
	call	unknownArgs	; if its not these, we don't know what it is
	jmp	argsLoop	; see if theres more arguments

countParse:
	pop	rdi		; get the next argument, this should be a number
	test	rdi, rdi	; is the argument non existant?
	je	noOpt
	call	atoi		; rdi already holds the option string
	test	rax, rax
	js	badOpt		; was the top bit of rax set? must be negative, invalid
	mov	[count], rax	; save count for later
	jmp	argsLoop

sethex:
	push	rdi		; save whatever was in rdi
	mov	rdi, wanthex	; load buffer
	mov	al, 't'		; load character
	stosb			; and add character to buffer
	pop	rdi		; restore rdi
	jmp	argsLoop	; continue on

printUsage:
	mov	rdi, fileName
	call	puts
	mov	rdi, usage
	call	puts
	mov	rdi, footer
	call	puts
	call	exitSuccess

printVersion:
	mov	rdi, fileName
	call	puts
	call	exitSuccess

; this subroutine does not exit the program but rather
; returns back to the calling point
unknownArgs:
	error	badArgsError
	ret

ignoreNonArgs:
	error	ignoreError
	jmp	argsLoop

noArgs: error_r noArgsError
noOpt:	error_r	noOptError
badOpt:	error_r	badOptError

;=================================================
; ARGUMENT PARSING ENDS HERE
;=================================================

openFile:
	mov	rax, 2		; we want to open
	mov	rdi, [inFile]
	xor	rsi, rsi
	xor	rdx, rdx
	syscall
	test	rax, rax	; did we get a bad handle?
	jle	badOpen		; if so, print error and exit
	mov	r10, rax	; save file handle
	mov	rsi, readbuf	; load in buffer
	mov	rbx, [count]	; move count into a register so we can compare
	test	rbx, rbx	; is there a value in this register?
	je	noCount		; if so, branch off

yesCount:
	xor	rax, rax	; we want to read from file now
	mov	rdi, r10
	mov	rsi, readbuf	; load in our buffer
	mov	rdx, rbx
	syscall
	cmp	rax, -1		; was there any sort of error?
	jle	badRead		; if so, error and exit
	fastmov	rax		; okay, now lets print...
	fastmov	rdi		; ...to stdout
	syscall
	call	closeFile

noCount:
	xor	rax, rax	; we want to read
	mov	rdi, r10	; load in file handle
	mov	rsi, readbuf	; load in buffer
	mov	rdx, inbufsize
	syscall
	cmp	rax, -1		; is it a bad read?
	jle	badRead		; if so, handle it
	cmp	rax, 0		; did we get nothing?
	jle	closeFile	; better close down then
	mov	rdx, rax	; save the amount we got
	cmp	[wanthex], byte 't'
	je	hexconv_nocount

regularprint:
	fastmov	rax		; we want to print...
	fastmov	rdi		; ...to stdout
	mov	rsi, readbuf	; print out the number that we read
	syscall
	jmp	writecheck	; and skip over the hex part

hexconv_nocount:
	inc	r12		; increment counter
	mov	rax, [readbuf]	; set what we read to convert
	mov	rdi, itoabuf	; set block to recieve return value
	call	itoa_16
	call	strlen
	mov	rdx, rax	; save return value into count for write
	fastmov	rax		; we want to write...
	fastmov	rdi		; ...to stdout
	mov	rsi, itoabuf	; the amount to print is already loaded
	syscall
	fastmov	rax		; reset the clobbered registers
	fastmov	rdx
	mov	rsi, space	; add a space between digits
	syscall
	cmp	r12, 10		; did we already print 10 numbers?
	jle	writecheck	; if not, continue as normal
	fastmov	rax		; we want to write...
	fastmov	rdi		; ...to stdout...
	fastmov	rdx		; ...but only one char
	mov	rsi, nl		; add a newline for easier reading
	syscall
	xor	r12, r12	; reset counter

writecheck:
	cmp	rax, 0
	jle	closeFile
	jmp	noCount

closeFile:
	mov	rdi, nl		; print new line
	call	puts
	mov	rax, 3		; we want to close the file
	mov	rdi, r10	; file handle is where we saved it
	syscall
	call	exitSuccess	; program end!

badOpen:error_r	badOpenError
badRead:error_r	badReadError

section .bss
	wanthex		resb 2
	inFile		resb bufsize
	count		resb bufsize
	itoabuf		resb bufsize
        readbuf		resb inbufsize
