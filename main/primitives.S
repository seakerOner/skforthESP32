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

msg_notcomptime:
    .asciz "ERROR: Not in COMPTIME mode\n"
msg_notinterpret:
    .asciz "ERROR: Not in INTERPRET mode\n"

    .global name_lessthan
name_lessthan:
    .ascii "<"
    .global name_morethan
name_morethan:
    .ascii ">"
    .global name_lit
name_lit:
    .ascii "LIT"
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
.global name_minus
name_minus:
    .ascii "-"
.global name_xor
name_xor:
    .ascii "xor"
.global name_and
name_and:
    .ascii "and"
.global name_lsh
name_lsh:
    .ascii "<<"
.global name_rsh
name_rsh:
    .ascii ">>"
.global name_or
name_or:
    .ascii "or"
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
.global name_comma
name_comma:
    .ascii ":"
.global name_semicolon
name_semicolon:
    .ascii ";"

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
    entry a1, 32
    movi a10, cr_text
    call8 uart_print
    retw

.global code_here
.align 4
code_here:
    entry a1, 32
    movi a8, here_addr
    l32i a8, a8, 0
    call4 spush
    beqz a9, FLASH_err_of
    retw

.global code_lit
.align 4
code_lit:
    entry a1, 32
    movi a12, mode
    l8ui a12, a12, 0
    beqz a12, .lit_fail

    call8 codeadd_litflag
    retw
    .lit_fail:
    movi a10, msg_notcomptime
    call8 uart_print
    call0 esp_restart

.global code_alloc
.align 4
code_alloc:     # accepts a number of bytes (8 bits)
    entry a1, 32
    call4 spop              # num cells (32bits)
    beqz a9, FLASH_err_uf
    movi a9, here_addr
    l32i a10, a9, 0
    add a8, a10, a8
    s32i a8, a9, 0
    retw

.global code_dotstack
.align 4
code_dotstack:
    entry a1, 32
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
    entry a1, 32
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
    retw

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
    entry a1, 32
    call4 spop  
    beqz a9, IRAM_err_uf
    call4 spush
    call4 spush
    beqz a9, IRAM_err_of
    retw

.global code_semicolon
.align 4
code_semicolon:
    entry a1, 32
    movi a12, mode
    l8ui a12, a12, 0
    beqz a12, .semicolon_fail            

    call8 .wrap_semicolon
    movi a10, INTERPRET
    movi a12, mode
    s8i a10, a12, 0             # set to INTERPRET 
    retw
    .semicolon_fail:
    movi a10, msg_notcomptime
    call8 uart_print
    call0 esp_restart
    .align 4
    .wrap_semicolon:
    entry a1, 32
    call8 codeadd0
    retw

.global code_comma
.align 4
code_comma:
    entry a1, 32
    movi a12, mode
    l8ui a12, a12, 0
    bnez a12, .comma_comptime
    movi a12, COMPTIME
    movi a13, mode
    s8i a12, a13, 0             # set to COMPTIME

    movi a10, input_buffer       # buffer
    movi a11, input_len          # total
    l8ui a11, a11, 0
    movi a12, input_idx          # current index
    l32i a12, a12, 0

    call8 wrap_comma
    retw
    .align 4
    wrap_comma:
    entry a1, 32

    call8 code_current
    mov a10, a2                 # buffer
    mov a11, a3                 # total
    mov a12, a4                 # current index
    mov a2, a14                 # code_space[p]
    call8 get_next_token        
    movi a5, input_idx
    s8i a12, a5, 0              # update current index on lexer
    # a10 -> token addr
    # a11 -> tokenlen
    # a12 -> code_ptr
    # a13 -> immediate flag
    mov a12, a2
    movi a13, 0
    call8 dic_addcomp
   
    retw

    .comma_comptime:
    movi a10, msg_notinterpret
    call8 uart_print
    call0 esp_restart



.global code_plus
.align 4
code_plus:
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

.global code_minus
.align 4
code_minus:
    entry a1, 32
    call4 spop 
    beqz a9, IRAM_err_uf
    mov a11, a8
    call4 spop
    beqz a9, IRAM_err_uf
    sub a8, a8, a11
    call4 spush
    beqz a9, IRAM_err_of
    movi a2, 1
    retw


.global code_xor
.align 4
code_xor:
    entry a1, 32
    call4 spop 
    beqz a9, IRAM_err_uf
    mov a11, a8
    call4 spop
    beqz a9, IRAM_err_uf
    xor a8, a11, a8
    call4 spush
    beqz a9, IRAM_err_of
    movi a2, 1
    retw

.global code_or
.align 4
code_or:
    entry a1, 32
    call4 spop 
    beqz a9, IRAM_err_uf
    mov a11, a8
    call4 spop
    beqz a9, IRAM_err_uf
    or a8, a11, a8
    call4 spush
    beqz a9, IRAM_err_of
    movi a2, 1
    retw

.global code_and
.align 4
code_and:
    entry a1, 32
    call4 spop 
    beqz a9, IRAM_err_uf
    mov a11, a8
    call4 spop
    beqz a9, IRAM_err_uf
    and a8, a11, a8
    call4 spush
    beqz a9, IRAM_err_of
    movi a2, 1
    retw

.global code_lsh
.align 4
code_lsh:
    entry a1, 32
    call4 spop 
    beqz a9, IRAM_err_uf
    mov a11, a8
    call4 spop
    beqz a9, IRAM_err_uf
    ssl a11
    sll a8, a8
    call4 spush
    movi a2, 1
    retw

.global code_rsh
.align 4
code_rsh:
    entry a1, 32
    call4 spop 
    beqz a9, IRAM_err_uf
    mov a11, a8
    call4 spop
    beqz a9, IRAM_err_uf
    ssr a11
    srl a8, a8
    call4 spush
    movi a2, 1
    retw

.global code_mult
.align 4
code_mult:
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
    entry a1, 32
    call4 spop # 1 OP so it's better to do only one window rotation 
    retw

.global code_swap
.align 4
code_swap:
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
    entry a1, 32
    call4 slen # 1 OP so it's better to do only one window rotation
    retw

.global code_at
.align 4
code_at:
    entry a1, 32 
    call4 spop
    beqz a9, IRAM_err_uf
    l32i a8, a8, 0
    call4 spush
    retw

.global code_atbyte
.align 4
code_atbyte:
    entry a1, 32 
    call4 spop 
    beqz a9, IRAM_err_uf
    l8ui a8, a8, 0
    call4 spush
    retw

.global code_store 
.align 4
code_store:
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
    entry a1, 32
    call4 spop
    beqz a9, IRAM_err_uf
    mov a10, a8
    call4 spop
    beqz a9, IRAM_err_uf
    s8i a10, a8, 0
    retw

