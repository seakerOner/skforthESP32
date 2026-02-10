.section .rodata

msg:
.asciz "Welcome to skforthESP32! (max 126 char per line)\n"

sk_handle:
.asciz "skforth>"

.extern uart_print
.extern uart_trygetc
.extern uart_putc
.extern delay
.extern lexer

.section .bss

.align 4
input_buffer:
    .space 128  # uart fifo max size

.align 4
input_len:
    .space 1

    # TODO: add backspace/delete functionality
.section .text
.global app_main

.align 4
app_main:
    entry a1, 32

    # INVARIANT REGISTERS
    # phy a2 -> input_len    addr
    # phy a3 -> input_buffer addr
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
    movi a5, 126
    bge a4, a5, .delay          # buffer full

    #store byte
    add a6, a3, a4

    s8i a10, a6, 0              # save written byte to buffer

    call8 uart_putc
    addi a4, a4, 1
    s8i a4, a2, 0

    # newline
    beqi a10, 10, interpret_line

.delay:
    call8 delay
    j .forever

interpret_line:
    l8ui a4, a2, 0

    add a6, a3, a4
    movi a5, 10                 # cr
    s8i a5, a6, 0
    addi a6, a6, 1
    movi a5, 0                  # null terminator
    s8i a5, a6, 0

    call0 lexer

    j .print_skhandle
