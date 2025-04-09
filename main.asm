section .data     
	filename db 'test.txt', 0 ;string + null terminator to mark the end
	introduce db 'Put file name here: ', 0 ;string + null terminator to mark the end
  
section .bss  
	input resb 10   
	info resb 26   
	fd_out resb 1  
	fd_in  resb 1  
  
section .text  
	global main  
  
main:   
	;printing introduce text  
	mov rax, 1			;system_write  
	mov rbx, 1			;std_out  
	mov rsi, introduce	;introduce text
	mov rdx, 21			;bytes to output
	syscall			;make system call  
  
	;allocating memory using malloc 
	mov rdi, 40 
	extern malloc 
	call malloc 
	ret	 
 
	;reading user input 
	mov eax, 3			;system_read 
	mov ebx, 0			;std_in 
	mov ecx, input		;input pointer
	mov edx, 10			;read 10 bytes 
	syscall			;make system call 
	 
	;adding null terminator in the end of file
	mov byte [input + eax - 1], 0 
 
	;jump to exit if input is empty 
	cmp eax, 1 
	jle exit  
 
	;opening file 
	mov eax, 5						;using sys_open
	mov ebx, input			  ;giving it filename
	mov ecx, 2						;declaring mode permissions
	syscall							;starting inteupt
 
	cmp eax, 0						 
	jl exit								;jump if file descriptor is negative
 
	mov [fd_in], eax			;store the descriptor
 
	;reading from file 
	mov eax, 3						;using sys_read
	mov ebx, [fd_in]			;file descriptor
	mov ecx, info					;info pointer	
	mov edx, 26						;charachters to read
	syscall							;run interrupt
 
	;printing result 
	mov eax, 4						;using sys_print
	mov ebx, 1						;std_out file descriptor
	mov ecx, info					;info pointer
	mov edx, 11						;charachters to write
	syscall							;run interrupt
    
	; close the file 
	mov eax, 3						;using sys_close
	mov ebx, [fd_in]			;file descriptor
	syscall								;run interrupt
 
	;label for exit code 
	exit: 
		mov rax, 60					;using sys_exit
		syscall						;run interrupt
