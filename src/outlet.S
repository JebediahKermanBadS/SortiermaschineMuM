@@@ -----------------------------------------------------------------------------------------
@@@ Project:	M&M Sortingmachine
@@@  Target:	Raspberry Pi Zero
@@@	   Date:	2020/04/02
@@@ Group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ -----------------------------------------------------------------------------------------
@@@ -----------------------------------------------------------------------------------------
@@@ With this document its possible to control the Outlet.
@@@ For this task it provides following methods:
@@@		- Function to calibrate the Outlet.
@@@		- Functions to rotate the Outlet in 60 degree Steps
@@@		  clockwise, counterclockwise respectively
@@@ -----------------------------------------------------------------------------------------

@@@ Renamimg registers --------------------------------------------------------------------
	rGPIO	.req r10

@@@ Pins of the Outlet ----------------------------------------------------------------------
	.equ nRSTOut_PIN,		11
	.equ StepOut_PIN,		12
	.equ nHallOutlet_PIN,	21
	.equ DirOut_PIN,		26

	.equ nRSTOut_IO_BIT,		3
	.equ StepOut_IO_BIT,	 	6
	.equ nHallOutlet_IO_BIT,	3
	.equ DirOut_IO_BIT,			18

@@@ Offsets for the GPIO Registers ----------------------------------------------------------
	.equ GPFSEL1, 	0x04
	.equ GPFSEL2, 	0x08
	.equ GPSET0,	0x1C
	.equ GPCLR0,	0x28
	.equ GPLEV0,	0x34

.data

@ offset_flag counts how many times the outlet is rotated in one direction to counter the
@ resulting step offset
.align 4
offset_flag:	.word 0
rotation_steps: 	.word 67
timer_event_count:	.word 2
calibration_state:	.word case_calibrate_start
calibrate_steps_in_hall:	.word 0

.text
speed_in_ms: .word 4

addr_rotation_steps: 	.word rotation_steps
addr_timer_event_count: .word timer_event_count
addr_calibration_state:	.word calibration_state
addr_calibrate_steps_in_hall: .word calibrate_steps_in_hall


.global outlet_init
.global outlet_set_enable
.global outlet_calibrate
.global outlet_rotate_clockwise_initiate
.global outlet_rotate60_clockwise
.global outlet_rotate_counterclockwise_initiate
.global outlet_rotate60_counterclockwise

