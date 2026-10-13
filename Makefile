# VANGUARD-x86 BARE-METAL OS MAKEFILE
# Assembler: NASM | Emulation: QEMU i386

ASM=nasm
LD=ld
QEMU=qemu-system-i386

all: bin/vanguard.img

bin/boot.bin: src/boot/boot.asm
	mkdir -p bin
	$(ASM) -f bin src/boot/boot.asm -o bin/boot.bin

bin/kernel.o: src/kernel/kernel.asm
	$(ASM) -f elf32 src/kernel/kernel.asm -o bin/kernel.o

bin/vga.o: src/drivers/vga.asm
	$(ASM) -f elf32 src/drivers/vga.asm -o bin/vga.o

bin/keyboard.o: src/drivers/keyboard.asm
	$(ASM) -f elf32 src/drivers/keyboard.asm -o bin/keyboard.o

bin/shell.o: src/shell/shell.asm
	$(ASM) -f elf32 src/shell/shell.asm -o bin/shell.o

bin/vanguard.img: bin/boot.bin
	dd if=/dev/zero of=bin/vanguard.img bs=512 count=2880
	dd if=bin/boot.bin of=bin/vanguard.img conv=notrunc

run: bin/vanguard.img
	$(QEMU) -fda bin/vanguard.img -boot a

clean:
	rm -rf bin/
