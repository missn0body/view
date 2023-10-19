ASM = nasm
ASMFLAGS = -f bin -Ox -Ov -g
RM = rm

view.com: dview.asm
	$(ASM) $^ $(ASMFLAGS) -o $@

view: view.com

.PHONY: all clean

all: view

clean:
	$(RM) view.com