@@@ -----------------------------------------------------------------------------------------
@@@ This method initialize pins for the outlet
@@@ Inputs: None
@@@ Return: None
outlet_init:
	ldr r0, [rGPIO, #GPFSEL1]

	bic r0, r0, #0b111 << nRSTOut_IO_BIT
	orr r0, r0, #0b001 << nRSTOut_IO_BIT

	bic r0, r0, #0b111 << StepOut_IO_BIT
	orr r0, r0, #0b001 << StepOut_IO_BIT

	str r0, [rGPIO, #GPFSEL1]

	ldr r0, [rGPIO, #GPFSEL2]

	bic r0, r0, #0b111 << nHallOutlet_IO_BIT

	bic r0, r0, #0b111 << DirOut_IO_BIT
	orr r0, r0, #0b001 << DirOut_IO_BIT

	str r0, [rGPIO, #GPFSEL2]

	mov r0, #1 << DirOut_PIN
	orr r0, r0, #1 << StepOut_PIN
	orr r0, r0, #1 << nRSTOut_PIN
	str r0, [rGPIO, #GPCLR0]

	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Enable the outlet
@@@ Inputs: r0 >= 1 -> enabled
@@@			r0 == 0 -> disabled
@@@ Return: None
outlet_set_enable:
	cmp r0, #0
	orr r0, r0, #0x01 << nRSTOut_PIN
	strne r0, [rGPIO, #GPSET0]		@ Enable the motor driver
	streq r0, [rGPIO, #GPCLR0]		@ Disable the motor driver

	mov r0, #1 << DirOut_PIN
	str r0, [rGPIO, #GPCLR0]		@ Set the direction to clockwise

	bx lr

@@@ ----------------------------------------------------------------------------------------
@@@ Calibrate the Outlet to Start Position
@@@ Inputs: None
@@@ Return: r0 == 0 -> calibration is done
@@@			r0 == 1 -> still calibration
outlet_calibrate:
	push {r4, lr}

	@ The timer is calling this method every time he counted to 0. This is probably to fast,
	@ so we have to count how often the method is called and cancel the execution if the count
	@ is not high enough
	ldr r0, addr_timer_event_count
	ldr r1, [r0]
	subs r1, #1
	str r1, [r0]
	bne outlet_calibrate_not_finished 	@ If the minimum waiting time is not over: cancel

	@ Reset the timer event count
	ldr r1, speed_in_ms
	str r1, [r0]

	@ Load the current case of the calibration.
	@ ! DO NOT CHANGE THE REGISTER r4 IN THIS METHOD !
	mov r0, #0
	ldr r4, addr_calibration_state
	ldr pc, [r4]

	case_calibrate_start:
		@ Check if the outlet is already at the hall sensor
		ldr r0, [rGPIO, #GPLEV0]
		ands r0, #1 << nHallOutlet_PIN

		ldreq r0, =case_hall_already_active		@ Hall == 0 : Is active
		ldrne r0, =case_calibrate_before_hall	@ Hall != 1 : Not active
		str r0, [r4]		@ Save the next case address in 'calibration_state'
		mov pc, r0

	case_hall_already_active:
		bl outlet_step
		@ Check if the step is finished
		cmp r0, #0
		bne outlet_calibrate_not_finished

		@ Read the level of the hall sensor and cmp with #0
		ldr r0, [rGPIO, #GPLEV0]
		ands r0, #1 << nHallOutlet_PIN

		@ HallSensor == 0 -> jump to the end
		beq outlet_calibrate_not_finished

		@ Else save the address for the next case and jump to the end
		ldr r0, =case_calibrate_before_hall
		str r0, [r4]
		b outlet_calibrate_not_finished

	case_calibrate_before_hall:
		bl outlet_step

		@ Check if the step is finished
		cmp r0, #0
		bne outlet_calibrate_not_finished

		@ Read the level of the hall sensor and cmp with #0
		ldr r0, [rGPIO, #GPLEV0]
		ands r0, #1 << nHallOutlet_PIN

		@ HallSensor == 1 -> Go to end
		bne outlet_calibrate_not_finished

		@ HallSensor == 0 -> Next case
		ldr r0, =case_calibrate_at_hall
		str r0, [r4]
		b outlet_calibrate_not_finished

	case_calibrate_at_hall:
		bl outlet_step

		@ Check if the step is finished
		cmp r0, #0
		bne outlet_calibrate_not_finished

		@ Count every step while the outlet is in the hall sensor
		ldr r0, addr_calibrate_steps_in_hall
		ldr r1, [r0]
		add r1, #1
		str r1, [r0]

		@ Read the level of the hall sensor and cmp with #0
		ldr r0, [rGPIO, #GPLEV0]
		ands r0, #1 << nHallOutlet_PIN

		@ HallSensor == 0 -> Go to end
		beq outlet_calibrate_not_finished

		@ HallSensor == 1 -> Next case
		mov r0, #1 << DirOut_PIN
		str r0, [rGPIO, #GPSET0]		@ Set the direction to counterclockwise

		@ Store the next case
		ldr r0, =case_calibrate_after_hall
		str r0, [r4]
		b outlet_calibrate_not_finished

	case_calibrate_after_hall:
		bl outlet_step

		@ Check if the step is finished
		cmp r0, #0
		bne outlet_calibrate_not_finished

		@ Remove always 2 steps from the counted value. This results in an automatically averaged count.
		@ Cmp it with zero
		ldr r0, addr_calibrate_steps_in_hall
		ldr r1, [r0]
		subs r1, #2
		str r1, [r0]

		@ While the counter is higher than zero repeat this
		bpl outlet_calibrate_not_finished

		@ The counter is now zero or lower. Reset the direction from the motor to clockwise
		mov r0, #1 << DirOut_PIN
		str r0, [rGPIO, #GPCLR0]

		@ Set the case for the method to the end label.
		@ If the calibration method is called again, nothing is going to happen
		ldr r0, =outlet_calibrate_end
		str r0, [r4]

		@ Return code, that the calibration is finished
		mov r0, #0
		b outlet_calibrate_end

	outlet_calibrate_not_finished:
		@ Return code, that the calibration is NOT finished
		ldr r4, addr_calibration_state
		ldr r4, [r4]
		ldr r0, =outlet_calibrate_end
		cmp r0, r4
		mov r0, #1
		moveq r0, #0

	outlet_calibrate_end:
		pop {r4, lr}
		bx lr

@@@ ----------------------------------------------------------------------------------------
@@@ Rotate the Outlet in 60 degree Steps clockwise
@@@ Inputs: r0 - Step count
@@@ Return: None
outlet_rotate_clockwise_initiate:
	push {r4, r5, r6, lr}
	mov r1, #67
	mul r1, r0, r1

	ldr r4, addr_rotation_steps
	str r1, [r4]

	ldr r5, =offset_flag
	ldr r6, [r5]
	add r6, r0

	cmp r6, #3
	subge r4, #1
	subge r6, #3
	str r6, [r5]

	mov r0, #0x01 << DirOut_PIN		@ Set direction to clockwise
	str r0, [rGPIO, #GPSET0]

	pop {r4, r5, r6, lr}
	bx lr

outlet_rotate60_clockwise:
	push {r4, lr}
	ldr r4, addr_rotation_steps

	@ The timer is calling this method every time he counted to 0. This is probably to fast,
	@ so we have to count how often the method is called and cancel the execution if the count
	@ is not high enough
	ldr r0, addr_timer_event_count
	ldr r1, [r0]
	subs r1, #1
	str r1, [r0]
	bne outlet_rotate60_clockwise_end	@ Cancel

	@ Reset the timer event count
	ldr r1, speed_in_ms
	str r1, [r0]

	@ If the color wheel already did the 400 steps: Do nothing
	ldr r0, [r4]
	cmp r0, #0
	beq outlet_rotate60_clockwise_end

	@ Do step and check if the step is finished (state of the wheel pin have to be LOW)
	bl outlet_step
	cmp r0, #0
	bgt outlet_rotate60_clockwise_end

	@ Subtract one from the current steps
	ldr r0, [r4]
	subs r0, #1
	str r0, [r4]

	outlet_rotate60_clockwise_end:
		ldr r0, [r4]
		pop {r4, lr}
		bx lr

@@@ ----------------------------------------------------------------------------------------
@@@ Rotate the Outlet in 60 degree Steps counterclockwise
@@@ Inputs: None
@@@ Return: None
outlet_rotate_counterclockwise_initiate:
	push {r4, r5, r6, lr}
	mov r1, #-67
	mul r1, r0

	ldr r4, addr_rotation_steps
	str r1, [r4]

	ldr r5, =offset_flag
	ldr r6, [r5]
	add r6, r0

	cmp r6, #-3
	addle r4, #1
	addle r6, #3
	str r6, [r5]

	mov r0, #0x01 << DirOut_PIN		@ Set direction to counterclockwise
	str r0, [rGPIO, #GPCLR0]

	pop {r4, r5, r6, lr}
	bx lr

outlet_rotate60_counterclockwise:
	push {r4, lr}
	ldr r4, addr_rotation_steps

	@ The timer is calling this method every time he counted to 0. This is probably to fast,
	@ so we have to count how often the method is called and cancel the execution if the count
	@ is not high enough
	ldr r0, addr_timer_event_count
	ldr r1, [r0]
	subs r1, #1
	str r1, [r0]
	bne outlet_rotate60_counterclockwise_end 	@ Cancel

	@ Reset the timer event count
	ldr r1, speed_in_ms
	str r1, [r0]

	@ If the color wheel already did the 400 steps: Do nothing
	ldr r0, [r4]
	cmp r0, #0
	beq outlet_rotate60_counterclockwise_end

	@ Do step and check if the step is finished (state of the wheel pin have to be LOW)
	bl outlet_step
	cmp r0, #0
	bgt outlet_rotate60_counterclockwise_end

	@ Subtract one from the current steps
	ldr r0, [r4]
	subs r0, #1
	str r0, [r4]

	outlet_rotate60_counterclockwise_end:

		ldr r0, [r4]
		pop {r4, lr}
		bx lr



@@@ ----------------------------------------------------------------------------------------
@@@ Rotate the Outlet exactly one step
@@@ Inputs: None
@@@ Return: None
outlet_step:
	@ Read the current level of the step pin and cmp with #0
	ldr r0, [rGPIO, #GPLEV0]
	ands r0, #1 << StepOut_PIN

	@ If currentLevel == LOW (eq): Set it to HIGH
	@ If currentLevel == HIGH (ne): Set it to LOW
	mov r0, #1 << StepOut_PIN
	streq r0, [rGPIO, #GPSET0]
	strne r0, [rGPIO, #GPCLR0]
	movne r0, #0

	bx lr
