@@@ -----------------------------------------------------------------------------------------
@@@ Project:	M&M Sortingmachine
@@@  Target:	Raspberry Pi Zero
@@@ Group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ -----------------------------------------------------------------------------------------
@@@ This document deals with the following tasks:
@@@		- Method to initialize the color wheel
@@@		- Method to enable the color wheel
@@@		- Method to calibrate the color wheel
@@@		- Method to rotate the color wheel in 90° steps
@@@ -----------------------------------------------------------------------------------------

@@@ Renaming registers ----------------------------------------------------------------------
	rGPIO	.req r10

@@@ Pins of the Color-Wheel -----------------------------------------------------------------
	.equ StepCW_PIN,	13
	.equ DirCW_PIN,		16  @ Pin to set the direction, (0 = clockwise, 1 = counterclockwise)
	.equ nRSTCW_PIN,	17  @ 0 = Inactivate, 1 = Active
	.equ nHallCW_PIN,	20  @ 0 = There is something, 1 = There is nothing

@@@ Pins for the input/output --------------------------------------------------------------
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
speed_in_ms: 		.word 4
@speed_in_ms: 		.word 40

addr_rotation_steps: 	.word rotation_steps
addr_timer_event_count: .word timer_event_count
addr_calibration_state:	.word calibration_state
addr_calibrate_steps_in_hall: .word calibrate_steps_in_hall

.global color_wheel_init
.global color_wheel_set_enable
.global color_wheel_calibrate
.global color_wheel_rotate90
.global color_wheel_reset_rotation
.global color_wheel_calibration_reset

