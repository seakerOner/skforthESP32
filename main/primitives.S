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
    call4 spush
    call4 spush
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
    mov a9, a8
    call4 spop
    add a8, a9, a8
    call4 spush
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
    mov a9, a8
    call4 spop
    mull a8, a9, a8
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
    mov a9, a8
    call4 spop
    mov a10, a8
    mov a8, a9
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
    mov a9, a8
    call4 spop
    call4 spush
    mov a10, a8
    mov a8, a9
    call4 spush
    mov a8, a10
    call4 spush
    retw

.global code_depth
.align 4
code_depth:
    call12 slen # 1 OP so it's better to do only one window rotation
    movi a10, .end_word_exec
    jx a10    # a normal JUMP has a range of -131068 to +131075 bytes. Not enough to go from iram to flash safely
