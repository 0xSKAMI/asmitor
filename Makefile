.PHONY: clean
all: main final

ASM = nasm
LINK = ld

ASM_FLAGS = -f elf64 -g -F dwarf 

TARGET = main
TARGET2 = final

${TARGET}: main.asm
	${ASM} ${ASM_FLAGS} $< -o $@.o

${TARGET2}: main.o
	${LINK} $< -o $@

clean:
	rm ${TARGET}.o ${TARGET2}
