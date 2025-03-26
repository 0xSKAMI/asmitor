section .data
	filename db 'test.txt', 0 ;string + null terminator to mark the end
	introduce db 'Put file name here: ', 0 ;string + null terminator to mark the end

section .bss
	input resb 10 
	input_length resd 1
	info resb 11
	fd_out resb 1
	fd_in  resb 1

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
	mov ecx, input		;input pointer
	mov edx, 10			;read 10 bytes
	int 0x80			;make system call
	
	;adding null terminator in the end of file
	mov byte [input + eax - 1], 0

	;storing eax to input length
	mov [input_length], eax 

	;unconditional jump to get_length label
	cmp eax, 1
	jle exit 

	get_length:
		;printing user's input
		mov eax, 4			;system_write
		mov ebx, 1			;std_out
		mov ecx, input		;user's input
		mov edx, [input_length]			;bytes to write
		int 0x80			;make system call
	
	;opening file
	mov eax, 5						;using sys_open
	mov ebx, input			;giving it filename
	mov ecx, 2						;declaring mode permissions
	int 0x80							;starting inteupt

	cmp eax, 0						
	jl exit								;jump if file descriptor is negative

	mov [fd_in], eax			;store the descriptor

	;reading from file
	mov eax, 3						;using sys_read
	mov ebx, [fd_in]			;file descriptor
	mov ecx, info					;info pointer	
	mov edx, 26						;charachters to read
	int 0x80							;run interrupt

	;printing result
	mov eax, 4						;using sys_print
	mov ebx, 1						;std_out file descriptor
	mov ecx, info					;info pointer
	mov edx, 11						;charachters to write
	int 0x80							;run interrupt
   
	; close the file
	mov eax, 6						;using sys_close
	mov ebx, [fd_in]			;file descriptor
	int  0x80							;run interrupt

	exit:
		mov eax, 1					;using sys_exit
		int 0x80						;run interrupt
