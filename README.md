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

commands: 
```text
    idf.py build
    idf.py flash monitor
```

# Docs

- Xtensa ISA
    - <https://dl.espressif.com/github_assets/espressif/xtensa-isa-doc/releases/download/latest/Xtensa.pdf>
- ESP32 TRM
    - <https://documentation.espressif.com/esp32_technical_reference_manual_en.pdf>
