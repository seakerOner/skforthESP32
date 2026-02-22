    .section .data
# stack -> 8 32bits
.align 4
stack:
    .space 4*8

.align 4

    .global stack
    .global sp

    .section .text
    .global init_stack

.align 4
init_stack:
    entry a1, 32

    movi a10, 0
    movi a11, stack

    retw

    .section .iram1.text, "ax"
    .global spush
    .global spop
    .global slen 

.align 4
spush: # (phy a14 | log a4 -> val)
    entry a1, 32
    mov a9, a11    # stack

    movi a8, 4
    mull a8, a8, a10
    add a9, a9, a8  # stack[i]

    s32i a4, a9, 0
    addi a10, a10, 1

    retw

.align 4
spop: # return (phy a14 | log a4 -> val)
    entry a1, 32
    mov a9, a11    # stack

    addi a10, a10, -1

    movi a8, 4
    mull a8, a8, a10
    add a9, a9, a8  # stack[i]

    l32i a4, a9, 0

    retw

# get stack length. this is primarily used for the `depth` WORD
.align 4
slen:
    entry a1, 32
    mov a9, a11 # stack
    movi a8, 4
    mull a8, a8, a10
    add a9, a9, a8 # stack[i]

    s32i a10, a9, 0
    addi a10, a10, 1

    retw
