.section .rodata

.equ UART_FIFO,   0x3FF40000
.equ UART_STATUS, 0x3FF4001C
.equ UART_FIFO_LIMIT, 126

.section .text
.global uart_print
.global uart_getc
.global uart_putc

.align 4
uart_print: # (reg2 -> string)
    entry a1, 16

    movi a6, UART_FIFO
    movi a7, UART_STATUS
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

# TODO: idf.py monitor terminal cant send bytes to ESP32, use a proper serial terminal (screen)
.align 4
uart_getc:
    entry a1, 16

    movi a6, UART_FIFO
    movi a7, UART_STATUS

.wait_rx:
    l32i a4, a7, 0
    extui a4, a4, 0, 8      # RXFIFO count
    beqz a4, .wait_rx       # wait for a single byte

    l8ui a2, a6, 0
    retw

.align 4 
uart_putc:
    entry a1, 16 

    movi a6, UART_FIFO
    movi a7, UART_STATUS

.wait_putc:
    l32i a4, a7, 0
    extui a4, a4, 16, 8 
    movi a5, UART_FIFO_LIMIT
    bge a4, a5, .wait_putc

    s8i a2, a6, 0
    retw



