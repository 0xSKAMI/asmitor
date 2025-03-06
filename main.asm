section .data
	filename db 'test.txt'

section .text
	global _start

_start:
	mov eax, 5
	mov ebx, filename
	mov ecx, 0
	mov edx, 0777
	int 0x80
