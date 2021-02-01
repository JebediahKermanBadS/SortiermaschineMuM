//----------------------------------------------------------------
// project: 	M&M Sortmachine
// group members:
//		- Demiroez, Dilara
//		- Gonther, Levin
//		- Grajczak, Benjamin
//		- Pfister, Marc
//  target:	 	Raspberry Pi Zero
//    date:	 	2020/02/01
// verison: 	1.0.0
//----------------------------------------------------------------
// This document deals with the following tasks:
//		- Method to set the feeder on
//	 	- Method to set the feeder off
//----------------------------------------------------------------

//  Pin of the Feeder --------------------------------------------
	.equ pin_feeder,	19

//  Register to set the pin on and off ---------------------------
	.equ GPSET0,		0x1C
	.equ GPCLR0,		0x28

.text

.global set_feeder_on
.global set_feeder_off

//----------------------------------------------------------------
// This method sets the feeder to on
// Input paramter:
// 		- r0: Base address of the gpios
// Returns: Nothing
set_feeder_on:
	ldr r1, [r0, #GPSET0]
	mov r2, #0x01
	orr r1, r1, r2, LSL #pin_feeder
	str r1, [r0, #GPSET0]

	bx lr

//----------------------------------------------------------------
// This method sets the feeder to off
// Input paramter:
// 		- r0: Base address of the gpios
// Returns: Nothing
set_feeder_off:
	ldr r1, [r0, #GPCLR0]
	mov r2, #0x01
	orr r1, r1, r2, LSL #pin_feeder
	str r1, [r0, #GPCLR0]

	bx lr
