# code_space for Skforth. this space is used to store compiled words

    .section .bss
    .global code_space
.align 4
code_space:
    .space 32000        # 8000 code addresses
    .section .data
    .global code_p
code_p:
    .space 4

    .section .text
    .global codeadd
.align 4
codeadd:       # a2 -> addr to push
    entry a1, 32
    movi a10, code_p
    l32i a8, a10, 0
    movi a10, 4
    mull a8, a8, a10
    movi a9, code_space
    add a9, a9, a8      # code_space[p]
    s32i a2, a9, 0
    addi a10, a10, 1
    movi a10, code_p
    s32i a10, a10, 0
    retw

.align 4 
codeadd0:
    entry a1, 32
    movi a10, code_p
    l32i a8, a10, 0
    movi a10, 4
    mull a8, a8, a10
    movi a9, code_space
    add a9, a9, a8
    movi a2, 0
    s32i a2, a9, 0
    addi a10, a10, 1
    movi a10, code_p
    s32i a10, a10, 0

