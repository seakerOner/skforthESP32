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

    .section .data
    # WORD        -> 32 bytes
    # 32000 bytes -> 1000 WORDS  (0.032 MB)
.align 4
dictionary:
    .space 32*1000

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
    .extern dictionary
    .extern here_dic
    .extern latest_word

dic_getword:

word_getprev:

word_getimmediate:

word_getnamelen:

word_getcode:

word_getname:


