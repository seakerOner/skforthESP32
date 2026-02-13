# the dictionary is a list of WORDS
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
.equ WORD_LEN, 32
    .global WORD_LEN

    .section .bss
    # WORD        -> 32 bytes
    # 32000 bytes -> 1000 WORDS  (0.032 MB)
.align 4
dictionary:
    .space 32000

.align 4
here_dic:
    .space 4    #   addr to next free spot in DIC

.align 4
latest_word:
    .space 4    

.global dictionary
.global here_dic
.global latest_word


    .section .text
    .global dic_addprim

# a10 -> name_ptr
# a11 -> name_len
# a12 -> code_ptr
# a13 -> immediate flag

.align 4
dic_addprim:
    movi a2, here_dic
    l32i a3, a2, 0      # a3 -> HERE

    # link = latest_word
    movi a4, latest_word
    l32i a5, a4, 0
    s32i a5, a3, 0

    # flags
    s8i a13, a3, 4
    s8i a11, a3, 5

    # code addr
    s32i a12, a3, 8

    # copy name
    addi a6, a3, 12
    mov a7, a11
.cpy_byte:
    l8ui a8, a10, 0
    s8i a8, a6, 0
    addi a10, a10, 1
    addi a6, a6, 1
    addi a7, a7, -1
    bnez a7, .cpy_byte

    s32i a3, a4, 0              # update latest_word

    addi a3, a3, WORD_LEN       # update here_dic
    s32i a3, a2, 0
    ret

