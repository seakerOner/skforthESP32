    .section .data
# stack -> 8 32bits
.align 4
stack:
    .space 4*8

.align 4
sp:
    .space 1

.align 4

    .global stack
    .global sp

    .section .text
    .global init_stack

# TODO:
# invariant registers here are invalid because when switching windows a10, a11 are not naturally "saved" 
# by the entry/retw combo. Normally it only restores a2-a7. manually saving the context could be an option.
# But as being devil's advocate maybe this is over-engineering and won't give as much performance as I naively may expect.
# Something to thinker about and test.

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
spush: # (phy a16 | log a4 @ offset 12 -> val)
    entry a1, 32

    movi a10, sp
    l8ui a10, a10, 0

    movi a9, stack    # stack

    movi a8, 4
    mull a8, a8, a10
    add a9, a9, a8  # stack[i]

    s32i a4, a9, 0
    addi a10, a10, 1

    movi a11, sp
    s8i a10, a11, 0
    retw

.align 4
spop: # return (phy a17 | log a4 @ offset 12 -> val)
    entry a1, 32

    movi a10, sp
    l8ui a10, a10, 0

    movi a9, stack    # stack

    addi a10, a10, -1

    movi a8, 4
    mull a8, a8, a10
    add a9, a9, a8  # stack[i]

    l32i a4, a9, 0

    movi a11, sp
    s8i a10, a11, 0

    retw

# get stack length. this is primarily used for the `depth` WORD
.align 4
slen:
    entry a1, 32

    movi a10, sp
    l8ui a10, a10, 0

    movi a9, stack # stack
    movi a8, 4
    mull a8, a8, a10
    add a9, a9, a8 # stack[i]

    s32i a10, a9, 0
    addi a10, a10, 1

    movi a11, sp
    s8i a10, a11, 0
    retw
