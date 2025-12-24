// Arm Thumb assembly for Cortex-M4 microcontroller
.syntax unified
.cpu cortex-m4
.thumb

// Global memory locations.
.global vtable
.global reset_handler

// declare variables (a, b) in .data section and (c) in .bss section
    .section .data
    .align 2    // 4-byte alignment
a:  .word 10
b:  .word 20
// c in .bss section
    .section .bss
    .align 2
c:  .space 4

// .text section for code
.section .text
.thumb_func

// Reset handler function
.type reset_handler, %function
reset_handler:

    // Initialize the stack pointer
    ldr r0, =_estack
    mov sp, r0

    // Copy .data from FLASH to RAM
    ldr r1, =_sdata
    ldr r2, =_edata
    ldr r3, =_sidata
    cmp r1, r2
    bcs data_is_empty   // branch if .data is empty
copy_data_loop:
    ldr  r4, [r3], #4      // load from source (Flash), then increment r3
    str  r4, [r1], #4      // store to destination (RAM), then increment r1
    cmp  r1, r2
    bcc  copy_data_loop   // branch while (r1 < r2)
data_is_empty:

    // Zero initialize .bss section
    ldr r1, =_sbss
    ldr r2, =_ebss
    mov r3, #0
    cmp r1, r2
    bcs bss_is_empty    // branch if .bss is empty
bss_loop:
    str  r3, [r1], #4     
    cmp  r1, r2
    bcc  bss_loop    // branch while (r1 < r2)
bss_is_empty:

    /* For demonstration, we will perform the logic of main here */
    // Assume a and b are already defined in .data section and c is defined in .bss section
    // Carries out:
    // if (a - b) < 0
    //     c = 1;
    // else
    //     c = 0;
    /* Start of main logic ------------------------------------ */
    ldr r0, =a
    ldr r1, =b
    ldr r2, [r0]        // load a
    ldr r3, [r1]        // load b
    sub r4, r2, r3      // r4 = a - b
    cmp r4, #0
    blt r4_lt_0       // branch if r4 less than 0
r4_ge_0:         // r4 Greater or Equal 0
    mov r4, #0
    b jump_to_store
r4_lt_0:
    mov r4, #1
jump_to_store:
    ldr r0, =c
    str r4, [r0]        // store result in c
    /* End of main logic -------------------------------------- */
    
halt:
    b halt

.size reset_handler, .-reset_handler

// Vector table
.section .isr_vector, "a", %progbits
.align 2    // 4-byte alignment
.type vtable, %object
vtable:
    .word   _estack                /* Initial Stack Pointer */
    .word   reset_handler          /* Reset Handler */
    /* To add handlers later */
.size vtable, .-vtable