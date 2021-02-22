@@@ -----------------------------------------------------------------------------------------
@@@ Project:	M&M Sortingmachine
@@@  Target:	Raspberry Pi Zero
@@@	   Date:	2021/02/04
@@@ Group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ -----------------------------------------------------------------------------------------
@@@ With this document its possible to control the hardware of the co-processor.
@@@ For this task it provides following methods:
@@@		- Function to let the co-processor sleep
@@@		- Function to wake the co-processor up
@@@ 	- Function to read the color bits
@@@ -----------------------------------------------------------------------------------------

@@@ Renaming registers ----------------------------------------------------------------------
	rGPIO	.req r10

@@@ Pins definition for the co-processor ----------------------------------------------------
	.equ colorBit1_PIN,		22
	.equ colorBit2_PIN,		23
	.equ colorBit3_PIN,		24
	.equ nSLP_PIN,			27	@ 0 = Sleep, 1 = Wakeup

	.equ colorBit1_IO_BIT,	6
	.equ colorBit2_IO_BIT,	9
	.equ colorBit3_IO_BIT,	12
	.equ nSLP_IO_BIT,		21

@@@ Offsets for the GPIO Registers ----------------------------------------------------------
	.equ GPFSEL2, 	0x08
	.equ GPSET0,	0x1C
	.equ GPCLR0,	0x28
	.equ GPLVL0,	0x34

.text

.global cop_init
.global cop_wakeup
.global cop_sleep
.global cop_read_color

@@@ -----------------------------------------------------------------------------------------
@@@ Wake up the Co-Processor (Sets the nSLP-Pin to HIGH)
@@@ Inputs: None
@@@ Return: None
cop_init:
	push {lr}
	ldr r0, [rGPIO, #GPFSEL2]

	bic r0, r0, #0b111 << colorBit1_IO_BIT
	bic r0, r0, #0b111 << colorBit2_IO_BIT
	bic r0, r0, #0b111 << colorBit3_IO_BIT

	bic r0, r0, #0b111 << nSLP_IO_BIT
	orr r0, r0, #0b001 << nSLP_IO_BIT

	str r0, [rGPIO, #GPFSEL2]

	bl cop_sleep
	pop {lr}
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Wake up the Co-Processor (Sets the nSLP-Pin to HIGH)
@@@ Inputs: None
@@@ Return: None
cop_wakeup:
	mov r0, #0x01 << nSLP_PIN
	str r0, [rGPIO, #GPSET0]
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Let the Co-Processor sleep (Sets the nSLP-Pin to LOW)
@@@ Inputs: None
@@@ Return: None
cop_sleep:
	mov r0, #0x01 << nSLP_PIN
	str r0, [rGPIO, #GPCLR0]
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Reading the color bits and save it as an int
@@@ Inputs: None
@@@ Return:
@@@		r0 == -1: UNKNOWN
@@@		r0 == 0: Red
@@@		r0 == 1: Green
@@@		r0 == 2: Blue
@@@		r0 == 3: Brown
@@@		r0 == 4: Orange
@@@		r0 == 5: Yellow
cop_read_color:
	ldr r0, [rGPIO, #GPLVL0]
	and r0, r0, #0b111 << colorBit1_PIN
	lsr r0, r0, #colorBit1_PIN
	subs r0, r0, #1
	bx lr















