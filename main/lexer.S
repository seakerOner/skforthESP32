    .section .rodata
    .global COMPTIME
    .global INTERPRET
.equ COMPTIME, 1
.equ INTERPRET, 0

    .section .text
    .global lexer

.align 4
lexer: # phy a2 -> len | phy a3 -> buffer
    l8ui a4, a2, 0

    addi a4, a4, -1     # ignore cr
    movi a5, 0          # loop counter

.next_token:
    movi a7, 0          # current token len counter
.loop:
    add a6, a3, a5     # buffer[i] addr
    l8ui a6, a6, 0
    beqi a6, 32, .step  # buffer[i] == space
        
    beqz a7, save_token_start

    1:
    addi a7, a7, 1
    j 2f 
    
    .step:
    bnez a7, found_token
    2:
    addi a5, a5, 1
    bne a5, a4, .loop

    bnei a6, 32, found_token

.end:
    ret

# ---

save_token_start:
    add a8, a3, a5
    j 1b

found_token: # a7 -> tokenlen | a8 -> token addr
    l8ui a10, a8, 0
    call8 uart_putc



    beq a5, a4, .end
    j .next_token
