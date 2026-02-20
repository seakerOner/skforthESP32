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

stackoverflow_err_msg:
    .asciz "ERROR: STACK is full... resetting\n"
stackunderflow_err_msg:
    .asciz "ERROR: STACK is empty... resetting\n"

# offset by 4 on register window is already expected when calling primitive's code addr
# so when calling spop/spush we have access to stack/sp invariant registers on 
# offset 12 (4 offset from original caller and 8 offset on callee)
#
# this is done so we can safely execute Forth WORDS and retw without breaking the Lexer "context"

    .section .iram1.text, "ax"

.global code_dup
.align 4
code_dup:
    entry a1, 32
    call8 spop  
    beqz a11, .err_stackunderflow
    call8 spush
    call8 spush
    retw

.global code_plus
.align 4
code_plus:
    entry a1, 32 
    call12 spop 
    beqz a15, .err_stackunderflow
    mov a12, a15
    call12 spop
    beqz a11, .err_stackunderflow
    add a15, a12, a15
    call12 spush
    retw

.global code_mult
.align 4
code_mult:
    entry a1, 32 
    call8 spop 
    beqz a11, .err_stackunderflow
    mov a12, a10
    call8 spop
    beqz a11, .err_stackunderflow
    mull a10, a12, a10
    call8 spush
    retw

.global code_drop
.align 4
code_drop:
    entry a1, 32
    call8 spop
    beqz a11, .err_stackunderflow
    retw

.global code_swap
.align 4
code_swap:
    entry a1, 32
    call8 spop
    beqz a11, .err_stackunderflow
    mov a12, a10
    call8 spop
    beqz a11, .err_stackunderflow
    mov a13, a10
    mov a10, a12
    call8 spush
    mov a10, a13
    call8 spush
    retw

.global code_over
.align 4
code_over:
    entry a1, 32
    call8 spop
    beqz a11, .err_stackunderflow
    mov a12, a10
    call8 spop
    beqz a11, .err_stackunderflow
    call8 spush
    mov a13, a10
    mov a10, a12
    call8 spush
    mov a10, a13
    call8 spush
    retw

.global code_depth
.align 4
code_depth:
    entry a1, 32
    ROTW 2
    mov a2, a10
    ROTW -2
    call8 spush
    retw

.err_stackoverflow:
    movi a10, stackoverflow_err_msg
    call8 uart_print
    retw

.err_stackunderflow:
    movi a10, stackunderflow_err_msg
    call8 uart_print
    retw

