; ==============================================================================
; INTERRUPT DESCRIPTOR TABLE (IDT) & 8259 PIC REMAPPER
; ==============================================================================

[BITS 32]
global idt_install

section .text
idt_install:
    ; Load IDT Register
    lidt [idtr]

    ; Remap Master & Slave PIC 8259 from IRQ 0-15 to CPU Vectors 0x20-0x2F
    ; ICW1: Initialize PIC
    mov al, 0x11
    out 0x20, al
    out 0xA0, al

    ; ICW2: Vector Offsets
    mov al, 0x20                    ; Master PIC vectors: 0x20 - 0x27
    out 0x21, al
    mov al, 0x28                    ; Slave PIC vectors: 0x28 - 0x2F
    out 0xA1, al

    ; ICW3: Cascading wiring
    mov al, 0x04
    out 0x21, al
    mov al, 0x02
    out 0xA1, al

    ; ICW4: 8086/88 Mode
    mov al, 0x01
    out 0x21, al
    out 0xA1, al

    ; Unmask Keyboard IRQ1
    mov al, 11111101b               ; Enable IRQ1 only
    out 0x21, al
    sti                             ; Enable hardware interrupts
    ret

section .data
idtr:
    dw 256 * 8 - 1                  ; 256 entries * 8 bytes - 1
    dd idt_table

section .bss
idt_table:
    resb 256 * 8                    ; Reserve 2048 bytes for IDT
