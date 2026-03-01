.section .rodata

.equ UART_FIFO,   0x3FF40000
.equ UART_STATUS, 0x3FF4001C
.equ UART_FIFO_LIMIT, 128
    .global UART_FIFO_LIMIT

.section .text
.global init_uart
.global uart_print
.global uart_print0
.global uart_print12
.global uart_printn
.global uart_trygetc
.global uart_putc
.global uart_putc12

.align 4
init_uart:
    entry a1, 16

    movi a6, UART_FIFO
    movi a7, UART_STATUS

    retw

# uart_print with 8 offset window rotation
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

# uart_print with any offset window rotation
.align 4
uart_print12: # (reg2 -> string)
    entry a1, 16
    movi a2, UART_FIFO
    movi a3, UART_STATUS

    mov a8, a4               # string

.loop12:
    l8ui a4, a8, 0
    beqz a4, .done12

.wait_fifo12:
    l32i a9, a3, 0
    extui a9, a9, 16, 8      # TXFIFO count
    movi a5, UART_FIFO_LIMIT           
    bge a9, a5, .wait_fifo12

    s8i a4, a2, 0            # write byte
    addi a8, a8, 1
    j .loop12

.done12:
    retw


# uart_print with no window rotation
.align 4
uart_print0: # (reg2 -> string)
    mov a3, a2               # string

.loop0:
    l8ui a2, a3, 0
    beqz a2, .done0

.wait_fifo0:
    l32i a4, a7, 0
    extui a4, a4, 16, 8      # TXFIFO count
    movi a5, UART_FIFO_LIMIT           
    bge a4, a5, .wait_fifo0

    s8i a2, a6, 0            # write byte
    addi a3, a3, 1
    j .loop0

.done0:
    ret


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
uart_putc12:    # reg4 -> char
    entry a1, 16 
    movi a2, UART_FIFO
    movi a3, UART_STATUS

.wait_putc12:
    l32i a10, a3, 0
    extui a10, a10, 16, 8 
    movi a5, UART_FIFO_LIMIT
    bge a10, a5, .wait_putc12

    s8i a4, a2, 0

    // if CR -13-, send LF
    movi a10, 13
    beq a4, a10, .send_lf12
    retw

.send_lf12:
    movi a4, 10
    s8i a4, a2, 0
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


