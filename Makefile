.PHONY: clean
all: main final

ASM = nasm
C=gcc
LINK = ld

ASM_FLAGS =-f elf64 -g -F dwarf
C_FLAGS=-no-pie

TARGET = main
TARGET2 = final

${TARGET}: main.asm
	${ASM} ${ASM_FLAGS} $< -o $@.o

${TARGET2}: main.o
	${C} ${C_FLAGS} -o $@ $<

clean:
	rm ${TARGET}.o ${TARGET2}
