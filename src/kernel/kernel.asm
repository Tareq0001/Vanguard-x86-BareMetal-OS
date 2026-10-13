; ==============================================================================
; VANGUARD-x86 BARE-METAL KERNEL - MAIN DISPATCHER
; Architect: Tareq Aboushi (أ. طارق ابوعشي)
; ==============================================================================

[BITS 32]
global kernel_main
extern idt_install
extern vga_print_string
extern vga_set_cursor
extern shell_init

section .text
kernel_main:
    ; 1. Install Interrupt Descriptor Table & Remap Programmable Interrupt Controller (PIC 8259)
    call idt_install

    ; 2. Initialize Interactive Video Cursor
    push dword 0                    ; Row 0
    push dword 0                    ; Col 0
    call vga_set_cursor
    add esp, 8

    ; 3. Display Institutional Kernel Header
    mov esi, kernel_banner
    mov ah, 0x0F                    ; Bright White on Black
    call vga_print_string

    ; 4. Dispatch to Shell Command Line Interface
    call shell_init

    ; Unreachable halt trap
.hang:
    hlt
    jmp .hang

section .data
kernel_banner:
    db "================================================================================", 0x0A
    db "  VANGUARD-x86 BARE-METAL OS [Version 1.0.4 - Release 2026]                    ", 0x0A
    db "  Pure Intel x86 Assembly Kernel | Designed & Engineered by Tareq Aboushi       ", 0x0A
    db "================================================================================", 0x0A
    db "CPU State: i386 Protected Mode | Paging: CR0/CR3 Ready | IDT: Installed        ", 0x0A
    db "Memory: 128 MB Base RAM Mapped | Video: 80x25 Color Text Mode at 0xB8000       ", 0x0A
    db "Type 'help' for available system commands or 'regs' to dump CPU state.         ", 0x0A, 0x0A, 0
