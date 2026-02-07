.section .rodata

msg:
    .asciz "Hello from ASM skforth ESP32!\n"

 .extern uart_print
 .extern uart_getc
 .extern uart_putc

.section .text
.global app_main

.align 4
app_main:
    entry a1, 32

    movi a10, msg
    call8 uart_print

forever:
    call8 uart_getc
    call8 uart_putc

    j forever
