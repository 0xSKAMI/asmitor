section .data     
	filename db 'test.txt', 0 ;string + null terminator to mark the end
	introduce db 'Put file name here: ', 0 ;string + null terminator to mark the end
  
section .bss  
	struc	test_type
		st_dev:     resq 1  ; 8 bytes
		st_ino:     resq 1  ; 8 bytes
		st_nlink:   resq 1  ; 8 bytes (often 64-bit on x64)
		st_mode:    resd 1  ; 4 bytes
		st_uid:     resd 1  ; 4 bytes
		st_gid:     resd 1  ; 4 bytes
		__pad0:     resd 1  ; 4 bytes padding (likely exists)
		st_rdev:    resq 1  ; 8 bytes
		st_size:    resq 1  ; 8 bytes
		st_blksize: resq 1  ; 8 bytes
		st_blocks:  resq 1  ; 8 bytes
		st_atime:   resq 1  ; 8 bytes (seconds part of timespec)
		st_atime_nsec: resq 1 ; 8 bytes (nanoseconds part)
		st_mtime:   resq 1  ; 8 bytes
		st_mtime_nsec: resq 1 ; 8 bytes
		st_ctime:   resq 1  ; 8 bytes
		st_ctime_nsec: resq 1 ; 8 bytes
		__unused:   resq 3  ; Reserved space often at the end (3 * 8 bytes)
	endstruc
	test_type_buffer:
		istruc test_type
		iend
	input resb 10 
	info resb 26   
	fd_out resb 1 
	fd_in  resq 1 
  
section .text  
	global _start
  
_start:   
	;printing introduce text  
	mov rax, 1			;system_write  
	mov rdi, 1			;std_out  
	mov rsi, introduce	;introduce text
	mov rdx, 21			;bytes to output
	syscall			;make system call  

	;reading user input 
	mov rax, 0			;system_read 
	mov rdi, 0			;std_in 
	mov rsi, input		;input pointer
	mov rdx, 10			;read 10 bytes 
	syscall			;make system call 

	;jump to exit if input is empty 
	cmp rax, 10 
	jge exit  

	;adding null terminator in the end of file
	mov byte [input + rax - 1], 0 
 
	;jump to exit if input is empty 
	cmp rax, 1 
	jle exit  
 
	;opening file 
	mov rax, 2						;using sys_open
	mov rdi, input			  ;giving it filename
	mov rsi, 2						;declaring mode permissions
	syscall							;starting inteupt

	cmp rax, 0						 
	jl exit								;jump if file descriptor is negative
 
	mov [fd_in], rax			;store the descriptor
 
	mov rax, 5
	mov rdi, [fd_in]
	mov rsi, test_type_buffer
	syscall

	mov rax, 1						;using sys_write
	mov rdi, 1						;std_out file descriptor
	mov rsi, [test_type_buffer]					;info pointer
	mov rdx, 1024						;charachters to write
	syscall							;run interrupt

	;reading from file 
	mov rax, 0						;using sys_read
	mov rdi, [fd_in]			;file descriptor
	mov rsi, info					;info pointer	
	mov rdx, 26						;charachters to read
	syscall							;run interrupt
 
	;printing result 
	mov rax, 1						;using sys_write
	mov rdi, 1						;std_out file descriptor
	mov rsi, info					;info pointer
	mov rdx, 26						;charachters to write
	syscall							;run interrupt
    
	; close the file 
	mov rax, 3						;using sys_close
	mov rdi, [fd_in]			;file descriptor
	syscall								;run interrupt
 
	;label for exit code 
	exit: 
		mov rax, 60					;using sys_exit
		syscall						;run interrupt

	space:
		;allocating memory
		mov rdi, input		;putting 0 in ebx register (making syscall return pointer to)
		add rdi, 128			;adding 128 bytes to memory
		mov rax, 12				;sys_brk
		syscall						;make system call
