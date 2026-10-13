; ==============================================================================
; PS/2 KEYBOARD CONTROLLER DRIVER (PORT 0x60 / 0x64)
; ==============================================================================

[BITS 32]
global keyboard_read_char

section .text
keyboard_read_char:
    ; Poll I/O Port 0x64 until output buffer is full
.wait:
    in al, 0x64
    test al, 1                      ; Bit 0 = Output Buffer Full
    jz .wait

    ; Read scancode from I/O Port 0x60
    in al, 0x60
    test al, 0x80                   ; Ignore key release (break codes)
    jnz .wait

    ; Lookup ASCII character in scancode table
    movzx eax, al
    mov al, [scancode_ascii + eax]
    ret

section .data
scancode_ascii:
    db 0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, 9
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 10, 0
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'", '`', 0, '\'
    db 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' '
    times 128 db 0
