; Legacy mode
org 0x7C00              ; (Directive) Tells assembler where code loaded
                        ; Directives not translated to machine code, its instruction for compiler
bits 16                 ; 16 bit code

%define ENDL 0x0D, 0x0A ; define endl

; FAT12 header
; ========================================================================================================
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'       ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880             ; 512 * 2880 = 1.44 MB
bdb_media_descriptor_type:  db 0F0h
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0 

ebr_drive_number:           db 0                ; 0x00 floppy, 0x80 hdd, useless
                            db 0                ; reserved
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h
ebr_volume_label:           db 'BINGBONG_OS'
ebr_system_id:              db 'FAT12   '
; ========================================================================================================


start:
    jmp main

; PRINT STRING
; param :-
; ds:si points to string

puts: 
    ; save registers to modify
    push si
    push ax
    push bx

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
    pop bx
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

    cli
    hlt                 ; halt


floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                     ; wait for keypress
    jmp 0FFFFh:0                ; jump to beginning of BIOS, should reboot

.halt:
    cli
    jmp .halt           ; inf loop of halting, prevents the cpu randomly restarting processing

; Disk Routine
; ========================================================================================================
; Convert Logical block addressing (lba) to Cylinder head sector (chs)
; ax: lba addresss
; cx [0-5]: sector no.
; cx [6-15]: cylinder
; dh: head
lba_to_chs:
    push ax
    push dx

    xor dx, dx                              ; dx = 0
    div word [bdb_sectors_per_track]        ; ax = LBA % SPT
                                            ; dx = LBA % SPT

    inc dx
    mov cx, dx

    xor dx, dx
    div word [bdb_heads]
    
    mov dh, dl
    mov ch, al
    shl ah, 6
    or cl, ah

    pop ax
    mov dl, al
    pop ax
    ret
; ========================================================================================================

; Disk read
; ========================================================================================================
disk_read:

    push ax                             ; save registers we will modify
    push bx
    push cx
    push dx
    push di

    push cx                             ; temporarily save CL (number of sectors to read)
    call lba_to_chs                     ; compute CHS
    pop ax                              ; AL = number of sectors to read
    
    mov ah, 02h
    mov di, 3     

.retry:
    pusha                               ; save all registers, we don't know what bios modifies
    stc                                 ; set carry flag, some BIOS'es don't set it
    int 13h                             ; carry flag cleared = success
    jnc .done                           ; jump if carry not set

    ; read failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; all attempts are exhausted
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax                             ; restore registers modified
    ret

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret
; ========================================================================================================

Init_msg:
    ; db " ____  _               ____                    ", ENDL
    ; db "| __ )(_)_ __   __ _  | __ )  ___  _ __   __ _ ", ENDL
    ; db "|  _ \| | '_ \ / _` | |  _ \ / _ \| '_ \ / _` |", ENDL
    ; db "| |_) | | | | | (_| | | |_) | (_) | | | | (_| |", ENDL
    ; db "|____/|_|_| |_|\__, | |____/ \___/|_| |_|\__, |", ENDL
    ; db "               |___/                     |___/ ", ENDL
    db "HAHA NURDDDDDDD"
    db 0                ; null terminator
msg_read_failed:        db 'Read from disk failed!', ENDL, 0

times 510-($-$$) db 0   ; $: mem offset of currect line
                        ; $$: mem offset of program
                        ; $ - $$: size of prog
                        ; db 0: set to 0
dw 0AA55h               ; We set last 2 bytes of 1st sector to aa55, cuz bios wants that
                        ; db: define bytes              dw: define words