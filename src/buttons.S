@@@ -----------------------------------------------------------------------------------------
@@@ Project:	M&M Sortingmachine
@@@  Target:	Raspberry Pi Zero
@@@ Group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ -----------------------------------------------------------------------------------------
@@@ This document provides methods to init the buttons for the machine
@@@ -----------------------------------------------------------------------------------------

@@@ Renamimg registers ----------------------------------------------------------------------
	rTIMER	.req r9
	rGPIO	.req r10

@@@ Pins of the Buttons ---------------------------------------------------------------------
	.equ pin_nBTN1,		8
	.equ pin_nBTN2,		9
	.equ pin_nBTN3,		10

@@@ Define the offset for the GPIO Registers ------------------------------------------------
	.equ GPFSET0, 	0x00
	.equ GPFSET1, 	0x04

	.equ GPEDS0,	0x40
	.equ GPREN0,	0x4C
	.equ GPFEN0,	0x58
	.equ GPHEN0,	0x64
	.equ GPLEN0,	0x70

.text

.global buttons_init

@@@ -----------------------------------------------------------------------------------------
@@@ Enable the buttons
@@@ Inputs: None
@@@ Return: None
buttons_init:

	@ Disable gpio interrupts
	mov r0, #0b1111 << 17
	str r0, [rTIMER, #0x220]

	ldr r0, [rGPIO, #GPFSET0]

	@ Set the button at pin 8 as input
	bic r0, #0b111 << 24

	@ Set the button at pin 9 as input
	bic r0, #0b111 << 27

	str r0, [rGPIO, #GPFSET0]

	@ Set the button at pin 10 as input
	ldr r0, [rGPIO, #GPFSET1]
	bic r0, #0b111
	str r0, [rGPIO, #GPFSET1]

	@ Disable RISING EDGE detect for all buttons
	ldr r0, [rGPIO, #GPREN0]
	bic r0, #0b111 << pin_nBTN1
	str r0, [rGPIO, #GPREN0]

	@ Enable FALLING EDGE detect for all buttons
	ldr r0, [rGPIO, #GPFEN0]
	orr r0, #0b111 << pin_nBTN1
	str r0, [rGPIO, #GPFEN0]

	@ Disable HIGH detect for all buttons
	ldr r0, [rGPIO, #GPHEN0]
	bic r0, #0b111 << pin_nBTN1
	str r0, [rGPIO, #GPHEN0]

	@ Disable LOW detect for all buttons
	ldr r0, [rGPIO, #GPLEN0]
	bic r0, #0b111 << pin_nBTN1
	str r0, [rGPIO, #GPLEN0]

	@ Clear pending event detect bit
	mov r0, #0b111 << pin_nBTN1
	str r0, [rGPIO, #GPEDS0]

	bx lr
