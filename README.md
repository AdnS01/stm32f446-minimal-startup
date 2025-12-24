# STM32F446 Bare-Metal Minimal Startup

## Objective
This project implements a minimal bare-metal startup sequence for the STM32F446RE to gain precise control and understanding of the execution flow from hardware reset to application code.

By avoiding HAL and CMSIS and using ARM Cortex-M4 assembly with a custom linker script, the project explicitly demonstrates stack initialization, vector table setup, memory section relocation, and controlled startup behavior using the GNU Arm Embedded Toolchain and GDB.

## Features
- ARM Cortex-M4 startup code written in assembly
- Custom linker script defining FLASH and RAM layout
- Simple demo logic to verify correct RAM initialization

## Tools
- GNU Arm Embedded Toolchain (gcc-arm-none-eabi)
- ST-LINK (stlink / st-util)
- GDB (gdb-multiarch)

## Build Instructions

Compile and link the bare-metal startup code for the STM32F446 (Cortex-M4).

```bash
# Compile assembly startup file to object file
arm-none-eabi-gcc -c src/startup_stm32f446.s -o build/startup_stm32f446.o -mcpu=cortex-m4 -mthumb

# Link object file to ELF 
arm-none-eabi-gcc build/startup_stm32f446.o -T linker/stm32f446.ld -nostartfiles -Wl,-Map=build/firmware.map -o build/firmware.elf

# Inspect symbols and memory layout
arm-none-eabi-nm build/firmware.elf
```

Example output from `arm-none-eabi-nm build/firmware.elf`:

```text
20000000 d a
20000004 d b
08000036 t bss_is_empty
0800002e t bss_loop
20000008 b c
08000016 t copy_data_loop
08000022 t data_is_empty
2000000c B _ebss
20000008 D _edata
20020000 R _estack
08000054 t halt
08000050 t jump_to_store
08000046 t r4_ge_0
0800004c t r4_lt_0
08000008 T reset_handler
20000008 B _sbss
20000000 D _sdata
0800007c A _sidata
08000000 R vtable
```

### Interpretation

- `.data` section:
    - `a` and `b` are located in RAM at runtime
    - their initial values are stored in FLASH at `_sidata`

- `.bss` section:
    - `c` is allocated in RAM and zero-initialized by startup code

- `vtable` is correctly placed at `0x08000000`

- `reset_handler` starts at `0x08000008`, as expected

This confirms that the linker script and startup logic are consistent and correct.

## Debugging Instructions

```bash
# Terminal 1: start the ST-LINK GDB server
st-util

# Terminal 2: start GDB with the ELF file
gdb-multiarch build/firmware.elf
```

### Inside GDB

```bash
# Connect GDB to st-util (GDB server)
# `st-util` runs a GDB server on port 4242
target extended-remote :4242

# Reset the STM32 and halt immediately after reset
monitor reset halt

# Load (flash) the ELF file into STM32 Flash memory
load

# Set a breakpoint at the end of the program
break halt

# Reset the STM32 and start execution from the reset vector
monitor reset

# Run the firmware until the breakpoint is reached
continue

# Read 3 words from RAM starting at 0x20000000
# .data section: a, b
# .bss  section: c
x/3wx 0x20000000
```
### Expected RAM values

```text
| Address    | Variable | Expected value           |
| ---------- | -------- | ------------------------ |
| 0x20000000 | a        | 10                       |
| 0x20000004 | b        | 20                       |
| 0x20000008 | c        | 0 or 1 (result of logic) |
```

### Inspect CPU state (registers)

```bash
info registers
```
Example output:

```text
r0      0x20000008      -> address of c
r1      0x20000004      -> address of b
r2      0xa             -> value of a (10)
r3      0x14            -> value of b (20)
r4      0x1             -> computed result
...
sp      0x20020000      -> stack pointer (_estack)
pc      0x08000054      -> halt loop
...
```