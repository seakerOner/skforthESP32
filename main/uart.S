.section .rodata

.equ UART_FIFO,   0x3FF40000
.equ UART_STATUS, 0x3FF4001C
.equ UART_FIFO_LIMIT, 128
    .global UART_FIFO_LIMIT

.section .text
.global init_uart
.global uart_print
.global uart_printn
.global uart_trygetc
.global uart_putc

.align 4
init_uart:
    entry a1, 16

    # TODO: change this registers. and update other places in the code base
    movi a6, UART_FIFO
    movi a7, UART_STATUS

    retw

.align 4
uart_print: # (reg2 -> string)
    entry a1, 16

    mov a3, a2               # string

.loop:
    l8ui a2, a3, 0
    beqz a2, .done

.wait_fifo:
    l32i a4, a7, 0
    extui a4, a4, 16, 8      # TXFIFO count
    movi a5, UART_FIFO_LIMIT           
    bge a4, a5, .wait_fifo

    s8i a2, a6, 0            # write byte
    addi a3, a3, 1
    j .loop

.done:
    retw

.align 4
uart_trygetc:
    entry a1, 16

    l32i a4, a7, 0
    extui a4, a4, 0, 8      # RXFIFO count
    beqz a4, .uart_empty

    l8ui a2, a6, 0

    retw
.uart_empty:
    movi a2, -1
    retw

.align 4 
uart_putc:
    entry a1, 16 

.wait_putc:
    l32i a4, a7, 0
    extui a4, a4, 16, 8 
    movi a5, UART_FIFO_LIMIT
    bge a4, a5, .wait_putc

    s8i a2, a6, 0

    // if CR -13-, send LF
    movi a4, 13
    beq a2, a4, .send_lf
    retw

.send_lf:
    movi a2, 10
    s8i a2, a6, 0
    retw

.align 4
uart_printn: # a2 -> addr | a3 -> len
    entry a1, 16
    mov a12, a2

    movi a13, 0     # counter
    .step_char:
    beq a13, a3, .doneprint
    add a10, a12, a13

.wait_printn:
    l32i a4, a7, 0
    extui a4, a4, 16, 8 
    movi a5, UART_FIFO_LIMIT
    bge a4, a5, .wait_printn

    l8ui a10, a10, 0
    s8i a10, a6, 0

    addi a13, a13, 1
    j .step_char

.doneprint:
    retw


