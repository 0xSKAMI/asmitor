section .data     
	filename db 'test.txt', 0 ;string + null terminator to mark the end
	introduce db 'Put file name here: ', 0 ;string + null terminator to mark the end
  
section .bss
	struc	test_type				;declaring test_type structure (we don't give it storage yet)
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
	test_type_buffer:			;giving test_type memory (storage)
		istruc test_type
		iend
	input resb 10					;buffer to get file name
	size_string resb 21		;buffer to store file size
	info resb 26					;buffer to store info program reads from file
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
 
	mov rax, 5															;sys_fstat
	mov rdi, [fd_in]												;file descriptor
	mov rsi, test_type_buffer								;giving it buffer so it can write in it
	syscall																	;interrupt

	mov rbx, [test_type_buffer + st_size]   ;moving size (in dec) to rbx reg

	mov rsi, size_string + 20								;point to end of buffer
	
	tranfer_loop:							;loop to tranform dec to hex
		mov rax, rbx						;writing dec length to rax
		xor rdx, rdx						;making rdx 0
		mov rdi, 10							;giving rdi value of 10
		div rdi									;devide

		mov byte [rsi], dl			;writing in rsi pointer byte (dl couse of we have only one byte or 8 bits)
		add byte [rsi], 48			;adding 48, 0 in ascii

		mov rbx, rax						;moving full number to rbx

		dec rsi									;racrease rsi by one
		cmp rax, 0							;see if there is only 0 in rax reg to end loop
		jne tranfer_loop				;ending loop in rax is 0

	;printing file size
	mov rax, 1						;using sys_write
	mov rdi, 1						;std_out file descriptor
	mov rsi, size_string + 19		;giving size of file
	mov rdx, 8					;charachters to write
	syscall							;run interrupt
	
	mov rax, [size_string + 19]
	cmp rax, 26 
	jg space 

	reading:
		;reading from file 
		mov rax, 0						;using sys_read
		mov rdi, [fd_in]			;file descriptor
		mov rsi, [info]					;info pointer	
		mov rdx, size_string		;charachters to read
		syscall							;run interrupt
	 
		;printing result 
		mov rax, 1						;using sys_write
		mov rdi, 1						;std_out file descriptor
		mov rsi, [info]					;info pointer
		mov rdx, size_string						;charachters to write
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
		mov rax, 9      ; sys_mmap
		mov rdi, 0      ; addr
		mov rsi, [size_string + 19]    ; length
		mov rdx, 3      ; prot = PROT_READ | PROT_WRITE 
		mov r10, 34     ; flags = MAP_PRIVATE | MAP_ANONYMOUS
		mov r8, -1      ; fd = -1
		mov r9, 0       ; offset
		syscall

		mov [info], rax

		cmp rax, 0
		jg reading
