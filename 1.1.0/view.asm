	bits 64
	cpu x64

;=================================================
; File VIEWer, similar to 'cat'
; Version 1.1.0
; Made by anson, in April 2024
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

	mov	rsi, helpString 	; does the argument equal 'help'?
	call	strcmp
	test	rax, rax
	je	printUsage		; if so, jump to usage
	mov	rsi, versionString	; does the argument equal 'version'?
	call	strcmp
	test	rax, rax
	je	printVersion		; if so, jump to version
	mov	rsi, countString	; does the argument equal 'count'?
	call	strcmp
	test	rax, rax
	je	countParse		; if so, jump to further processing
	mov	rsi, hexString
	call	strcmp
	test	rax, rax
	je	sethex
	call	unknownArgs		; if its not these, we don't know what it is
	jmp	argsLoop		; see if theres more arguments

countParse:
	pop	rdi			; get the next argument, this should be a number
	test	rdi, rdi		; is the argument non existant?
	je	noOpt
	call	atoi			; rdi already holds the option string
	test	rax, rax
	js	badOpt			; was the top bit of rax set? must be negative, invalid
	mov	[count], rax		; save count for later
	jmp	argsLoop

sethex:
	push	rdi
	mov	rdi, wanthex
	mov	al, 'T'
	stosb
	pop	rdi
	jmp	argsLoop

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
	mov	rdi, errorPre
	call	puts
	mov	rdi, badArgsError
	call	puts
	ret

ignoreNonArgs:
	mov	rdi, errorPre
	call	puts
	mov	rdi, ignoreError
	call	puts
	jmp	argsLoop

noArgs:
	mov	rdi, errorPre
	call	puts
	mov	rdi, noArgsError
	call	puts
	call	exitFailure

noOpt:
	mov	rdi, errorPre
	call	puts
	mov	rdi, noOptError
	call	puts
	call	exitFailure

badOpt:
	mov	rdi, errorPre
	call	puts
	mov	rdi, badOptError
	call	puts
	call	exitFailure

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
	mov	rax, 1		; okay, now lets print...
	mov	rdi, 1		; ...to stdout
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
	cmp	[wanthex], byte 'T'
	je	hexconv_nocount

regularprint:
	xor	rax, rax
	inc	rax
	xor	rdi, rdi
	inc	rdi
	mov	rsi, readbuf
	syscall
	jmp	writecheck

hexconv_nocount:
	inc	r12		; increment counter
	mov	rax, [readbuf]	; set what we read to convert
	mov	rdi, itoabuf	; set block to recieve return value
	call	itoa
	call	strlen
	mov	rdx, rax	; save return value into count for write
	xor	rax, rax
	inc	rax
	xor	rdi, rdi
	inc	rdi
	mov	rsi, itoabuf	; the amount to print is already loaded
	syscall
	xor	rax, rax
	inc	rax
	xor	rdx, rdx
	inc	rdx
	mov	rsi, space	; add a space between digits
	syscall
	cmp	r12, 10		; did we already print 10 numbers?
	jle	writecheck	; if not, continue as normal
	xor	rax, rax
	inc	rax
	xor	rdi, rdi
	inc	rdi
	xor	rdx, rdx
	inc	rdx
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

badOpen:
	mov	rdi, errorPre
	call	puts
	mov	rdi, badOpenError
	call	puts
	call	exitFailure

badRead:
	mov	rdi, errorPre
	call	puts
	mov	rdi, badReadError
	call	puts
	call	exitFailure

;=================================================
; HELPER FUNCTIONS BEGIN HERE
;=================================================

; basic implementation of libc puts()
; NOTE, requires a null-terminated string
; rdi = address of null-terminated string
puts:
	push	rsi
	xor	rax, rax	; make sure register is clear for length
	call	strlen		; rdi should already contain address
	mov	rdx, rax	; move the count given into its place
	mov	rsi, rdi	; ready the address for the write() call
	mov	rax, 1		; we want to write...
	mov	rdi, 1		; ... to stdout
	syscall
	pop	rsi
	ret

; basic implementation of libc strlen()
; rdi = address of string
; rax = length of string
strlen:
	push	rcx
	lea	rax, [rdi + 1]	; load input, as well as incrementing

strlen_loop:
	mov	cl, byte [rax]	; and move the first character into the lowest part of rcx
	inc	rax		; increment length
	test	cl, cl		; is the current byte null?
	jnz	strlen_loop	; if not, keep repeating
	sub	rax, rdi
	pop	rcx
	ret

; implementation of libc strcmp()
; NOTE: requires null-terminated strings
; rsi = address of string
; rdi = address of string
; rax = the difference of the strings
strcmp:
	push	r10
	push	r11
	xor 	rcx, rcx		; ready counter

strcmp_loop:
	mov 	r10b, [rdi + rcx]	; load each index
	mov 	r11b, [rsi + rcx]
	cmp 	r10b, r11b		; how do they compare?
	jne 	strcmp_end		; if they aren't equal, exit
	test 	r10b, r10b		; has the first string ended?
	je 	strcmp_end		; if so, exit
	inc 	rcx			; increment
	jmp 	strcmp_loop		; and restart

strcmp_end:
	sub 	r10b, r11b		; get the difference from indexes
	movsx 	rax, r10b		; and load to returnValue
	pop	r11
	pop	r10
	ret

; implementation of libc atoi()
; NOTE: will not detect negative values
; rdi = address of string
; rax = resulting number
atoi:
	push	rcx
	xor 	rax, rax               	; reset returnValue

atoi_loop:
	movzx 	rcx, byte [rdi]		; loading next index
	sub 	rcx, '0'		; subtract 48 to convert from ASCII to int
	jl 	atoi_end		; invalid character?
	cmp 	rcx, 9			; was it too high?
	jg 	atoi_end		; if so, return

	lea 	rax, [rax * 4 + rax]  	; rax = result * 5
	lea 	rax, [rax * 2 + rcx]    ; rax = result * 5 * 2 + digit = result * 10 + digit
	inc 	rdi                   	; rdi = address of next character
	jmp 	atoi_loop

atoi_end:
	pop	rcx
	ret

; implementation of libc itoa(), but specifically for hexadecimal
; rax = binary integer
; rdi = address of string
itoa:
	push 	rdx
	push 	rcx
	push 	rbx
	push 	rax

	mov 	rbx, 16		; base of the decimal system
	xor 	ecx, ecx	; number of digits generated

itoa_nextdiv:
	xor 	edx, edx	; rax extended to (rdx,rax)
	div 	rbx		; divide by the number-base
	push 	rdx		; save remainder on the stack
	inc 	rcx		; and count this remainder
	cmp 	rax, 0		; was the quotient zero?
	jne 	itoa_nextdiv	; no, do another division

itoa_nextdigit:
	pop 	rax		; else pop recent remainder
	add 	al, '0'		; and convert to a numeral
	cmp	al, 57		; are we past the digits?
	jle	itoa_noadd	; if not, continue
	add	al, 7		; else, add 7 so we can get letters

itoa_noadd:
	stosb			; store to memory-buffer
	loop 	itoa_nextdigit	; again for other remainders
	mov	al, '.'
	stosb
	xor	al, al
	stosb

	pop 	rax
	pop 	rbx
	pop 	rcx
	pop 	rdx
	ret

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


;=================================================
; HELPER FUNCTIONS ENDS HERE
;=================================================

section .bss
	wanthex		resb 2
	inFile		resb bufsize
	count		resb bufsize
	itoabuf		resb bufsize
        readbuf		resb inbufsize
