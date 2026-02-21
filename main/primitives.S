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

    .section .iram1.text, "ax"

    # TODO: redo primitives

.global code_dup
.align 4
code_dup:
    call12 spop  
    call12 spush
    call12 spush
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely

.global code_plus
.align 4
code_plus:
    call8 spop 
    mov a12, a11
    call8 spop
    add a11, a12, a11
    call8 spush
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely

.global code_mult
.align 4
code_mult:
    call8 spop 
    mov a12, a10
    call8 spop
    mull a10, a12, a10
    call8 spush
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely

.global code_drop
.align 4
code_drop:
    call12 spop
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely

.global code_swap
.align 4
code_swap:
    call8 spop
    mov a12, a10
    call8 spop
    mov a13, a10
    mov a10, a12
    call8 spush
    mov a10, a13
    call8 spush
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely

.global code_over
.align 4
code_over:
    call8 spop
    mov a12, a10
    call8 spop
    call8 spush
    mov a13, a10
    mov a10, a12
    call8 spush
    mov a10, a13
    call8 spush
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely

.global code_depth
.align 4
code_depth:
    ROTW 2
    mov a2, a10
    ROTW -2
    call8 spush
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
