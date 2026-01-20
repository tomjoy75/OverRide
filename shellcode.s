BITS 32 ; Tell nasm this is 32-bit code.

	jmp short one ; Jump down to a call at the end.
two:
; ssize_t write(int fd, const void *buf, size_t count);
	pop ecx ; Pop the return address (string ptr) into ecx.
	xor eax, eax ; initialise register eax.
	xor ebx, ebx ; initialise register ebx.
	xor edx, edx ; initialise register edx.
	mov al, 4 ; Write syscall #.
	mov bl, 1 ; STDOUT file descriptor
	mov dl, 13 ; Length of the string
	int 0x80 ; Do syscall: write(1, string, 14)

; void _exit(int status);
	mov al, 1 ; Exit syscall #
	sub bl, 1 ; Status = 0
	int 0x80 ; Do syscall: exit(0)

one:
	call two ; Call back upwards to avoid null bytes
	db "Hello, world!" ; with newline and carriage return bytes.
