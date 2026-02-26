# TODO: add word tracing when error occurs for better debugging

.section .rodata
    .global DECIMAL 
    .global HEXADECIMAL
    .global msg_ok
msg_ok:
    .asciz "  ok "

msg:
.asciz "Welcome to skforthESP32! (max 126 char per line)\n"

sk_handle:
.asciz "skforth>"

.equ DECIMAL, 10
.equ HEXADECIMAL, 16

    .section .bss
    .global mode
    .global num_base

.align 4
mode:
    .space 1

.align 4
input_buffer:
    .space 128      # uart fifo max size

.align 4
input_len:
    .space 1

.align 4
num_base:
    .space 1

    .section .text

.global app_main
.global .print_skhandle

.align 4
app_main:
    entry a1, 32

    movi a2, translation_buff
    movi a3, 0                     # null terminator
    s8i a3, a2, 11
    movi a3, translation_endbuff
    addi a2, a2, 11                 # last byte slot of buffer 
    s32i a2, a3, 0

    movi a2, num_base
    movi a3, DECIMAL
    s8i a3, a2, 0

    movi a2, mode
    movi a3, INTERPRET
    s8i a3, a2, 0

    # init here_dic and latest_word
    movi a2, dictionary
    movi a3, here_dic
    s32i a2, a3, 0
    movi a3, latest_word
    movi a4, 0
    s32i a4, a3, 0

    # add primitives to DIC
    movi a10, name_dot
    movi a11, 1
    movi a12, code_dot
    movi a13, 0
    call0 dic_addprim

    movi a10, name_cr
    movi a11, 2
    movi a12, code_cr
    movi a13, 0
    call0 dic_addprim

    movi a10, name_dup
    movi a11, 3
    movi a12, code_dup
    movi a13, 0
    call0 dic_addprim

    movi a10, name_plus
    movi a11, 1
    movi a12, code_plus
    movi a13, 0
    call0 dic_addprim
    
    movi a10, name_mult
    movi a11, 1
    movi a12, code_mult
    movi a13, 0
    call0 dic_addprim

    movi a10, name_drop
    movi a11, 4
    movi a12, code_drop
    movi a13, 0
    call0 dic_addprim

    movi a10, name_swap
    movi a11, 4
    movi a12, code_swap
    movi a13, 0
    call0 dic_addprim

    movi a10, name_depth
    movi a11, 5
    movi a12, code_depth
    movi a13, 0
    call0 dic_addprim

    movi a10, name_over
    movi a11, 4
    movi a12, code_over
    movi a13, 0
    call0 dic_addprim

    # INVARIANT REGISTERS
    # phy a2                         -> input_len       addr
    # phy a3                         -> input_buffer    addr
    # phy a14 (logic  a6 offset  8 ) -> uart fifo       addr
    # phy a15 (logic  a7 offset  8 ) -> uart status     addr
    #
    # The registers below are not in effect.
    # phy a22 (logic a10 offset 12 ) -> sp index     (max 7) 
    # phy a23 (logic a11 offset 12 ) -> stack base      addr      

    call8  init_uart
    # call12 init_stack
    movi a2, input_len
    movi a3, input_buffer

    movi a10, msg
    call8 uart_print

.print_skhandle:
    movi a5, 0
    s8i a5, a2, 0               # reset len

    movi a10, sk_handle
    call8 uart_print
.forever:
    call8 uart_trygetc          # get what the user types on terminal
    beqi a10, -1, .delay

    l8ui a4, a2, 0              # load len
    movi a5, UART_FIFO_LIMIT
    bge a4, a5, .delay          # buffer full

    #store byte
    add a6, a3, a4

    s8i a10, a6, 0              # save written byte to buffer

    beqi a10, 8, .backspace

    call8 uart_putc
    addi a4, a4, 1
    s8i a4, a2, 0

    # newline
    beqi a10, 10, interpret_line


.delay:
    call0 delay
    j .forever

.backspace:
    beqz a4, .delay
    call8 uart_putc

    addi a4, a4, -1
    s8i a4, a2, 0
    movi a10, 32                # space to clean char
    call8 uart_putc
    movi a10, 8                 # put the cursor on the original position
    call8 uart_putc
    j .delay
    

interpret_line:
    l8ui a4, a2, 0

    beqi a4, 1, .print_skhandle

    call0 lexer

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

    j .print_skhandle
