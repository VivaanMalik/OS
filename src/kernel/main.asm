; Legacy mode
org 0x7C00              ; (Directive) Tells assembler where code loaded
                        ; Directives not translated to machine code, its instruction for compiler
bits 16                 ; 16 bit code

%define ENDL 0x0D, 0x0A ; define endl


start:
    jmp main

; PRINT STRING
; param :-
; ds:si points to string

puts: 
    ; save registers to modify
    push si
    push ax
    ; push bx

.loop:
    lodsb               ; [DS:SI], SI++
    or al, al           ; check for 0 terminator (bitwise OR on al) ax divided into ah and al
                        ; if al not 0, value remains same
                        ; raises zero flag if al = 0
    jz .done            ; jz sees if zero flag raised

    mov ah, 0x0e        ; Tells bios to print char
    mov bh, 0           ; Tells bios to print on display 0
    int 0x10            ; interrupt (int) bios to print char
    
    jmp .loop

.done:
    ; pop bx
    pop ax
    pop si
    ret

main:
                        ; Memory stored in segmenrs (16 to 64 bytes)
                        ; segments overlap every 16 bytes
                        ; Real address = segment * 16 + offset
                        ; address in old thingies stored as segment:offset
                        ; segment[base + index * scale + displacement]
    mov ax, 0           ; ax = general register
    mov ds, ax          ; set ds, es using ax - cant write to es, ds directly
    mov es, ax          ; ds = data segment, es = extra segment

                        ; mem in stack accessed in fifo method (first in first out) use push and pop
                        ; sp grows downwards [ | OS]
                        ;                      ^
                        ;                      sp
    mov ss, ax          ; ss = stack segment
    mov sp, 0x7C00      ; sp = stack pointer

    ; print msg
    mov si, Init_msg    ; load msg first address to si
    call puts

    hlt                 ; halt

.halt:
    jmp .halt           ; inf loop of halting, prevents the cpu randomly restarting processing

Init_msg:
    db " ____  _               ____                    ", ENDL
    db "| __ )(_)_ __   __ _  | __ )  ___  _ __   __ _ ", ENDL
    db "|  _ \| | '_ \ / _` | |  _ \ / _ \| '_ \ / _` |", ENDL
    db "| |_) | | | | | (_| | | |_) | (_) | | | | (_| |", ENDL
    db "|____/|_|_| |_|\__, | |____/ \___/|_| |_|\__, |", ENDL
    db "               |___/                     |___/ ", ENDL
    db "HAHA NURDDDDDDD"
    db 0                ; null terminator

times 510-($-$$) db 0   ; $: mem offset of currect line
                        ; $$: mem offset of program
                        ; $ - $$: size of prog
                        ; db 0: set to 0
dw 0AA55h               ; We set last 2 bytes of 1st sector to aa55, cuz bios wants that
                        ; db: define bytes              dw: define words