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
@@@ This document deals with the following tasks:
@@@		- Method to set the feeder on
@@@	 	- Method to set the feeder off
@@@ -----------------------------------------------------------------------------------------

@@@ Renaming registers ----------------------------------------------------------------------
	rGPIO	.req r10

@@@ Pin of the Feeder -----------------------------------------------------------------------
	.equ feeder_pin,	19
	.equ feeder_io_bit,	27

@@@ Register to set the pin on and off ------------------------------------------------------
	.equ GPFSEL1,		0x04
	.equ GPSET0,		0x1C
	.equ GPCLR0,		0x28

.text

.global feeder_init
.global feeder_on
.global feeder_off

@@@ -----------------------------------------------------------------------------------------
@@@ This method initializes the feeder (Define the pin as outpu)
@@@ Inputs: None
@@@ Return: None
feeder_init:
	ldr r0, [rGPIO, #GPFSEL1]
	bic r0, r0, #0b111 << feeder_io_bit
	orr r0, r0, #0b001 << feeder_io_bit
	str r0, [rGPIO, #GPFSEL1]
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ This method sets the feeder to on
@@@ Inputs: None
@@@ Return: None
feeder_on:
	ldr r0, [rGPIO, #GPSET0]
	orr r0, r0, #0x01 << feeder_pin
	str r0, [rGPIO, #GPSET0]

	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ This method sets the feeder to off
@@@ Inputs: None
@@@ Return: None
feeder_off:
	ldr r0, [rGPIO, #GPCLR0]
	orr r0, r0, #0x01 << feeder_pin
	str r0, [rGPIO, #GPCLR0]

	bx lr
