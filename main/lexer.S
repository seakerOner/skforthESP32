    .section .rodata
    .global COMPTIME
    .global INTERPRET
.equ COMPTIME, 1
.equ INTERPRET, 0
unknown_word_err:
    .asciz " <- Unknown WORD\n"

    .section .text
    .global lexer

.align 4
lexer: # phy a2 -> len | phy a3 -> buffer
    l8ui a4, a2, 0

    addi a4, a4, -1     # ignore cr
    movi a5, 0          # loop counter

.next_tok:
    movi a7, 0          # current token len counter
.loop:
    add a6, a3, a5     # buffer[i] addr
    l8ui a6, a6, 0
    beqi a6, 32, .step  # buffer[i] == space
        
    beqz a7, save_tok_start

    1:
    addi a7, a7, 1
    j 2f 
    
    .step:
    bnez a7, found_tok
    2:
    addi a5, a5, 1
    bne a5, a4, .loop

    bnei a6, 32, found_tok

.end:
    ret

# ---

save_tok_start:
    add a8, a3, a5
    j 1b

found_tok: # a7 -> tokenlen | a8 -> token addr

    # traverse dictionary for matching name
    movi a9, latest_word
    3:

    l8ui a10, a9, 5         # word len

    bne a10, a7, step_dic
    

    # check if token and name are the same
    movi a10, 0     # counter
    .step_tok_char:
    beq a10, a7, exec_word 
    addi a13, a10, 12       # offset 12 for base string + current char
    add a13, a9, a13        # word name[i] addr
    l8ui a13, a13, 0        

    add a11, a8, a10    # token[i]
    l8ui a11, a11, 0    

    bne a11, a13, step_dic
    j .step_tok_char

step_dic: # a9 -> word base addr
    l32i a9, a9, 0                  # WORD -> prev word
    beqi a9, 0, tok_not_in_dic      # reached last word 
    j 3b

tok_not_in_dic:
    # try to transform token into a number, add it to the stack and step orelse fail

    # TODO: 

    beq a5, a4, .end
    j .next_tok

exec_word: # a9 -> word base addr 
    # core logic of the lexer if WORD is found 

    #TODO:

    beq a5, a4, .end
    j .next_tok

