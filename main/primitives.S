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
cr_text:
    .asciz "\n"
msg_overflow:
    .asciz "ERROR: Stack overflow.\n"
msg_underflow:
    .asciz "ERROR: Stack underflow.\n"

    .global name_lessthan
name_lessthan:
    .ascii "<"
    .global name_morethan
name_morethan:
    .ascii ">"
    .global name_spacechar
name_spacechar:
    .ascii " "

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
.global name_alloc
name_alloc:
    .ascii "ALLOC"
.global name_allocbytes
name_allocbytes:
    .ascii "ALLOCB"
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
.global name_dotstack
name_dotstack:
    .ascii ".s"

test:
    .asciz "BANANA"

    .section .bss
    .global translation_buff
    .global translation_endbuff
    .global here_addr

.align 4 
here_addr:
    .space 4
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
    movi a8, here_addr
    l32i a8, a8, 0
    call4 spush
    beqz a9, FLASH_err_of
    retw

.global code_alloc
.align 4
code_alloc:
    call8 .alloc_wrap
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
    .alloc_wrap:
    entry a1, 32
    call4 spop              # num cells (32bits)
    beqz a9, FLASH_err_uf
    movi a9, here_addr
    l32i a10, a9, 0
    movi a12, 32
    mull a8, a8, a12
    add a8, a10, a8
    s32i a8, a9, 0
    retw

.global code_allocbytes
.align 4
code_allocbytes:
    call8 .allocbytes_wrap
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
    .allocbytes_wrap:
    entry a1, 32 
    call4 spop
    beqz a9, FLASH_err_uf
    movi a9, here_addr
    l32i a10, a9, 0
    movi a12, 8 
    mull a8, a8, a12 
    add a8, a10, a8 
    s8i a8, a9, 0
    retw

.global code_dotstack
.align 4
code_dotstack:
    movi a10, name_lessthan
    l8ui a10, a10, 0
    call8 uart_putc

    movi a10, sp        
    l8ui a10, a10, 0
    movi a11, 0x30
    or a10, a10, a11
    call8 uart_putc

    movi a10, name_morethan
    l8ui a10, a10, 0
    call8 uart_putc

    movi a10, name_spacechar
    l8ui a10, a10, 0
    call8 uart_putc

    call8 .dotstack_wrap

    .after_dotstackwrap:
    movi a10, .end_word_exec
    jx a10

    .align 4
    .dotstack_wrap:
    entry a1, 32
    movi a4, sp        
    l8ui a4, a4, 0
    .next_val_stack:
    beqz a4, .end_dotstack
    addi a4, a4, -1
    movi a14, stack
    movi a10, 4
    mull a10, a4, a10
    add a12, a14, a10
    l32i a12, a12, 0

    # a12 -> value 

    movi a13, translation_endbuff
    l32i a13, a13, 0

    beqz a12, .dotstack_zero

    movi a10, HEXADECIMAL
    movi a11, num_base
    l8ui a11, a11, 0
    beq a10, a11, .dotstack_hex

    # decimal conversion if not hex
    .dotstack_dec:
    remu a10, a12, a11          # digit = value % base
    quou a12, a12, a11          # value = value / base

    movi a9, 0x30
    or a10, a10, a9         # dec to ASCII
    addi a13, a13, -1
    s8i a10, a13, 0
    bnez a12, .dotstack_dec
    j .end_digit
    .dotstack_hex:
    # TODO:

    .dotstack_zero:
        movi a12, 0x30          # ascii 0
        call8 uart_putc12
        movi a12, name_spacechar
        l8ui a12, a12, 0
        call8 uart_putc12
        j .next_val_stack

    .end_digit:
    #print buffer
    mov a12, a13
    call8 uart_print12
    movi a12, name_spacechar
    l8ui a12, a12, 0
    call8 uart_putc12
    j .next_val_stack

    .end_dotstack:
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

