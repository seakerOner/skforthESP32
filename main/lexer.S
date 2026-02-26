    .section .rodata
    .global COMPTIME
    .global INTERPRET
.equ COMPTIME, 1
.equ INTERPRET, 0
unknown_word_err:
    .asciz " <- Unknown WORD\n"

    .section .text
    .global lexer
    .global .end_word_exec

.align 4
lexer: # phy a2 -> len | phy a3 -> buffer
    l8ui a4, a2, 0

    addi a4, a4, -1                 # ignore cr
    movi a5, 0                      # loop counter

.next_tok:
    movi a7, 0                      # current token len counter
.loop:
    add a6, a3, a5                  # buffer[i] addr
    l8ui a6, a6, 0
    beqi a6, 32, .step              # buffer[i] == space
        
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
    l32i a9, a9, 0
    3:
    beqi a9, 0, tok_not_in_dic          # reached last word 

    l8ui a10, a9, 5                     # word len

    bne a10, a7, step_dic
    

    # check if token and name are the same
    movi a10, 0                         # counter
    .step_tok_char:
    beq a10, a7, exec_word 
    addi a13, a10, 12                   # offset 12 for base string + current char
    add a13, a9, a13                    # word name[i] addr
    l8ui a13, a13, 0        

    add a11, a8, a10                    # token[i]
    l8ui a11, a11, 0    

    addi a10, a10, 1
    bne a11, a13, step_dic
    j .step_tok_char

step_dic: # a9 -> word base addr
    l32i a9, a9, 0                      # WORD -> prev word
    j 3b

tok_not_in_dic: # a7 -> tokenlen | a8 -> token addr
    # try to transform token into a number, add it to the stack and step orelse fail
    # instructions BLTUI and BGEUI can't accept immediate values of the range desired in ASCII conversion
    # that's why we load the values into registers as penalty and use BLTU and BGEU

    movi a10, num_base
    l8ui a10, a10, 0
    movi a9, 0                          # counter
    movi a11, 0                         # result value

    # while ( valid char ) convert char to num
    movi a13, HEXADECIMAL
    beq a10, a13, .hex_conversion_step
    .dec_conversion_step:    # if not hex, naturally will be decimal
    add a12, a8, a9                     # base token addr + index
    l8ui a12, a12, 0                    # token[index]
    movi a13, 0x2F
    bltu a12, a13, .tok_not_num         # <= 47
    movi a13, 0x3A
    bgeu a12, a13, .tok_not_num         # >= 58
    # valid decimal number, convert
    movi a13, 0x30
    xor a12, a12, a13
    mull a11, a11, a10                  # val * base
    add a11, a11, a12                   # val = val * base + num

    addi a9, a9, 1
    bne a9, a7, .dec_conversion_step
    j .send_num_to_stack    
    .hex_conversion_step:
    add a12, a8, a9
    l8ui a12, a12, 0
    movi a13, 0x2F
    bltu a12, a13, .tok_not_num         # <= 47
    movi a13, 0x67
    bgeu a12, a13, .tok_not_num         # >= 'g'
    movi a13, 0x39
    bltu a12, a13, .is_hex_numerical
    movi a13, 0x61
    bgeu a12, a13, .is_hex_lowercase
    movi a13, 0x40
    bltu a12, a13, .tok_not_num
    movi a13, 0x46
    bltu a12, a13, .is_hex_uppercase
    
    .is_hex_numerical:
    movi a13, 0x30
    xor a12, a12, a13
    mull a11, a11, a10                  # val * base
    add a11, a11, a12                   # val = val * base + num
    j .next_num_hex

    .is_hex_lowercase:
    movi a13, 0x60 
    xor a12, a12, a13
    addi a12, a12, 9
    mull a11, a11, a10                  # val * base
    add a11, a11, a12                   # val = val * base + num
    j .next_num_hex

    .is_hex_uppercase:
    movi a13, 0x40
    xor a12, a12, a13
    addi a12, a12, 9
    mull a11, a11, a10                  # val * base
    add a11, a11, a12                   # val = val * base + num

    .next_num_hex:
    addi a9, a9, 1
    bne a9, a7, .hex_conversion_step

    .send_num_to_stack:
    # a wrap subroutine is used in the same fashion on primitive WORDS to enable register access
    call8 .lexer_stack_wrap 

    movi a10, msg_ok
    call8 uart_print

    movi a10, sp
    l8ui a10, a10, 0
    movi a11, 0x30
    or a10, a10, a11            # number to ASCII decimal
    movi a11, 1
    call8 uart_putc

    movi a10, cr_text
    call8 uart_print


    j .print_skhandle               #   reset
        .align 4
        .lexer_stack_wrap:
        entry a1, 32 
        mov a8, a3                  #   a3 @ offset 8 = a11 @ offset 0
        call4 spush
        retw

    .tok_not_num:
    mov a10, a8
    mov a11, a7
    call8 uart_printn
    movi a10, unknown_word_err
    call8 uart_print
    j .print_skhandle               #   reset

.end_tok_transformation:
    beq a5, a4, .end
    j .next_tok

exec_word: # a9 -> word base addr 
    # core logic of the lexer if WORD is found 

    movi a10, mode
    l8ui a10, a10, 0

    bnez a10, .comptime             # IF 0 -> interpret ELSE 1 -> comptime
    interpret:
        l32i a10, a9, 8                 # WORD code addr
        jx a10
    .comptime:
        l8ui a10, a9, 4                 # offset 4 -> is_immediate
        bnez a10, .not_immediate        # IF 0 -> not_immediate ELSE 1 -> is_immediate
        immediate:
            l32i a10, a9, 8                 # WORD code addr
            jx a10
        .not_immediate:
            # TODO: add word to code_space

.align 4
.end_word_exec:
    beq a5, a4, .end
    j .next_tok

