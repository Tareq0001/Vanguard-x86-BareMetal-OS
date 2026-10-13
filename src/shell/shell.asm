; ==============================================================================
; INTERACTIVE SHELL & COMMAND INTERPRETER IN PURE ASSEMBLY
; ==============================================================================

[BITS 32]
global shell_init
extern vga_print_string
extern keyboard_read_char

section .text
shell_init:
    mov esi, prompt_msg
    mov ah, 0x0B                    ; Cyan prompt
    call vga_print_string

shell_loop:
    call keyboard_read_char
    cmp al, 10                      ; Enter key
    je .process_cmd
    ; Echo character and store in buffer
    ; ...
    jmp shell_loop

.process_cmd:
    ; Compare buffer with built-in commands:
    ; 'help', 'regs', 'mem', 'clear', 'about', 'matrix', 'reboot'
    ret

section .data
prompt_msg db "vanguard-os # ", 0
cmd_help   db "help", 0
cmd_regs   db "regs", 0
cmd_mem    db "mem", 0
cmd_clear  db "clear", 0
