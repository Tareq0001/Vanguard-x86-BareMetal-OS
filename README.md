# VANGUARD-x86 | Pure Assembly Bare-Metal Operating System

[![Live Demo](https://img.shields.io/badge/Live_Demo-GitHub_Pages-emerald?style=for-the-badge&logo=github)](https://tareq0001.github.io/Vanguard-x86-BareMetal-OS/)
[![Assembly: 100%](https://img.shields.io/badge/Language-100%25_x86_Assembly-blue?style=for-the-badge&logo=assemblyscript)](https://github.com/Tareq0001/Vanguard-x86-BareMetal-OS)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**VANGUARD-x86** is a complete, institutional-grade **bare-metal operating system and kernel written 100% in pure Intel x86 Assembly (NASM)**. It boots directly on raw hardware, transitions from 16-bit Real Mode to 32-bit Protected Mode, configures hardware segmentation via the GDT, remaps the 8259 PIC, and drives direct video memory buffers (`0xB8000`) and the PS/2 keyboard controller.

---

## ⚡ Core Architecture & Engineering Highlights

1. **512-Byte MBR Bootloader (`src/boot/boot.asm`):**
   - Loaded by the BIOS at `0x0000:0x7C00`.
   - Enables the A20 address line via Fast A20 Gate (I/O Port `0x92`).
   - Configures the Global Descriptor Table (GDT) for a flat 4GB memory space.
   - Sets the Protection Enable (`PE`) bit in Control Register 0 (`CR0`).
   - Executes a far jump (`jmp 0x08:protected_mode_entry`) to flush the CPU instruction prefetch pipeline.
   - Terminated with the MBR magic signature `0xAA55`.

2. **Ring 0 Protected Mode Kernel (`src/kernel/kernel.asm`):**
   - Reloads data segment selectors (`DS, ES, FS, GS, SS = 0x10`).
   - Establishes a 32-bit protected-mode stack at `ESP = 0x90000`.
   - Installs the Interrupt Descriptor Table (IDT) and remaps master/slave PIC 8259 chips (IRQs 0-15 to vectors `0x20-0x2F`).

3. **Direct Memory Video Driver (`src/drivers/vga.asm`):**
   - Writes directly to the color text video memory buffer at physical address `0xB8000` (80x25 character matrix).
   - Manipulates hardware blinking cursor via CRT controller I/O ports `0x3D4` and `0x3D5`.

4. **PS/2 Keyboard Driver (`src/drivers/keyboard.asm`):**
   - Polls status register at I/O Port `0x64`.
   - Reads hardware scancodes from Port `0x60` and decodes them into ASCII characters.

5. **Live In-Browser Architecture Workstation:**
   - Complete interactive x86 CPU emulator and instruction decoder running the compiled system in real time.
   - Live CPU register view (`EAX, EBX, ECX, EDX, ESI, EDI, ESP, EBP, EIP, EFLAGS, CR0`).
   - Real-time Disassembly view with step-by-step instruction execution.
   - Memory Hex Viewer inspecting physical RAM byte-by-byte.
   - Built-in live NASM Assembler REPL: type x86 assembly instructions and assemble/execute them directly into CPU registers!

---

## 🛠️ Local Build & QEMU Emulation

```bash
# 1. Assemble bootloader into raw binary
nasm -f bin src/boot/boot.asm -o bin/boot.bin

# 2. Assemble kernel and drivers into 32-bit ELF objects
nasm -f elf32 src/kernel/kernel.asm -o bin/kernel.o
nasm -f elf32 src/drivers/vga.asm -o bin/vga.o
nasm -f elf32 src/drivers/keyboard.asm -o bin/keyboard.o

# 3. Create bootable floppy disk image (1.44MB)
dd if=/dev/zero of=bin/vanguard.img bs=512 count=2880
dd if=bin/boot.bin of=bin/vanguard.img conv=notrunc

# 4. Run on bare-metal hardware emulator (QEMU)
qemu-system-i386 -fda bin/vanguard.img -boot a
```

---

## 🚀 Live Web Workstation

Experience the live bare-metal operating system and register emulator in your browser:
👉 [https://tareq0001.github.io/Vanguard-x86-BareMetal-OS/](https://tareq0001.github.io/Vanguard-x86-BareMetal-OS/)

Designed & Engineered by **Tareq Aboushi** (أ. طارق ابوعشي).
