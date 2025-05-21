section .data     
	filename db 'test.txt', 0 ;string + null terminator to mark the end
	introduce db 'Put file name here: ', 0 ;string + null terminator to mark the end
	clear db 27,"[H",27,"[2J" 
	backward db 27,"[D", 0
	forward db 27,"[C",13, 0
	up db 27,"[A", 0
	down db 27,"[B", 0
	cursor_home db 27, "[H", 0
	cursor_save db 27, "[s", 0
	cursor_paste db 27, "[u", 0
  
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
	struc termios_type		;creating test_type struc to save termios flags
		c_iflag:		resb 4  ;4 bytes 
		c_oflag:		resb 4	;4 bytes
		c_cflag:		resb 4	;4 bytes
		c_lflag:		resb 4	;4 bytes
		c_line:			resb 1	;1 bytes
		C_cc:				resb 19	;19 bytes
	endstruc
	termios_type_buffer:	;allocating storage for termios_type 
		istruc termios_type
		iend
	input resb 4096					;buffer to get user input 
	info resb 1					;buffer to store info program reads from file
	line_length resq 1
	fd_out resb 1
	fd_in  resq 1 
	line_count resb 1
	length_count resb 1
  
section .text  
	global _start
  
_start:   
	mov rax, 16										;sys_ioctl
	mov rdi, 2										;stdout
	mov rsi, 0x5401								;TCGETS
	mov rdx, termios_type_buffer	;saving result in termios_type_buffer
	syscall												;calling interrupt

	;clearing the terminal
	mov rax, 1			;system_write  
	mov rdi, 1			;std_out  
	mov rsi, clear	;clear text
	mov rdx, 10			;bytes to output
	syscall			;make system call  
	
	;moving cursor to home (start of buffer)
	mov rax, 1			;system_write  
	mov rdi, 1			;std_out  
	mov rsi, cursor_save	;ANSI code
	mov rdx, 3			;bytes to output
	syscall			;make system call  
	
	;printing introduce text  
	mov rax, 1			;system_write  
	mov rdi, 1			;std_out  
	mov rsi, introduce	;introduce text
	mov rdx, 21			;bytes to output
	syscall			;make system call  

	mov rbx, rax

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
 
	;printing introduce text  
	mov rax, 1			;system_write  
	mov rdi, 1			;std_out  
	mov rsi, clear	;introduce text
	mov rdx, 16			;bytes to output
	syscall			;make system call  
  
	;opening file 
	mov rax, 2						;using sys_open
	mov rdi, input			  ;giving it filename
	mov rsi, 2						;declaring mode permissions
	syscall							;starting inteupt

	cmp rax, 0						 
	jl exit								;jump if file descriptor is negative
 
	mov [fd_in], rax			;store the descriptor

	;changing flags (using hex)
	mov eax, 0x8a31														;saving new flag in eax register
	mov [termios_type_buffer + c_lflag], eax	;saving new flags in c_lflag buffer

	mov rax, 16																;calling ioctl
	mov rdi, 1																;file descriptor fd_out
	mov rsi, 0x5402														;TCSET
	mov rdx, termios_type_buffer							;saving from termios_type_buffer
	syscall																		;calling interrupt

	get_file_info:
		;getting file information
		mov rax, 5															;sys_fstat
		mov rdi, [fd_in]												;stdout
		mov rsi, test_type_buffer								;giving it buffer so it can write in it
		syscall																	;interrupt
	
		mov rax, [test_type_buffer + st_size]
		cmp rax, 0
		jg space											;jumping to space and giving more space to info buffer there

	reading_file:
		;sys_lseek to move cursor 
		mov rax, 8					;sys_lseek
		mov rdi, [fd_in]		;file descriptor
		mov rsi, 0					;bytes to move cursos
		mov rdx, 0					;start from beggining
		syscall

		;reading from file 
		mov rax, 0						;using sys_read
		mov rdi, [fd_in]			;file descriptor
		mov rsi, [info]					;buffer where program stores info that it reads 
		mov rdx, [test_type_buffer + st_size]		;charachters to read
		syscall							;run interrupt

		;moving cursor to home (start of buffer)
		mov rax, 1			;system_write  
		mov rdi, 1			;std_out  
		mov rsi, cursor_home	;ANSI code
		mov rdx, 3			;bytes to output
		syscall			;make system call  
	reading_buffer:
		;printing result
		mov rax, 1						;using sys_write
		mov rdi, 1						;std_out file descriptor
		mov rsi, [info]				;buffer where we read from
		mov rdx, [test_type_buffer + st_size]						;charachters to write
		syscall							;run interrupt

		;moving cursor to where it was
		mov rax, 1			;system_write  
		mov rdi, 1			;std_out  
		mov rsi, cursor_paste	;ANSI code
		mov rdx, 3			;bytes to output
		syscall			;make system call  

	input_loop:
		;sys_lseek to move cursor 
		mov rax, 8					;sys_lseek
		mov rdi, [fd_in]		;file descriptor
		mov rsi, 0					;bytes to move cursos
		mov rdx, 1					;go to the end of file 
		syscall
		
		;reading user input 
		mov rax, 0			;system_read 
		mov rdi, 0			;std_in 
		mov rsi, input		;input pointer
		mov rdx, 4096		;read 4096 bytes 
		syscall			;make system call 

		mov al, [input]
		cmp al, 0x1b 
		je check_cursor_1 

		mov rbx, rax	;moving number of bytes in input to rbx register
		mov byte [input + rbx - 1], 0		;removing newline in the end of inpuT
		dec rbx

		;clearing the terminal
		mov rax, 1			;system_write  
		mov rdi, 1			;std_out  
		mov rsi, clear	;clear text
		mov rdx, 16			;bytes to output
		syscall			;make system call  
	
		mov al, [input]
		mov rbx, [info]		
		mov byte [rbx + 2], al
	
		jmp reading_buffer 

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
		jg reading_file					;if not then jump to reading
		jle exit						;if yes then jump to exit

	check_cursor_1:
		mov ah, [input + 1]
		cmp ah, 0x5b
		je check_cursor_2 

	check_cursor_2:
		mov ah, [input + 2]
		cmp ah, 0x43
		je right_cursor 

		mov ah, [input + 2]
		cmp ah, 0x44
		je left_cursor 

		mov ah, [input + 2]
		cmp ah, 0x42
		je down_cursor

		mov ah, [input + 2]
		cmp ah, 0x41
		je up_cursor
	
	right_cursor:
		;moving cursor backward
		mov rax, 1			;system_write  
		mov rdi, 1			;std_out  
		mov rsi, forward	;clear text
		mov rdx, 3			;bytes to output
		syscall			;make system call  

		;saving cursor position
		mov rax, 1			;system_write  
		mov rdi, 1			;std_out  
		mov rsi, cursor_save	;ANSI code
		mov rdx, 3			;bytes to output
		syscall			;make system call  

		inc byte [length_count]
		
		jmp reading_buffer
	
	left_cursor:
		;moving cursor backward
		mov rax, 1			;system_write  
		mov rdi, 1			;std_out  
		mov rsi, backward	;clear text
		mov rdx, 3			;bytes to output
		syscall			;make system call  

		;saving cursor position
		mov rax, 1			;system_write  
		mov rdi, 1			;std_out  
		mov rsi, cursor_save	;ANSI code
		mov rdx, 3			;bytes to output
		syscall			;make system call  

		dec byte [length_count] 
		
		jmp reading_buffer

	up_cursor:
		;moving cursor backward
		mov rax, 1			;system_write  
		mov rdi, 1			;std_out  
		mov rsi, up	;clear text
		mov rdx, 3			;bytes to output
		syscall			;make system call  

		;saving cursor position
		mov rax, 1			;system_write  
		mov rdi, 1			;std_out  
		mov rsi, cursor_save	;ANSI code
		mov rdx, 3			;bytes to output
		syscall			;make system call  

		jmp reading_buffer
	
	down_cursor:
		;moving cursor backward
		mov rax, 1			;system_write  
		mov rdi, 1			;std_out  
		mov rsi, down	;clear text
		mov rdx, 3			;bytes to output
		syscall			;make system call  

		;saving cursor position
		mov rax, 1			;system_write  
		mov rdi, 1			;std_out  
		mov rsi, cursor_save	;ANSI code
		mov rdx, 3			;bytes to output
		syscall			;make system call  

		jmp reading_buffer 

	line_read:
		mov rbx, [info]
		mov rax, [line_count]
		xor rsi, rsi

		cmp byte [rbx + rax], 0x0A 
		jne line_read
		cmp [line_count], rax
		jne line_read

		add rax, [length_count]
		cmp byte [rbx + rax], 0x0A 
