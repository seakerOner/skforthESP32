# collection of primitive WORDS
# primitive words give core functionlity to skforth.
# Word's code is stored in IRAM memory and not editable
#
# code is in IRAM to eliminate cache miss penalties aswell as 
# enabling faster and more predictable execution than code fetched from FLASH
#
# WORD structure:
#
# WORD total byte size -> max 32 bytes
#
# offset 0   : link prev word (  4     )
# offset 4   : is_immediate   (  1     )
# offset 5   : name_len       (  1     )
# offset 6-7 : padding
# offset 8   : code addr      (  4     )
# offset 12  : name ascii     ( 20 max )
    .section .rodata
    .global cr_text
    .equ PSRAM, 0x3F800000
cr_text:
    .asciz "\n"
msg_overflow:
    .asciz "ERROR: Stack overflow.\n"
msg_underflow:
    .asciz "ERROR: Stack underflow.\n"

.global name_cr 
name_cr:
    .ascii "cr"
.global name_dup
name_dup:
    .ascii "dup"
.global name_plus
name_plus:
    .ascii "+"
.global name_mult
name_mult:
    .ascii "*"
.global name_drop
name_drop:
    .ascii "drop"
.global name_swap
name_swap:
    .ascii "swap"
.global name_over
name_over:
    .ascii "over"
.global name_depth
name_depth:
    .ascii "depth"
.global name_here 
name_here:
    .ascii "HERE"
.global name_at
name_at:
    .ascii "@"
.global name_atbyte
name_atbyte:
    .ascii "b@"
.global name_store
name_store:
    .ascii "!"
.global name_storebyte
name_storebyte:
    .ascii "b!"
.global name_dot
name_dot:
    .ascii "."

    .section .bss
    .global translation_buff
    .global translation_endbuff

.align 4
translation_buff:
    .space 11           # max 32 bit number is 4,294,967,295 = 10 digits = 10 bytes + 1 bytes for null terminator
.align 4
translation_endbuff:
    .space 4            # address of the end of array

    .section .text
    .extern esp_restart
    .global FLASH_err_of

.align 4
FLASH_err_of:   # a3 -> return addr
    movi a2, msg_overflow
    call0 uart_print0
    call0 esp_restart
.align 4
FLASH_err_uf:   # a3 -> return addr
    movi a2, msg_underflow
    call0 uart_print0
    call0 esp_restart

.global code_cr
.align 4 
code_cr:
    movi a10, cr_text
    call8 uart_print
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely

.global code_here
.align 4
code_here:
    call8 .here_wrap
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
    .here_wrap:
    entry a1, 32
    movi a8, PSRAM
    call4 spush
    beqz a9, FLASH_err_of
    retw

.global code_dot
.align 4
code_dot:
    call8 .dot_wrap

    # a12 -> value from stack
    movi a13, translation_endbuff
    l32i a13, a13, 0

    beqz a12, .dot_zero

    movi a10, HEXADECIMAL
    movi a11, num_base
    l8ui a11, a11, 0
    beq a10, a11, .dot_hex
    # decimal conversion if not hex
    .dot_dec:
    remu a10, a12, a11          # digit = value % base
    quou a12, a12, a11          # value = value / base

    movi a9, 0x30
    or a10, a10, a9         # dec to ASCII
    addi a13, a13, -1
    s8i a10, a13, 0
    bnez a12, .dot_dec
    j .end_dot
    .dot_hex:
    # TODO:

    .dot_zero:
        movi a10, 0x30          # ascii 0
        call8 uart_putc
        movi a10, .end_word_exec
        jx a10

    .end_dot:
    # print buffer
    mov a10, a13
    call8 uart_print
    movi a10, .end_word_exec
    jx a10

    .align 4 
    .dot_wrap:
    entry a1, 32 
    call4 spop
    beqz a9, FLASH_err_uf
    mov a4, a8

    retw

    .section .iram1.text, "ax"

IRAM_err_of:
    movi a2, msg_overflow
    call0 uart_print0
    call0 esp_restart
IRAM_err_uf:
    movi a2, msg_underflow
    call0 uart_print0
    call0 esp_restart

.global code_dup
.align 4
code_dup:
    call8 .dup_wrap
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
    .align 4
    .dup_wrap:
    entry a1, 32
    call4 spop  
    beqz a9, IRAM_err_uf
    call4 spush
    call4 spush
    beqz a9, IRAM_err_of
    retw

.global code_plus
.align 4
code_plus:
    call8 .plus_wrap
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
    .align 4
    .plus_wrap:
    entry a1, 32
    call4 spop 
    beqz a9, IRAM_err_uf
    mov a11, a8
    call4 spop
    beqz a9, IRAM_err_uf
    add a8, a11, a8
    call4 spush
    beqz a9, IRAM_err_of
    movi a2, 1
    retw

.global code_mult
.align 4
code_mult:
    call8 .mult_wrap
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
    .align 4
    .mult_wrap:
    entry a1, 32
    call4 spop 
    beqz a9, IRAM_err_uf
    mov a11, a8
    call4 spop
    beqz a9, IRAM_err_uf
    mull a8, a11, a8
    call4 spush
    retw

.global code_drop
.align 4
code_drop:
    call12 spop # 1 OP so it's better to do only one window rotation 
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely

.global code_swap
.align 4
code_swap:
    call8 .swap_wrap
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
    .align 4
    .swap_wrap:
    entry a1, 32
    call4 spop
    beqz a9, IRAM_err_uf
    mov a11, a8
    call4 spop
    beqz a9, IRAM_err_uf
    mov a10, a8
    mov a8, a11
    call4 spush
    mov a8, a10
    call4 spush
    retw

.global code_over
.align 4
code_over:
    call8 .over_wrap
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
    .align 4
    .over_wrap:
    entry a1, 32
    call4 spop
    beqz a9, IRAM_err_uf
    mov a11, a8
    call4 spop
    beqz a9, IRAM_err_uf
    call4 spush
    mov a10, a8
    mov a8, a11
    call4 spush
    mov a8, a10
    call4 spush
    beqz a9, IRAM_err_of
    retw

.global code_depth
.align 4
code_depth:
    call12 slen # 1 OP so it's better to do only one window rotation
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely

.global code_at
.align 4
code_at:
    call8 .at_wrap
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
    .at_wrap:
    entry a1, 32 
    call4 spop
    beqz a9, IRAM_err_uf
    l32i a8, a8, 0
    call4 spush
    retw

.global code_atbyte
.align 4
code_atbyte:
    call8 .atbyte_wrap
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
    .atbyte_wrap:
    entry a1, 32 
    call4 spop 
    beqz a9, IRAM_err_uf
    l8ui a8, a8, 0
    call4 spush
    retw

.global code_store 
.align 4
code_store:
    call8 store_wrap
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
    store_wrap:
    entry a1, 32
    call4 spop
    beqz a9, IRAM_err_uf
    mov a10, a8
    call4 spop
    beqz a9, IRAM_err_uf
    s32i a10, a8, 0
    retw

.global code_storebyte
.align 4
code_storebyte:
    call8 storebyte_wrap
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
    storebyte_wrap:
    entry a1, 32
    call4 spop
    beqz a9, IRAM_err_uf
    mov a10, a8
    call4 spop
    beqz a9, IRAM_err_uf
    s8i a10, a8, 0
    retw

