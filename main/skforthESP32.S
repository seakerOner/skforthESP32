.section .rodata
msg:
    .asciz "Hello from ASM skforth ESP32!\n"

.equ UART_FIFO,   0x3FF40000
.equ UART_STATUS, 0x3FF4001C

.section .text
.global app_main

app_main:
    entry a1, 32

    movi a6, UART_FIFO
    movi a7, UART_STATUS
    movi a3, msg

loop:
    l8ui a2, a3, 0
    beqz a2, exit

wait_fifo:
    l32i a4, a7, 0
    extui a4, a4, 16, 8      # TXFIFO count
    movi a5, 126             # MAX FIFO buff len
    bge a4, a5, wait_fifo

    s8i a2, a6, 0            # write byte
    addi a3, a3, 1
    j loop

exit:
    j exit
