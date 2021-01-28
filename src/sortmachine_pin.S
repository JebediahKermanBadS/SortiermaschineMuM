@@@ M&M Sortingmachine
@@@ --------------------------------------------------------------
@@@ group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ target:	 Raspberry Pi Zero
@@@	date:	 2020/01/27
@@@	verison: 1.0.0
@@@ --------------------------------------------------------------
@@@ This document deals with the following tasks:
@@@		- Method to initialize this pins as Output/Input
@@@ 	- Method to initialize the timer and interrupts
@@@ --------------------------------------------------------------

@@@ Define the GPIO Function Select Register Offsets -------------
	.equ GPFSEL0, 	0x00
	.equ GPFSEL1, 	0x04
	.equ GPFSEL2, 	0x08
@@@ --------------------------------------------------------------

@@@ --------------------------------------------------------------
@@@ Start Data Section -------------------------------------------
.data
msg_hex: .asciz "%xh\n"

.align 4
gpio_outputdef_fsel0: 	@ 0000 0000 0010 0100 1001 0010 0100 0000
				.word 	0x00249240

.align 4
gpio_resetdef_fsel1:	@ 1100 0111 0000 0011 1111 0000 0000 0000
				.word	0xC703F000
gpio_outputdef_fsel1:	@ 0000 1000 0010 0100 0000 0010 0100 1000
				.word 	0x08240248

.align 4
gpio_resetdef_fsel2:	@ 1111 1100 0000 0000 0000 0000 0000 0000
				.word	0xFC000000
gpio_outputdef_fsel2:	@ 0000 0000 0010 0100 0000 0000 0000 0000
				.word 	0x00240000

@@@ Start Textsection -------------------------------------------
@@@ -------------------------------------------------------------
.text

.global init_output_input
.global init_timerIR_registers

@@@ --------------------------------------------------------------
@@@ This defines the pins as output/input
@@@ Input paramter:
@@@ 	r0: The virtual gpio address
@@@ Returns: Nothing
@@@ --------------------------------------------------------------
init_output_input:
	push {lr}

@@@ Start defining the first GPIO Function select register -------
	ldr r1, [r0, #GPFSEL0]

	@ Define pins 2-9 as input
	@ Pin 0 and 1 is unchanged
	and r1, r1, #0x3F //11 1111

	@ Define pins 2-7 as output
	@ Pin 0 and 1 is unchanged
	ldr r2, =gpio_outputdef_fsel0
	ldr r2, [r2]
	orr r1, r1, r2

	str r1, [r0, #GPFSEL0]
@@@ --------------------------------------------------------------

@@@ Start defining of the second GPIO Function select register ---
	ldr r1, [r0, #GPFSEL1]

	@ Clear the pins used in the machine, dont change others
	ldr r2, =gpio_resetdef_fsel1
	ldr r2, [r2]
	and r1, r1, r2

	@ Set the bits for outputs, dont change inputs ot other pins
	ldr r2, =gpio_outputdef_fsel1
	ldr r2, [r2]
	orr r1, r1, r2

	str r1, [r0, #GPFSEL1]
@@@ --------------------------------------------------------------

@@@ Start defining of the third GPIO Function select register ----
	ldr r1, [r0, #GPFSEL2]

	@ Clear the pins used in the machine, dont change others
	ldr r2, =gpio_resetdef_fsel2
	ldr r2, [r2]
	and r1, r1, r2

	@ Set the bits for outputs, dont change inputs ot other pins
	ldr r2, =gpio_outputdef_fsel2
	ldr r2, [r2]
	orr r1, r1, r2

	str r1, [r0, #GPFSEL2]
@@@ --------------------------------------------------------------

	pop {lr}
	bx lr


@@@ --------------------------------------------------------------
@@@ This function initializes the timer and interrupts
@@@ Input paramter:
@@@ 	r0: The virtual memory address
@@@ Returns: Nothing
@@@ --------------------------------------------------------------
init_timerIR_registers:
	push {lr}

	mov r1, #1
	str r1, [r0, #0x18]

	ldr r0, =msg_hex
	ldr r1, [r0, #0x408]
	mov r4, r1
	bl printf

	orr r4, r4, #0b101 << 5
	str r4, [r0, #0x408]

	ldr r0, =msg_hex
	mov r1, r4
	bl printf

	ldr r0, =msg_hex
	ldr r1, [r0, #0x408]
	bl printf

	ldr r1, [r0, #0x218]
	orr r1, r1, #0x01
	@str r1, [rTIMER, #0x218]

	ldr r1, [r0, #0x218]
	ldr r0, =msg_hex
	bl printf

	pop {lr}
	bx lr

@@@ --------------------------------------------------------------


















