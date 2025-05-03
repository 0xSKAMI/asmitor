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
	input resb 4096					;buffer to get user input 
	info resb 1					;buffer to store info program reads from file
	line_length resq 1
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
	mov rdx, 4096		;read 4096  bytes 
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

	;getting file information
	mov rax, 5															;sys_fstat
	mov rdi, [fd_in]												;file descriptor
	mov rsi, test_type_buffer								;giving it buffer so it can write in it
	syscall																	;interrupt
	
	jg space											;jumping to space and giving more space to info buffer there

	reading:
		;reading from file 
		mov rax, 0						;using sys_read
		mov rdi, [fd_in]			;file descriptor
		mov rsi, [info]					;buffer where program stores info that it reads 
		mov rdx, [test_type_buffer + st_size]		;charachters to read
		syscall							;run interrupt

		;printing result
		mov rax, 1						;using sys_write
		mov rdi, 1						;std_out file descriptor
		mov rsi, [info]				;buffer where we read from
		mov rdx, [test_type_buffer + st_size]						;charachters to write
		syscall							;run interrupt
	
		;sys_lseek to move cursor 
		mov rax, 8					;sys_lseek
		mov rdi, [fd_in]		;file descriptor
		mov rsi, 0					;bytes to move cursos
		mov rdx, 0					;start from beggining
		syscall

		;reading user input 
		mov rax, 0			;system_read 
		mov rdi, 0			;std_in 
		mov rsi, input		;input pointer
		mov rdx, 4096		;read 4096 bytes 
		syscall			;make system call 

		mov rbx, rax	;moving number of bytes in input to rbx register

		mov byte [input + rax - 1], 0		;removing newline in the end of inpuT
	
		dec rbx													;decreasing input length by 1 to fix it after /n is no longer there
	
		;writing to file
		mov rax, 1			;system_write  
		mov rdi, [fd_in]			;std_out  
		mov rsi, input				;input buffer
		mov rdx, rbx		;bytes to output
		syscall			;make system call  

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
		mov rsi, [test_type_buffer  + st_size] ; length
		mov rdx, 3      ; prot = PROT_READ | PROT_WRITE 
		mov r10, 34     ; flags = MAP_PRIVATE | MAP_ANONYMOUS
		mov r8, -1      ; fd = -1
		mov r9, 0       ; offset
		syscall

		mov [info], rax			;moving rax to info (practicly info is now tottaly new buffer)

		cmp rax, 0					;see if any errors had happen
		jg reading					;if not then jump to reading
		jle exit						;if yes then jump to exit

	read_line:
		mov rax, 8
		mov rdi, [fd_in]
		mov rsi, [line_length] 
		mov rdx, 0
		syscall

		mov rax, 0
		mov rdi, [fd_in]
		mov rsi, input
		mov rdx, 1
		syscall

		cmp rax, '/n'
		je reading 
