.section .rodata

msg:
.asciz "Hello from ASM skforth ESP32!\n"
sk_handle:
.asciz "skforth>"

.extern uart_print
.extern uart_trygetc
.extern uart_putc
.extern delay

.section .text
.global app_main

.align 4
app_main:
    entry a1, 32

    movi a10, msg
    call8 uart_print

.print_skhandle:
    movi a10, sk_handle
    call8 uart_print
.forever:
    call8 uart_trygetc
    beqi a10, -1, .delay

    call8 uart_putc

    beqi a10, 10, .print_skhandle

.delay:
    call8 delay
    j .forever
