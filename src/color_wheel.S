//----------------------------------------------------------------
// project: 	M&M Sortmachine
// group members:
//		- Demiroez, Dilara
//		- Gonther, Levin
//		- Grajczak, Benjamin
//		- Pfister, Marc
//  target:	 	Raspberry Pi Zero
//    date:	 	2020/02/01
// version: 	1.0.0
//----------------------------------------------------------------
// This document deals with the following tasks:
//		- Method to calibrate the color wheel
//		- Method to roate the color wheel in 90° steps
//----------------------------------------------------------------

// Pins of the Color-Wheel ---------------------------------------
	.equ pin_StepCW,	13
	.equ pin_DirCW,		16
	.equ pin_nRSTCW,	17

// Pins for the Hallsensor ---------------------------------------
	.equ pin_nHallCW,	20

//  Register offsets to set pins on and off ----------------------
	.equ GPSET0,		0x1C
	.equ GPCLR0,		0x28
	.equ GPLEV0,		0x34

	.equ SLEEP_TIME_US,	2000

//  Renamimg registers -------------------------------------------
	rGPIO	.req r10

.data
msg_hex: .asciz "%x\n"

.text

.global color_wheel_calibrate
.global color_wheel_rotate90

color_wheel_calibrate:
	push {r4, lr}
	mov r4, #200

	ldr r0, [rGPIO, #GPCLR0]
	orr r0, r0, #0x01 << pin_DirCW	// Set direction to clockwise
	orr r0, r0, #0x01 << pin_nRSTCW	// Enable the motor driver
	str r0, [rGPIO, #GPCLR0]

cw_before_hall_loop:
	bl color_wheel_step

	ldr r0, [rGPIO, #GPLEV0]
	ands r0, r0, #0x01 << pin_nHallCW
	bne cw_before_hall_loop

cw_at_hall_loop:
	bl color_wheel_step
	bl color_wheel_step
	sub r4, r4, #1

	ldr r0, [rGPIO, #GPLEV0]
	ands r0, r0, #0x01 << pin_nHallCW
	beq cw_at_hall_loop

cw_after_hall_loop:
	bl color_wheel_step
	subs r4, r4, #1
	bne cw_after_hall_loop

	pop {r4, lr}
	bx lr

color_wheel_rotate90:
	push {r4, lr}
	mov r4, #400

cw_rotate90_loop:
	bl color_wheel_step
	subs r4, #1
	bne cw_rotate90_loop

	pop {r4, lr}
	bx lr

color_wheel_step:
	push {lr}

	ldr r0, [rGPIO, #GPSET0]
	orr r0, r0, #0x01 << pin_StepCW
	str r0, [rGPIO, #GPSET0]

	mov r0, #SLEEP_TIME_US
	bl usleep

	ldr r0, [rGPIO, #GPCLR0]
	orr r0, r1, #0x01 << pin_StepCW
	str r0, [rGPIO, #GPCLR0]

	mov r0, #SLEEP_TIME_US
	bl usleep

	pop {lr}
	bx lr


















