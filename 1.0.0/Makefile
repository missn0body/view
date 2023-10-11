ASM = nasm
ASMFLAGS = -f elf64 -Ox -Ov -g
LD = ld
RM = rm

view.o: view.asm
	$(ASM) $(ASMFLAGS) $^

view: view.o
	$(LD) -o $@ $^

.PHONY: all clean

all: view

clean:
	$(RM) *.o view
