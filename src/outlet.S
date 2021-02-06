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

speed_in_us: .word 20000

@ offset_flag counts how many times the outlet is rotated in one direction to counter the
@ resulting step offset
.align 4
offset_flag:	.word 0

.global outlet_init
.global outlet_calibrate
.global outlet_rotate60_clockwise
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

@@@ ----------------------------------------------------------------------------------------
@@@ Calibrate the Outlet to Start Position
@@@ Inputs: None
@@@ Return: None
outlet_calibrate:
	push {r4, lr}
	mov r4, #0

	mov r0, #0x01 << DirOut_PIN			@ Set direction to clockwise
	orr r0, r0, #0x01 << nRSTOut_PIN	@ Enable the motor driver
	str r0, [rGPIO, #GPSET0]

	ldr r0, [rGPIO, #GPLEV0]
	ands r0, r0, #0x01 << nHallOutlet_PIN
	bleq outlet_at_hall


outlet_before_hall_loop:
	bl outlet_step

	ldr r0, [rGPIO, #GPLEV0]
	ands r0, r0, #0x01 << nHallOutlet_PIN
	beq outlet_before_hall_loop

outlet_at_hall_loop:
	bl outlet_step
	add r4, r4, #1

	ldr r0, [rGPIO, #GPLEV0]
	ands r0, r0, #0x01 << nHallOutlet_PIN
	bne outlet_at_hall_loop

	mov r0, #0x01 << DirOut_PIN @Set direction to counterclockwise
	str r0, [rGPIO, #GPCLR0]
	mov r4, r4, LSR #1

outlet_after_hall_loop:
	bl outlet_step
	subs r4, r4, #1
	beq outlet_after_hall_loop

	pop {r4, lr}
	bx lr

outlet_at_hall:
	push {lr]

	mov r0, #0x01 << DirOut_PIN @Set direction to counterclockwise
	str r0, [rGPIO, #GPCLR0]
loop:
	bl outlet_step

	ldr r0, [rGPIO, #GPLEV0]
	ands r0, r0, #0x01 << nHallOutlet_PIN
	bne loop

	mov r0, #0x01 << DirOut_PIN		@ Set direction to clockwise
	str r0, [rGPIO, #GPSET0]

	pop {lr}
	bx lr

@@@ ----------------------------------------------------------------------------------------
@@@ Rotate the Outlet in 60 degree Steps clockwise
@@@ Inputs: None
@@@ Return: None
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

	mov r0, #0x01 << DirOut_PIN		@ Set direction to clockwise
	str r0, [rGPIO, #GPSET0]

outlet_rotate60_clockwise_loop:
	bl outlet_step
	subs r4, #1
	bne outlet_rotate60_clockwise_loop

	pop {r4, r5, r6, lr}
	bx lr

@@@ ----------------------------------------------------------------------------------------
@@@ Rotate the Outlet in 60 degree Steps counterclockwise
@@@ Inputs: None
@@@ Return: None
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

	mov r0, #0x01 << DirOut_PIN		@ Set direction to counterclockwise
	str r0, [rGPIO, #GPCLR0]

outlet_rotate60_counterclockwise_loop:
	bl outlet_step
	subs r4, #1
	bne outlet_rotate60_counterclockwise_loop

	pop {r4, r5, r6, lr}
	bx lr

@@@ ----------------------------------------------------------------------------------------
@@@ Rotate the Outlet exactly one step
@@@ Inputs: None
@@@ Return: None
outlet_step:
	push {lr}

	mov r0, #0x01 << StepOut_PIN
	str r0, [rGPIO, #GPSET0]

	ldr r0, =speed_in_us
	bl usleep

	mov r0, #0x01 << StepOut_PIN
	str r0, [rGPIO, #GPCLR0]

	ldr r0, =speed_in_us
	bl usleep

	pop {lr}
	bx lr
