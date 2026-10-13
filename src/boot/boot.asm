; ==============================================================================
; VANGUARD-x86 BARE-METAL OPERATING SYSTEM - MBR BOOTLOADER
; Architect: Tareq Aboushi (أ. طارق ابوعشي)
; Target Architecture: Intel x86 (16-bit Real Mode -> 32-bit Protected Mode)
; Assembled with: NASM (Netwide Assembler)
; ==============================================================================

[BITS 16]
[ORG 0x7C00]                        ; BIOS loads boot sector to physical 0x0000:0x7C00

boot_start:
    cli                             ; Clear interrupts during fundamental setup
    xor ax, ax                      ; AX = 0
    mov ds, ax                      ; DS = 0
    mov es, ax                      ; ES = 0
    mov ss, ax                      ; SS = 0
    mov sp, 0x7C00                  ; Stack grows downwards from 0x7C00
    sti                             ; Re-enable interrupts

    ; Display Real-Mode Boot Greeting via BIOS INT 10h TeleType
    mov si, msg_real_mode
    call bios_print_string

    ; --------------------------------------------------------------------------
    ; Step 1: Enable A20 Line via Fast A20 Gate (I/O Port 0x92)
    ; --------------------------------------------------------------------------
    in al, 0x92
    or al, 2                        ; Bit 1 = A20 Fast Gate Enable
    out 0x92, al

    ; --------------------------------------------------------------------------
    ; Step 2: Load Global Descriptor Table (GDT)
    ; --------------------------------------------------------------------------
    cli                             ; Disable interrupts before protected mode transition
    lgdt [gdt_descriptor]           ; Load 48-bit GDT pointer into GDTR register

    ; --------------------------------------------------------------------------
    ; Step 3: Switch CPU to 32-bit Protected Mode (CR0 PE bit)
    ; --------------------------------------------------------------------------
    mov eax, cr0
    or eax, 0x00000001              ; Set Protection Enable (PE) bit 0
    mov cr0, eax

    ; --------------------------------------------------------------------------
    ; Step 4: Far Jump to 32-bit Code Segment to flush CPU prefetch queue
    ; --------------------------------------------------------------------------
    jmp 0x08:protected_mode_entry   ; 0x08 = Offset of Kernel Code Segment in GDT

; ==============================================================================
; 16-BIT REAL MODE UTILITIES
; ==============================================================================
bios_print_string:
    lodsb                           ; Load byte at DS:SI into AL and increment SI
    or al, al                       ; Check for null terminator
    jz .done
    mov ah, 0x0E                    ; BIOS TeleType output function
    int 0x10                        ; Call BIOS Video Services
    jmp bios_print_string
.done:
    ret

msg_real_mode db "[VANGUARD BIOS] 16-Bit Real Mode Initialized. Enabling A20 & Loading GDT...", 0x0D, 0x0A, 0

; ==============================================================================
; GLOBAL DESCRIPTOR TABLE (GDT) - FLAT 4GB ADDRESSING SPACE
; ==============================================================================
gdt_start:
    ; Null Descriptor (Mandatory 8 null bytes)
    dd 0x00000000
    dd 0x00000000

    ; Kernel Code Segment Descriptor (Offset 0x08)
    ; Base: 0x00000000, Limit: 0xFFFFF (4GB with 4KB Granularity)
    ; Flags: Present, Ring 0, Executable, Readable
    dw 0xFFFF                       ; Limit (bits 0-15)
    dw 0x0000                       ; Base (bits 0-15)
    db 0x00                         ; Base (bits 16-23)
    db 10011010b                    ; Access Byte: P=1, DPL=00, S=1, Type=Code (RX)
    db 11001111b                    ; Flags (4-bit) & Limit (bits 16-19): G=1 (4KB), D=1 (32-bit)
    db 0x00                         ; Base (bits 24-31)

    ; Kernel Data Segment Descriptor (Offset 0x10)
    ; Base: 0x00000000, Limit: 0xFFFFF (4GB with 4KB Granularity)
    ; Flags: Present, Ring 0, Writable
    dw 0xFFFF                       ; Limit (bits 0-15)
    dw 0x0000                       ; Base (bits 0-15)
    db 0x00                         ; Base (bits 16-23)
    db 10010010b                    ; Access Byte: P=1, DPL=00, S=1, Type=Data (RW)
    db 11001111b                    ; Flags (4-bit) & Limit (bits 16-19): G=1 (4KB), B=1 (32-bit)
    db 0x00                         ; Base (bits 24-31)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1      ; GDT size in bytes minus 1 (16-bit Limit)
    dd gdt_start                    ; 32-bit Linear Base Address of GDT

; ==============================================================================
; 32-BIT PROTECTED MODE ENTRY POINT
; ==============================================================================
[BITS 32]
protected_mode_entry:
    ; Reload all segment registers with Kernel Data Segment selector (0x10)
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Setup 32-bit Protected Mode Stack at 0x90000
    mov esp, 0x00090000
    mov ebp, esp

    ; Clear VGA Text Screen Buffer at 0xB8000
    call vga_clear_screen

    ; Print Protected Mode Confirmation Banner
    mov esi, msg_prot_mode
    mov ah, 0x0A                    ; Light Green on Black
    call vga_print_at

    ; Jump to Kernel Main Entry
    extern kernel_main
    call kernel_main

    ; Halt loop if kernel ever returns
.halt:
    hlt
    jmp .halt

; ------------------------------------------------------------------------------
; 32-Bit Direct VGA Memory Writing (0xB8000)
; ------------------------------------------------------------------------------
vga_clear_screen:
    mov edi, 0x000B8000             ; Base address of color video text buffer
    mov ecx, 80 * 25                ; 80 columns x 25 rows = 2000 character cells
    mov ax, 0x0720                  ; Character: ' ' (0x20), Attribute: Light Grey on Black (0x07)
    rep stosw                       ; Store word AX into [EDI] ECX times
    ret

vga_print_at:
    ; ESI: Pointer to null-terminated string, AH: Color attribute
    mov edi, 0x000B8000
.loop:
    lodsb
    or al, al
    jz .done
    stosw                           ; Write character (AL) and attribute (AH) to [EDI]
    jmp .loop
.done:
    ret

msg_prot_mode db "VANGUARD-x86 KERNEL: Entered 32-Bit Protected Mode [CR0=0x80000011]", 0

; Pad remaining bytes up to 510 with zeros and add MBR magic boot signature
times 510 - ($ - $$) db 0
dw 0xAA55                           ; MBR Boot Signature (Byte 511 & 512)
