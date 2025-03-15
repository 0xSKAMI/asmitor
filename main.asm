section .data
	filename db 'test.txt'
	introduce db 'Put file name here: '

section .bss
	input resb 10 
	input_length resb 1

section .text
	global _start

_start:
	;printing introduce text
	mov eax, 4			;system_write
	mov ebx, 1			;std_out
	mov ecx, introduce	;introduce text
	mov edx, 20			;bytes to output
	int 0x80			;make system call

	;reading user input
	mov eax, 3			;system_read
	mov ebx, 0			;std_in
	mov ecx, input		;info pointer
	mov edx, 10			;read 10 bytes
	int 0x80			;make system call

	;unconditional jump to get_length label
	mov edx, 110
	cmp edx, 10
	jl get_length	

	get_length:
		;printing user's input
		mov eax, 4			;system_write
		mov ebx, 1			;std_out
		mov ecx, input_length		;user's input
		mov edx, 10			;bytes to write
		int 0x80			;make system call

	mov eax, 1
	int 0x80