@@@ -----------------------------------------------------------------------------------------
@@@ Initialize the pins for the color wheel as input/output
@@@ Inputs: None
@@@ Return: None
color_wheel_init:
	ldr r0, [rGPIO, #GPFSET1]

	@ Set the step pin to OUTPUT
	bic r0, r0, #0b111 << StepCW_IO_BIT
	orr r0, r0, #OUTPUT << StepCW_IO_BIT

	@ Set the direction pin to OUTPUT
	bic r0, r0, #0b111 << DirCW_IO_BIT
	orr r0, r0, #OUTPUT << DirCW_IO_BIT

	@ Set the reset pin to OUTPUT
	bic r0, r0, #0b111 << nRSTCW_IO_BIT
	orr r0, r0, #OUTPUT << nRSTCW_IO_BIT
	str r0, [rGPIO, #GPFSET1]

	@ Set the HallSensor pin to INPUT
	ldr r0, [rGPIO, #GPFSET2]
	bic r0, r0, #0b111 << nHallCW_IO_BIT
	str r0, [rGPIO, #GPFSET2]

	@ Set the stepPin, directionPin and resetPin to LOW
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
color_wheel_set_enable:
	cmp r0, #0
	orr r0, r0, #0x01 << nRSTCW_PIN
	strne r0, [rGPIO, #GPSET0]		@ Enable the motor driver
	streq r0, [rGPIO, #GPCLR0]		@ Disable the motor driver

	mov r0, #1 << DirCW_PIN
	str r0, [rGPIO, #GPCLR0]		@ Set the direction to clockwise

	bx lr


@@@ -----------------------------------------------------------------------------------------
@@@ Calibrate the color-wheel with the hall-sensor. Call this in the beggining of the program
@@@ Inputs: None
@@@ Return: r0 == 0 -> calibration is done
@@@			r0 == 1 -> still calibrating
color_wheel_calibrate:
	push {r4, lr}

	@ The timer is calling this method every time he counted to 0. This is to fast,
	@ so we have to count how often the method is called and cancel the execution if the count
	@ is not high enough
	ldr r0, addr_timer_event_count
	ldr r1, [r0]
	subs r1, #1
	str r1, [r0]
	bne color_wheel_calibrate_not_finished 	@ If the minimum waiting time is not over: cancel

	@ Reset the timer event count
	ldr r1, speed_in_ms
	str r1, [r0]

	@ Load the current case of the calibration.
	@ ! DO NOT CHANGE THE REGISTER r4 IN THIS METHOD !
	mov r0, #0
	ldr r4, addr_calibration_state
	ldr pc, [r4]

	@ Default starting case
	case_calibrate_start:
		@ Check if the wheel is already at the hall sensor
		ldr r0, [rGPIO, #GPLEV0]
		ands r0, #1 << nHallCW_PIN

		ldreq r0, =case_hall_already_active		@ Hall == 0 : Is active
		ldrne r0, =case_calibrate_before_hall	@ Hall != 1 : Not active

		mov r1, #1 << DirCW_PIN

		@ Set the direction to clockwise if the wheel is before the hallsensor
		strne r1, [rGPIO, #GPCLR0]

		@ Set the direction to counterclockwise if the wheel is at the hallsensor
		streq r1, [rGPIO, #GPSET0]

		str r0, [r4]		@ Save the next case address in 'calibration_state'
		mov pc, r0

	case_hall_already_active:
		bl color_wheel_step

		@ Check if the step is finished
		cmp r0, #0
		bne color_wheel_calibrate_not_finished

		@ Read the level of the hall sensor and cmp with #0
 		ldr r0, [rGPIO, #GPLEV0]
		ands r0, #1 << nHallCW_PIN

		@ HallSensor == 0 -> jump to the end
		beq color_wheel_calibrate_not_finished

		@ Set the direction to clockwise
		mov r1, #1 << DirCW_PIN
		strne r1, [rGPIO, #GPCLR0]

		@ Save the address for the next case and jump to the end
		ldr r0, =case_calibrate_before_hall
		str r0, [r4]
		b color_wheel_calibrate_not_finished

	case_calibrate_before_hall:
		bl color_wheel_step

		@ Check if the step is finished
		cmp r0, #0
		bne color_wheel_calibrate_not_finished

		@ Read the level of the hall sensor and cmp with #0
		ldr r0, [rGPIO, #GPLEV0]
		ands r0, #1 << nHallCW_PIN

		@ HallSensor == 1 -> Go to end
		bne color_wheel_calibrate_not_finished

		@ HallSensor == 0 -> Next case
		ldr r0, =case_calibrate_at_hall
		str r0, [r4]
		b color_wheel_calibrate_not_finished

	case_calibrate_at_hall:
		bl color_wheel_step

		@ Check if the step is finished
		cmp r0, #0
		bne color_wheel_calibrate_not_finished

		@ Count every step while the wheel is in the hall sensor
		ldr r0, addr_calibrate_steps_in_hall
		ldr r1, [r0]
		add r1, #1
		str r1, [r0]

		@ Read the level of the hall sensor and cmp with #0
		ldr r0, [rGPIO, #GPLEV0]
		ands r0, #1 << nHallCW_PIN

		@ HallSensor == 0 -> Go to end
		beq color_wheel_calibrate_not_finished

		@ HallSensor == 1 -> Next case
		mov r0, #1 << DirCW_PIN
		str r0, [rGPIO, #GPSET0]		@ Set the direction to counterclockwise

		@ Store the next case
		ldr r0, =case_calibrate_after_hall
		str r0, [r4]
		b color_wheel_calibrate_not_finished

	case_calibrate_after_hall:
		bl color_wheel_step

		@ Check if the step is finished
		cmp r0, #0
		bne color_wheel_calibrate_not_finished

		@ Remove 2 steps from the counted value. This results in an automatically averaged count.
		@ Cmp it with zero
		ldr r0, addr_calibrate_steps_in_hall
		ldr r1, [r0]
		subs r1, #2
		str r1, [r0]

		@ While the counter is higher than zero repeat this
		bpl color_wheel_calibrate_not_finished

		@ The counter is now zero or lower. Reset the direction of the motor to clockwise
		mov r0, #1 << DirCW_PIN
		str r0, [rGPIO, #GPCLR0]

		@ Set the case for the method to the end label.
		@ If the calibration method is called again, nothing will happen
		ldr r0, =color_wheel_calibrate_end
		str r0, [r4]

		@ Return code, that the calibration is finished
		mov r0, #0
		b color_wheel_calibrate_end

	color_wheel_calibrate_not_finished:
		@ Return code, that the calibration is NOT finished
		ldr r4, addr_calibration_state
		ldr r4, [r4]
		ldr r0, =color_wheel_calibrate_end
		cmp r0, r4
		mov r0, #1
		moveq r0, #0 @ Is finished return code
	color_wheel_calibrate_end:
		pop {r4, lr}
		bx lr

color_wheel_calibration_reset:

	ldr r0, addr_calibration_state
	ldr r1, =case_calibrate_start
	str r1, [r0]

	bx lr


@@@ -----------------------------------------------------------------------------------------
@@@ Make 400 Steps with the color-wheel. This is exactly a rotation of 90 degrees
@@@ Inputs: None
@@@ Return: r0 - The remaining steps
color_wheel_rotate90:
	push {r4, lr}
	ldr r4, addr_rotation_steps

	@ The timer is calling this method every time he counts to 0. This is probably too fast,
	@ so we have to count how often the method is called and cancel the execution if the count
	@ is not high enough
	ldr r0, addr_timer_event_count
	ldr r1, [r0]
	subs r1, #1
	str r1, [r0]
	bne color_wheel_rotate90_end 	@ Cancel

	@ Reset the timer event count
	ldr r1, speed_in_ms
	str r1, [r0]

	@ If the color wheel already did the 400 steps: Do nothing
	ldr r0, [r4]
	cmp r0, #0
	beq color_wheel_rotate90_end

	@ Do step and check if the step is finished (state of the wheel pin has to be LOW)
	bl color_wheel_step
	cmp r0, #0
	bgt color_wheel_rotate90_end

	@ Subtract one from the current steps
	ldr r0, [r4]
	subs r0, #1
	str r0, [r4]

	@ If there are any steps left, jump straight to the end
	@ bgt color_wheel_rotate90_end

	@ If not reset the counter
	@	color_wheel_rotate90_reset:
	@	mov r0, #400
	@	str r0, [r4]

	color_wheel_rotate90_end:

		ldr r0, [r4]
		pop {r4, lr}
		bx lr


@@@ -----------------------------------------------------------------------------------------
@@@ Reset the rotation of the color wheel to rotate 90° again
@@@ Inputs: None
@@@ Return: None
color_wheel_reset_rotation:
	ldr r0, addr_rotation_steps
	mov r1, #400
	str r1, [r0]

	bx lr


@@@ -----------------------------------------------------------------------------------------
@@@ Make a step with the color wheel
@@@ Inputs: None
@@@ Return: r0 == 0: Set to LOW, r0 > 0: Set to HIGH
color_wheel_step:
	@ Read the current level of the step pin and cmp with #0
	ldr r0, [rGPIO, #GPLEV0]
	ands r0, #1 << StepCW_PIN

	@ If currentLevel == LOW (eq): Set it to HIGH
	@ If currentLevel == HIGH (ne): Set it to LOW
	mov r0, #1 << StepCW_PIN
	streq r0, [rGPIO, #GPSET0]
	strne r0, [rGPIO, #GPCLR0]
	movne r0, #0

	bx lr


















