; ==============================================================================
; DIRECT MEMORY VGA DRIVER (0xB8000) & CRT CONTROLLER PORTS
; ==============================================================================

[BITS 32]
global vga_print_string
global vga_set_cursor
global vga_put_char

section .text

vga_print_string:
    ; ESI: Pointer to string, AH: Attribute
.next_char:
    lodsb
    or al, al
    jz .done
    cmp al, 0x0A                    ; Newline check
    je .newline
    call vga_put_char
    jmp .next_char
.newline:
    ; Advance cursor to start of next line
    mov eax, [cursor_pos]
    xor edx, edx
    mov ebx, 80
    div ebx
    inc eax                         ; Next row
    imul eax, 80
    mov [cursor_pos], eax
    jmp .next_char
.done:
    ret

vga_put_char:
    ; AL: Char, AH: Attribute
    push ebx
    push edx
    mov ebx, [cursor_pos]
    shl ebx, 1                      ; Multiply by 2 (2 bytes per cell)
    add ebx, 0x000B8000
    mov [ebx], ax                   ; Store character and color
    inc dword [cursor_pos]
    pop edx
    pop ebx
    ret

vga_set_cursor:
    ; [ESP+4]: Col, [ESP+8]: Row
    push ebp
    mov ebp, esp
    mov eax, [ebp+12]               ; Row
    imul eax, 80
    add eax, [ebp+8]                ; Col
    mov [cursor_pos], eax

    ; Send hardware cursor location to VGA CRT Controller (Ports 0x3D4, 0x3D5)
    mov ebx, eax
    mov dx, 0x03D4
    mov al, 0x0F                    ; Cursor Low byte index
    out dx, al
    inc dx
    mov al, bl
    out dx, al

    dec dx
    mov al, 0x0E                    ; Cursor High byte index
    out dx, al
    inc dx
    mov al, bh
    out dx, al

    pop ebp
    ret

section .data
cursor_pos dd 0
