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

	.equ SLEEP_TIME_US,	20000

.data
msg_hex: .asciz "%x\n"

.text

test: .word TEST

.global color_wheel_calibrate
.global color_wheel_rotate90

color_wheel_calibrate:
	push {r4, r5, lr}
	mov r4, r0
	mov r5, #200

	ldr r1, [r4, #GPCLR0]
	orr r1, r1, #0x01 << pin_DirCW	// Set direction to clockwise
	orr r1, r1, #0x01 << pin_nRSTCW	// Enable the motor driver
	str r1, [r4, #GPCLR0]

cw_before_hall_loop:
	bl color_wheel_step

	ldr r1, [r4, #GPLEV0]
	ands r1, r1, #0x01 << pin_nHallCW
	bne cw_before_hall_loop

cw_at_hall_loop:
	bl color_wheel_step
	bl color_wheel_step
	sub r5, r5, #1

	ldr r1, [r4, #GPLEV0]
	ands r1, r1, #0x01 << pin_nHallCW
	beq cw_at_hall_loop

cw_after_hall_loop:
	bl color_wheel_step
	subs r5, r5, #1
	bne cw_after_hall_loop

	pop {r4, r5, lr}
	bx lr

color_wheel_rotate90:
	bx lr

color_wheel_step:
	push {lr}

	ldr r1, [r4, #GPSET0]
	orr r1, r1, #0x01 << pin_StepCW
	str r1, [r4, #GPSET0]

	ldr r0, #SLEEP_TIME_US
	bl usleep

	ldr r1, [r4, #GPCLR0]
	orr r1, r1, #0x01 << pin_StepCW
	str r1, [r4, #GPCLR0]

	ldr r0, #SLEEP_TIME_US
	bl usleep

	pop {lr}
	bx lr


















