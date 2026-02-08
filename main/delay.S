    .section .text
    # we use vTaskDelay so Watchdog doesn't trigger with IDLE
    .extern vTaskDelay
.global delay

delay:
    entry a1, 32 
    movi a10, 1
    call8 vTaskDelay
    retw
