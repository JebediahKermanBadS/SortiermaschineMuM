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
@@@		- Method to calibrate the color wheel
@@@		- Method to roate the color wheel in 90° steps
@@@ -----------------------------------------------------------------------------------------

@@@ Renamimg registers ----------------------------------------------------------------------
	rGPIO	.req r10

@@@ Pins of the Color-Wheel -----------------------------------------------------------------
	.equ StepCW_PIN,	13
	.equ DirCW_PIN,		16  @ Pin to set the direction, (0 = clockwise, 1 = counterclockwise)
	.equ nRSTCW_PIN,	17  @ 0 = Inactivate, 1 = Active
	.equ nHallCW_PIN,	20  @ 0 = There is something, 1 = There is nothing

@@@ Pins for the input/outputs --------------------------------------------------------------
	.equ StepCW_IO_BIT,		9
	.equ DirCW_IO_BIT,		18
	.equ nRSTCW_IO_BIT,		21
	.equ nHallCW_IO_BIT,	0

@@@ Register offsets to set pins on and off -------------------------------------------------
	.equ GPFSET1, 	0x04
	.equ GPFSET2,	0x08
	.equ GPSET0,	0x1C
	.equ GPCLR0,	0x28
	.equ GPLEV0,	0x34

	.equ OUTPUT,	0b001

.text

speed_in_us: .word 2000

.global color_wheel_init
.global color_wheel_calibrate
.global color_wheel_rotate90

@@@ -----------------------------------------------------------------------------------------
@@@ Initialize the pins for the color wheel as input/output
@@@ Inputs: None
@@@ Return: None
color_wheel_init:
	ldr r0, [rGPIO, #GPFSET1]
	bic r0, r0, #0b111 << StepCW_IO_BIT
	orr r0, r0, #OUTPUT << StepCW_IO_BIT

	bic r0, r0, #0b111 << DirCW_IO_BIT
	orr r0, r0, #OUTPUT << DirCW_IO_BIT

	bic r0, r0, #0b111 << nRSTCW_IO_BIT
	orr r0, r0, #OUTPUT << nRSTCW_IO_BIT
	str r0, [rGPIO, #GPFSET1]

	ldr r0, [rGPIO, #GPFSET2]
	bic r0, r0, #0b111 << nHallCW_IO_BIT
	str r0, [rGPIO, #GPFSET2]

	mov r0, #1 << StepCW_PIN
	orr r0, r0, #1 << DirCW_PIN
	orr r0, r0, #1 << nRSTCW_PIN
	str r0, [rGPIO, #GPCLR0]

	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Calibrate the color-wheel with the hall-sensor. Call this in the beggining of the program
@@@ Inputs: None
@@@ Return: None
color_wheel_calibrate:
	push {r4, lr}
	mov r4, #400

	orr r0, r0, #0x01 << nRSTCW_PIN	 // Enable the motor driver
	str r0, [rGPIO, #GPSET0]

	mov r0, #1 << DirCW_PIN			 // Set direction to clockwise
	str r0, [rGPIO, #GPCLR0]

	@@@ If the hall sensor is already active, rotate until the magnet is outside
	cw_hall_already_active:
		bl color_wheel_step
		ldr r0, [rGPIO, #GPLEV0]
		ands r0, r0, #0x01 << nHallCW_PIN
		beq cw_hall_already_active

	@@@ Rotate until the wheel is at the beginning of the hall sensor
	cw_before_hall_loop:
		bl color_wheel_step
		ldr r0, [rGPIO, #GPLEV0]
		ands r0, r0, #0x01 << nHallCW_PIN
		bne cw_before_hall_loop

	@@@ Rotate as long the magnet is in the hall sensor.
	cw_at_hall_loop:
		bl color_wheel_step
		bl color_wheel_step
		sub r4, r4, #1

		ldr r0, [rGPIO, #GPLEV0]
		ands r0, r0, #0x01 << nHallCW_PIN
		beq cw_at_hall_loop

	@@@ Rotate as long the step-counter is at zero
	cw_after_hall_loop:
		bl color_wheel_step
		subs r4, r4, #1
		bne cw_after_hall_loop

	pop {r4, lr}
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Make 400 Steps wiht the color-wheel. This is exactly a rotation of 90 degrees
@@@ Inputs: None
@@@ Return: None
color_wheel_rotate90:
	push {r4, lr}
	mov r4, #400

cw_rotate90_loop:
	bl color_wheel_step
	subs r4, #1
	bne cw_rotate90_loop

	pop {r4, lr}
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Make a step with the color wheel
@@@ Inputs: None
@@@ Return: None
color_wheel_step:
	push {lr}

	mov r0, #1 << StepCW_PIN
	str r0, [rGPIO, #GPSET0]

	ldr r0, speed_in_us
	bl usleep

	mov r0, #1 << StepCW_PIN
	str r0, [rGPIO, #GPCLR0]

	ldr r0, speed_in_us
	bl usleep

	pop {lr}
	bx lr


















