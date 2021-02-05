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
	.equ pin_feeder,	19

@@@ Register to set the pin on and off ------------------------------------------------------
	.equ GPSET0,		0x1C
	.equ GPCLR0,		0x28

.text

.global set_feeder_on
.global set_feeder_off

@@@ -----------------------------------------------------------------------------------------
@@@ This method sets the feeder to on
@@@ Inputs: None
@@@ Return: None
set_feeder_on:
	ldr r1, [rGPIO, #GPSET0]
	orr r1, r1, #0x01 << pin_feeder
	str r1, [rGPIO, #GPSET0]

	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ This method sets the feeder to off
@@@ Inputs: None
@@@ Return: None
set_feeder_off:
	ldr r1, [rGPIO, #GPCLR0]
	orr r1, r1, #0x01 << pin_feeder
	str r1, [rGPIO, #GPCLR0]

	bx lr
