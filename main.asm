section .data
	filename db 'test.txt'

section .bss
	info resb 11 
	fd_out resb 1
	fd_in  resb 1

section .text
	global _start

_start:
	;open file
	mov eax, 5			;using sys_open
	mov ebx, filename	;giving it filename
	mov ecx, 0			;declaring mode permissions
	int 0x80			;starting inteupt
	
	mov [fd_in], eax

	;reading from file
	mov eax, 3			;using sys_read
	mov ebx, [fd_in]	;file descriptor 
	mov ecx, info		;pointer to buffer
	mov edx, 26			;buffer size
	int 0x80

	;printing result
	mov eax, 4			
	mov ebx, 1
	mov ecx, info
	mov edx, 11
	int 0x80	
   
	; close the file
	mov eax, 6
	mov ebx, [fd_in]
	int  0x80    

	mov eax, 1
	int 0x80
