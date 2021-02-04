@@@----------------------------------------------------------------
@@@ project: 	M&M Sortmachine
@@@ group members:
@@@		- Demiroez, Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@  target:	 	Raspberry Pi Zero
@@@    date:	 	2020/02/04
@@@ version: 	1.0.0
@@@ ----------------------------------------------------------------
@@@ With this document its possible to control the Outlet.
@@@ For this task it provides following methods:
@@@		- Function to calibrate the Outlet.
@@@		- Function to rotate the Outlet in 60 degree Steps
@@@ version: 	1.0.0
@@@ ----------------------------------------------------------------


@@@ Pins of the Outlet ---------------------------------------------
	.equ pin_nRSTOut,	11
	.equ pin_StepOut,	12
	.equ pin_DirOut,	26

@@ Pin for the Hallsensor ------------------------------------------
	.equ pin_nHallOutlet,	21

@@@ Register offsets to set pins on and off ------------------------
	.equ GPSET0,		0x1C
	.equ GPCLR0,		0x28
	.equ GPLEV0,		0x34

	.equ SLEEP_TIME_US,	2000

@@@  Renamimg registers --------------------------------------------
	rGPIO	.req r10
.data

@offset_flag counts how many times the outlet is rotated in one direction to
@counter the resulting step offset
.balign 4
offset_flag:	.word 0

.text

.global outlet_calibrate
.global outlet_rotate60_clockwise
.global outlet_rotate60_counterclockwise

@@@ ----------------------------------------------------------------
@@@ Calibrate the Outlet to Start Position
@@@ Inputs: None
@@@ Returns: None
outlet_calibrate:
	push {r4, lr}
	mov r4, #0

	ldr r0, [rGPIO, #GPSET0]
	orr r0, r0, #0x01 << pin_DirOut		@ Set direction to clockwise
	orr r0, r0, #0x01 << pin_nRSTOut	@ Enable the motor driver
	str r0, [rGPIO, #GPSET0]

outlet_before_hall_loop:
	bl outlet_step

	ldr r0, [rGPIO, #GPLEV0]
	ands r0, r0, #0x01 << pin_nHallOutlet
	bne outlet_before_hall_loop

outlet_at_hall_loop:
	bl outlet_step
	add r4, r4, #1

	ldr r0, [rGPIO, #GPLEV0]
	ands r0, r0, #0x01 << pin_nHallOutlet
	beq outlet_at_hall_loop

	ldr r0, [rGPIO, #GPCLR0]
	orr r0, r0, #0x01 << pin_DirOut @Set direction to counterclockwise
	str r0, [rGPIO, #GPCLR0]
	mov r4, r4, LSR #1

outlet_after_hall_loop:
	bl outlet_step
	subs r4, r4, #1
	bne outlet_after_hall_loop

	pop {r4, lr}
	bx lr

outlet_step:
	push {lr}

	ldr r0, [rGPIO, #GPSET0]
	orr r0, r0, #0x01 << pin_StepOut
	str r0, [rGPIO, #GPSET0]

	mov r0, #SLEEP_TIME_US
	bl usleep

	ldr r0, [rGPIO, #GPCLR0]
	orr r0, r1, #0x01 << pin_StepOut
	str r0, [rGPIO, #GPCLR0]

	mov r0, #SLEEP_TIME_US
	bl usleep

	pop {lr}
	bx lr

@@@ ----------------------------------------------------------------
@@@ Rotate the Outlet in 60 degree Steps clockwise
@@@ Inputs: None
@@@ Returns: None
outlet_rotate60_clockwise:
	push {r4, r5, r6, lr}
	mov r4, #67
	ldr r5, =offset_flag
	ldr r6, [r5]
	add r6, #1

	cmp r6, #3
	subeq r4, #1
	moveq r6, #0
	str r6, [r5]

	ldr r0, [rGPIO, #GPSET0]
	orr r0, r0, #0x01 << pin_DirOut		@ Set direction to clockwise
	str r0, [rGPIO, #GPSET0]

outlet_rotate60_clockwise_loop:
	bl outlet_step
	subs r4, #1
	bne outlet_rotate60_clockwise_loop

	pop{r4, r5, r6, lr}
	bx lr

@@@ ----------------------------------------------------------------
@@@ Rotate the Outlet in 60 degree Steps counterclockwise
@@@ Inputs: None
@@@ Returns: None

outlet_rotate60_counterclockwise:
	push {r4, r5, r6, lr}
	mov r4, #67
	ldr r5, =offset_flag
	ldr r6, [r5]
	sub r6, #1

	cmp r6, #-3
	subeq r4, #1
	moveq r6, #0
	str r6, [r5]

	ldr r0, [rGPIO, #GPCLR0]
	orr r0, r0, #0x01 << pin_DirOut		@ Set direction to counterclockwise
	str r0, [rGPIO, #GPCLR0]

outlet_rotate60_counterclockwise_loop:
	bl outlet_step
	subs r4, #1
	bne outlet_rotate60_counterclockwise_loop

	pop{r4, r5, r6, lr}
	bx lr
