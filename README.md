# Asmitor

> [!IMPORTANT]  
> Asmitor is currently in pre-alpha state and only suitable to use by developers

## Features
For now asmitor can edit small files with only replace method (still not fully implemented).

## Build and run

> [!IMPORTANT]  
> Asmitor is written on linux x86 64, it will not work if user is using other system such as windows and so on
 
## Build Prerequisites
nasm - the Netwide Assembler, GNU ld, GNU Make (although you can build it without makefile too)

If you have make installed just run make and it will generate executable called "final". Run it

If you don't have make installed run following commands
```
nasm -f elf64 -g -F dwarf
ld main.o -o final
```

## License
Asmitor is licensed under MIT license
