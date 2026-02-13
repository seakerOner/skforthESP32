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

    .section .iram.text, "ax"

.global code_dup
.align 4
code_dup:
    call12 spop  # return val phy a14
    call12 spush
    call12 spush
    ret

.global code_plus
.align 4
code_plus:
    call12 spop  # return val phy a14
    mov a15, a14
    call12 spop
    add a14, a15, a14
    call12 spush
    ret

.global code_mult
.align 4
code_mult:
    call12 spop # return val phy a14
    mov a15, a14
    call12 spop
    mull a14, a15, a14
    call12 spush
    ret

.global code_drop
.align 4
code_drop:
    call12 spop
    ret

.global code_swap
.align 4
code_swap:
    call12 spop
    mov a15, a14
    call12 spop
    mov a13, a14
    mov a14, a15
    call12 spush
    mov a14, a13
    call12 spush
    ret

.global code_over
.align 4
code_over:
    call12 spop
    mov a15, a14
    call12 spop
    call12 spush
    mov a13, a14
    mov a14, a15
    call12 spush
    mov a14, a13
    call12 spush
    ret

.global code_depth
.align 4
code_depth:
    ROTW 3
    mov a2, a10
    ROTW -3
    call12 spush
    ret
