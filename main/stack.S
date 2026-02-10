    .section .data
# stack -> 8 32bits
.align 4
stack:
    .space 4*8

.align 4
sp:
    .space 4

    .global stack
    .global sp

.section .text
    .global init_stack
    .global spush
    .global spop

.align 4
init_stack:
    ROTW 4      # offset reg window by 16

    movi a10, sp
    movi a11, stack
    movi a3, 0 
    s32i a3, a10, 0

    ROTW -4     # offset reg window by -16
    ret

.align 4
spush: # (phy a18 | log a2 -> val)
    ROTW 4
    mov a9, a11    # stack

    movi a8, 4
    mull a8, a8, a10
    add a9, a9, a8  # stack[i]

    s32i a2, a9, 0

    addi a10, a10, 1

    ROTW -4
    ret

.align 4
spop: # return (phy a18 | log a2 -> val)
    ROTW 4
    mov a9, a11    # stack

    addi a10, a10, -1

    movi a8, 4
    mull a8, a8, a10
    add a9, a9, a8  # stack[i]

    l32i a2, a9, 0

    ROTW -4
    ret
