@@@ -----------------------------------------------------------------------------------------
@@@ Project:	M&M Sortingmachine
@@@  Target:	Raspberry Pi Zero
@@@	   Date:	2021/02/20
@@@ Group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ -----------------------------------------------------------------------------------------
@@@ This document provides methods to init the timer and enable/disable it
@@@ -----------------------------------------------------------------------------------------

@@@ Renamimg registers ----------------------------------------------------------------------
	rTIMER	.req r9
	rGPIO	.req r10

.text

.global timer_init
.global timer_set_enable

timer_pre_divider: 	.word 399

@@@ -----------------------------------------------------------------------------------------
@@@ Initialize the timer
@@@ Inputs: None
@@@ Return: None
timer_init:
	@ Disable timer interrupt
	mov r0, #1
	str r0, [rTIMER, #0x224]

	@ Set the control register of the timer
	ldr r0, [rTIMER, #0x408]
	bic r0, #1 << 7 	@ Disable the timer
	bic r0, #1 << 5 	@ Disable the timer interrupt
	bic r0, #11 << 2	@ Disable the prescale
	bic r0, #1 << 1		@ Set to 16-bit timer
	str r0, [rTIMER, #0x408]

	@ Clear the interrupt pending bit
	mov r0, #1
	str r0, [rTIMER, #0x40C]

	@ Set the pre-devider of the timer, fTimer = 1MHz
	ldr r0, timer_pre_divider
	str r0, [rTIMER, #0x41C]

	@ Set the load value of the timer to 1000 ; fTimer = 1kHz
	mov r0, #1000
	str r0, [rTIMER, #0x400]

	@ Enable the timer after all settings are made
	ldr r0, [rTIMER, #0x408]
	orr r0, #1 << 7
	str r0, [rTIMER, #0x408]

	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Enable or disable the timer
@@@ Inputs: r0 >= 1 -> enabled
@@@			r0 == 0 -> disabled
@@@ Return: None
timer_set_enable:
	cmp r0, #0

	@ Set the control register of the timer
	ldr r0, [rTIMER, #0x408]
	biceq r0, #1 << 7 	@ Disable the timer
	orrne r0, #1 << 7 	@ Enable the timer
	str r0, [rTIMER, #0x408]

	bx lr
