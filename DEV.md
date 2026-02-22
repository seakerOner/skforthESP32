# SKFORTHESP32 - Developer Notes

SkforthESP32 is a **bare-metal Forth system implementation for the ESP32 microcontroller**.
It was developed to run efficiently on embedded hardware, in contrast to the main Skforth project which is Linux-centric.

Key design goals:

- **Deterministic execution** of Forth “words” using IRAM to eliminate cache misses.
- **Efficient register usage** with Xtensa register windows to reduce memory traffic and stack operations.
- **Separation of concerns** between system-level I/O/lexer routines and the VM / word execution domain.
- **Predictable stack** access via invariant register offsets for core operations (spop, spush, slen).

This document explains the **internal architecture**, **register conventions**, and **design decisions*.

## Execution Model (Xtensa Register Windows)

skforthESP32 separates execution into **two domains**, exploiting Xtensa register windows:

---
### 1 - System / Lexer / UART Domain

Rooted at `app_main` (call0 ABI), this domain handles:
    - UART initialization and console I/O
    - Input buffering
    - Lexing user input into tokens

**Calling conventions**:
    - UART helpers (`uart_print`, `uart_putc`, `uart_trygetc`, `uart_printn`) use `call8`.
    - Expected invariant register offset: **8**

Invariant registers in this domain:
    - a2                          -> input_len
    - a3                          -> input_buffer
    - a14 (logical a6 @ offset 8) -> UART FIFO address
    - a15 (logical a7 @ offset 8) -> UART status address

> Note:
> All UART subroutines assume offset 8. This tree never mixes with the VM window chain.

### 2 - VM / Word Execution Domain

Entered via:

```text
    call0 lexer
          -> jx word_code
```

- `jx` is used instead of `call` to **avoid implicit window rotation**.
- Each word typically begins with a **wrapper subroutine**:

```assembly
    call8 word_wrapper
```

A word wrapper is used so the subroutines return registers are accessible
from the wrapper via known logical register offsets.

In some word definitions (e.g. drop, depth) where only one subroutine call is needed no word wrapper is used 

Stack helpers are invoked using:
```assembly
    call4 spop
    call4 spush
```

Expected invariant register offset: **12**

Invariant registers in this domain:
    - a22 (logical a10 @ offset 12) -> stack pointer index
    - a23 (logical a11 @ offset 12) -> stack base address

Stack helpers depend on this offset being stable.

### Flow Diagram (simplified)

```text
app_main (call0)
 ├─ call8 init_uart (offset 8)
 ├─ call12 init_stack
 └─ call0 lexer
       └─ jx word_code
             └─ call8 word_wrapper
                   ├─ call4 spop / spush
                   └─ retw
```

## Stack Helpers

- `spop` / `spush` / `slen`
- All reside in IRAM
- Require the VM offset (12) to correctly read/write stack
- Stored values are 32-bit. Maximum stack depth is 8 entries.

## Dictionary / Words

All Words stored in **IRAM** for speed and predictability
- Maximum word size: 32 bytes
- Word structure:

```text
offset 0   : link prev word (  4     )
offset 4   : is_immediate   (  1     )
offset 5   : name_len       (  1     )
offset 6-7 : padding
offset 8   : code addr      (  4     )
offset 12  : name ascii     ( 20 max )
```

> Notes:
> Wrappers (`call8`) are used so that return registers can be accessed from stack helper subroutines.
> Simple words (`drop`, `depth`) use `call12` directly for efficiency.

## Memory Layout

- **IRAM**: Word code, stack helpers, core VM operations
- **BSS**: Stack array, dictionary pointers
- **RODATA**: Word names, error messages, prompt

## Development notes

- Word wrappers and offsets are critical for **register window consistency**. 
- Stack helpers **must always use the expected VM offset (12)**.
- UART subroutines **must always use the expected system offset (8)**.
- IRAM storage is chosen for **speed and predictability**, avoiding cache misses.

# References 

- Xtensa ISA
    - <https://dl.espressif.com/github_assets/espressif/xtensa-isa-doc/releases/download/latest/Xtensa.pdf>
- ESP32 TRM
    - <https://documentation.espressif.com/esp32_technical_reference_manual_en.pdf>
