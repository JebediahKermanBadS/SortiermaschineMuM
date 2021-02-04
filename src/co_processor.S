@@@ -----------------------------------------------------------------------------------------
@@@ Project:	M&M Sortingmachine
@@@  Target:	Raspberry Pi Zero
@@@	   Date:	2020/02/04
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
	.equ pin_colorBit1,	22
	.equ pin_colorBit2,	23
	.equ pin_colorBit3,	24
	.equ pin_nSLP,		27

@@@ Offsets for the GPIO Registers ----------------------------------------------------------
	.equ GPSET0,	0x1C
	.equ GPCLR0,	0x28
	.equ GPLVL0,	0x34

.text

.global cop_wakeup
.global cop_sleep
.global cop_read_color

@@@ -----------------------------------------------------------------------------------------
@@@ Wake up the Co-Processor (Sets the nSLP-Pin to HIGH)
@@@ Inputs: None
@@@ Return: None
cop_wakeup:
	ldr r0, [rGPIO, #GPSET0]
	orr r0, r0, #0x01 << pin_nSLP
	str r0, [rGPIO, #GPSET0]
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Let the Co-Processor sleep (Sets the nSLP-Pin to LOW)
@@@ Inputs: None
@@@ Return: None
cop_sleep:
	ldr r0, [rGPIO, #GPCLR0]
	orr r0, r0, #0x01 << pin_nSLP
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
	and r0, r0, #0b111 << pin_colorBit1
	lsr r0, r0, #pin_colorBit1
	subs r0, r0, #0x01
	bx lr















