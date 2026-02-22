# skforthESP32 
Implementation of skforth (my Forth system) targeting the ESP32 microcontroller.
This version exists because the main skforth project is currently more Linux centric, so this repo focuses on running it directly on embedded 
ESP32 hardware.

## Target hardware
Tested on ESPLAY ESP32 (ESP32-WROVER module):
- Dual-core Xtensa ESP32
- 16MB SPI Flash / 8MB PSRAM
- UART console

## Build / Flash / Monitor

Requires ESP-IDF.
(You can use other serial consoles to access the interpreter; e.g. putty )

commands: 
```text
    idf.py build flash
    idf.py monitor
```

# Developer Notes

For some insight into the arquiteture and design decisions of Skforth's internals the [DEV.md](./DEV.md) file is available.
