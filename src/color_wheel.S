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

.data

.align 4
rotation_steps:		.word 400
timer_event_count: 	.word 1
calibration_state:	.word case_calibrate_start
calibrate_steps_in_hall:	.word 0

.text
@speed_in_ms: 		.word 2
speed_in_ms: 		.word 40

addr_rotation_steps: 	.word rotation_steps
addr_timer_event_count: .word timer_event_count
addr_calibration_state:	.word calibration_state
addr_calibrate_steps_in_hall: .word calibrate_steps_in_hall

.global color_wheel_init
.global colow_wheel_set_enable
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
@@@ Enable the color wheel
@@@ Inputs: r0 >= 1 -> enabled
@@@			r0 == 0 -> disabled
@@@ Return: None
colow_wheel_set_enable:
	cmp r0, #0
	orr r0, r0, #0x01 << nRSTCW_PIN
	strne r0, [rGPIO, #GPSET0]		@ Enable the motor driver
	streq r0, [rGPIO, #GPCLR0]		@ Disable the motor driver
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Calibrate the color-wheel with the hall-sensor. Call this in the beggining of the program
@@@ Inputs: None
@@@ Return: None
color_wheel_calibrate:
	push {r4, lr}

	ldr r0, addr_timer_event_count
	ldr r1, [r0]
	subs r1, #1
	str r1, [r0]
	bne color_wheel_calibrate_end 	@ If the minimum waiting time is not over: cancel

	@ Reset the timer event count
	ldr r1, speed_in_ms
	str r1, [r0]

	ldr r4, addr_calibration_state
	ldr pc, [r4]

	case_calibrate_start:
		ldr r0, [rGPIO, #GPLEV0]
		ands r0, #1 << nHallCW_PIN	@ Check if the wheel is already at the hall sensor

		mov r0, #1 << DirCW_PIN
		str r0, [rGPIO, #GPCLR0]		@ Set the direction to clockwise

		ldreq r0, =case_hall_already_active		@ Hall == 0 : Is active
		ldrne r0, =case_calibrate_before_hall	@ Hall != 1 : Not active
		str r0, [r4]	@ Save for the next timer event in the calibration state
		mov pc, r0

	case_hall_already_active:
		bl color_wheel_step
		cmp r0, #0
		bne color_wheel_calibrate_end

 		ldr r0, [rGPIO, #GPLEV0]
		ands r0, #1 << nHallCW_PIN

		@ HallSensor == 0 -> jump to the end
		beq color_wheel_calibrate_end

		@ Else jump in the next call to the next switch case
		ldr r0, =case_calibrate_before_hall
		str r0, [r4]
		b color_wheel_calibrate_end

	case_calibrate_before_hall:
		bl color_wheel_step
		cmp r0, #0
		bne color_wheel_calibrate_end

		ldr r0, [rGPIO, #GPLEV0]
		ands r0, #1 << nHallCW_PIN

		@ HallSensor == 1 -> Go to end
		bne color_wheel_calibrate_end

		@ HallSensor == 0 -> Next case
		ldr r0, =case_calibrate_at_hall
		str r0, [r4]
		b color_wheel_calibrate_end

	case_calibrate_at_hall:
		bl color_wheel_step
		cmp r0, #0
		bne color_wheel_calibrate_end

		ldr r0, addr_calibrate_steps_in_hall
		ldr r1, [r0]
		add r1, #1
		str r1, [r0]

		ldr r0, [rGPIO, #GPLEV0]
		ands r0, #1 << nHallCW_PIN

		@ HallSensor == 0 -> Go to end
		beq color_wheel_calibrate_end

		@ HallSensor == 1 -> Next case
		mov r0, #1 << DirCW_PIN
		str r0, [rGPIO, #GPSET0]		@ Set the direction to counterclockwise

		ldr r0, =case_calibrate_after_hall
		str r0, [r4]
		b color_wheel_calibrate_end

	case_calibrate_after_hall:
		bl color_wheel_step
		cmp r0, #0
		bne color_wheel_calibrate_end

		ldr r0, addr_calibrate_steps_in_hall
		ldr r1, [r0]
		subs r1, #2
		str r1, [r0]

		bpl color_wheel_calibrate_end

		mov r0, #1 << DirCW_PIN
		str r0, [rGPIO, #GPCLR0]		@ Set the direction to clockwise

		ldr r0, =color_wheel_calibrate_end
		str r0, [r4]

	color_wheel_calibrate_end:
		pop {r4, lr}
		bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Make 400 Steps wiht the color-wheel. This is exactly a rotation of 90 degrees
@@@ Inputs: None
@@@ Return: r0 - The remaining steps
color_wheel_rotate90:
	push {r4, lr}
	ldr r4, addr_rotation_steps

	ldr r0, addr_timer_event_count
	ldr r1, [r0]
	subs r1, #1
	str r1, [r0]
	bne color_wheel_rotate90_end 	@ If the minimum waiting time is not over: cancel

	@ Reset the timer event count
	ldr r1, speed_in_ms
	str r1, [r0]

	bl color_wheel_step
	cmp r0, #0
	bgt color_wheel_rotate90_end

	ldr r0, [r4]
	subs r0, #1
	str r0, [r4]

	bgt color_wheel_rotate90_end

	color_wheel_rotate90_reset:
		mov r0, #400
		str r0, [r4]

	color_wheel_rotate90_end:

		ldr r0, [r4]
		pop {r4, lr}
		bx lr


@@@ -----------------------------------------------------------------------------------------
@@@ Make a step with the color wheel
@@@ Inputs: None
@@@ Return: r0 == 0: Set to LOW, r0 > 0: Set to HIGH
color_wheel_step:
	ldr r0, [rGPIO, #GPLEV0]
	ands r0, #1 << StepCW_PIN
	mov r0, #1 << StepCW_PIN
	streq r0, [rGPIO, #GPSET0]
	strne r0, [rGPIO, #GPCLR0]
	movne r0, #0

	bx lr


















