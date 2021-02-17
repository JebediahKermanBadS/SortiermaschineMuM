@@@ -----------------------------------------------------------------------------------------
@@@ Project:	M&M Sortingmachine
@@@  Target:	Raspberry Pi Zero
@@@	   Date:	2020/26/01
@@@ Group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ -----------------------------------------------------------------------------------------

@@@ Renamimg registers ----------------------------------------------------------------------
	rTIMER	.req r9
	rGPIO	.req r10

@@@ Pins of the 7-Segment Display -----------------------------------------------------------
	.equ pin_SER,		2
	.equ pin_SRCLK,		3
	.equ pin_nSRCLR,	4
	.equ pin_RCLK,		5
	.equ pin_SEG_A,		6
	.equ pin_SEG_B,		7

@@@ Pins of the Buttons ---------------------------------------------------------------------
	.equ pin_nBTN1,		8
	.equ pin_nBTN2,		9
	.equ pin_nBTN3,		10

@@@ Pins for the objectsensor in the outlet -------------------------------------------------
	.equ pin_objCW,		25
	.equ pin_dirOut,	26

@@@ Define the offset for the GPIO Registers ------------------------------------------------
	.equ GPFSET0, 	0x00
	.equ GPFSET1, 	0x04
	.equ GPSET0,	0x1C
	.equ GPCLR0,	0x28
	.equ GPLVL0,	0x34

@@@ For the buttons -------------------------------------------------------------------------
	.equ GPEDS0,	0x40
	.equ GPREN0,	0x4C
	.equ GPFEN0,	0x58
	.equ GPHEN0,	0x64
	.equ GPLEN0,	0x70


.data
.align 4

msg_init: .asciz "M&M Sorting Machine started!\nThis is a program from the following group:\n\t- Demiroez, Dilara\n\t- Gonther, Levin\n\t- Grajczak, Benjamin\n\t- Pfister, Marc\n"

msg_gpio_mem: 	.asciz "Gpio memory is: %p\n"
msg_timer_mem: 	.asciz "Timer memory is: %p\n"

msg_print_int: 	.asciz "%d\n"
msg_print_hex: 	.asciz "%x\n"

msg_calibration_finished: .asciz "The calibration of the outlet and the color wheel is finished.\n"

.align 4
is_running:	.word 0

.align 4
color_array: .word 0
			 .word 1
			 .word 2
			 .word 3
			 .word -2
			 .word -1

.align 4
outlet_position: .word 0

.text

timer_pre_divider: 	.word 399

addr_is_running: 	.word is_running

.extern printf
.extern sleep

@@@ Methods from the co_processor.S ---------------------------------------------------------
.extern cop_init
.extern cop_wakeup
.extern cop_sleep
.extern cop_read_color

@@@ Methods from the color_wheel.S ----------------------------------------------------------
.extern color_wheel_init
.extern color_wheel_calibrate
.extern color_wheel_rotate90

@@@ Methods from the feeder.S ---------------------------------------------------------------
.extern feeder_init
.extern feeder_on
.extern feeder_off

@@@ Methods from leds.S ---------------------------------------------------------------------
.extern leds_Init
.extern leds_DeInit
.extern leds_showColor

@@@ Methods from mapping_memory.S -----------------------------------------------------------
.extern mmap_gpio
.extern unmap_memory

@@@ Methods from outlet.S -------------------------------------------------------------------
.extern outlet_init
.extern outlet_calibrate
.extern outlet_rotate60_clockwise
.extern outlet_rotate60_counterclockwise

.global main
main:
	push {fp, lr}
	mov fp, sp

	ldr r0, =msg_init
	bl printf

	@ Map the virtual address for the gpio registers
	bl mmap_gpio
	mov rGPIO, r0
	cmp rGPIO, #-1
	beq main_end

	@ Map the virtual address for the timer registers
	bl mmap_timerIR
	mov rTIMER, r0
	cmp rTIMER, #-1
	beq main_end

	@ Print the virtual address for the gpio reigsters
	ldr r0, =msg_gpio_mem
	mov r1, rGPIO
	bl printf

	@ Print the virtual address for the timer reigsters
	ldr r0, =msg_gpio_mem
	mov r1, rTIMER
	bl printf

	@@@ Init all the hardware ---------------------------------------------------------------
	bl cop_init
	bl color_wheel_init
	bl feeder_init
	bl leds_Init
	bl outlet_init
	bl timer_init
	bl interrupts_disable
	bl buttons_init

	mov r0, #1
	bl colow_wheel_set_enable
	mov r0, #1
	bl timer_set_enable
	bl cop_wakeup
	calibrate_loop:
		ldr r0, [rTIMER, #0x410]
		cmp r0, #0
		beq calibrate_loop

		@ Timer counted to zero. 1ms is over
		str r0, [rTIMER, #0x40C]
		bl color_wheel_calibrate

		cmp r0, #0
		bgt calibrate_loop

	bl colow_wheel_set_enable
	mov r0, #0
	bl timer_set_enable
	bl cop_sleep

	ldr r0, =msg_calibration_finished
	bl printf

	main_loop:
		ldr r0, [rGPIO, #GPEDS0]
		ands r0, #1 << pin_nBTN1
		beq main_loop

		str r0, [rGPIO, #GPEDS0]

		ldr r0, addr_is_running
		ldr r0, [r0]
		cmp r0, #0
		str r0, [sp, #-4]!
		bleq machine_start
		ldr r0, [sp], #4
		cmp r0, #1
		bleq machine_stop

		b main_loop

	b main_munmap_pgpio


main_munmap_pgpio:
	mov r0, rTIMER
	bl unmap_memory

	mov r0, rGPIO
	bl unmap_memory

main_end:
	bl leds_DeInit

	mov sp, fp
	pop {fp, lr}
	bx lr

machine_start:
	push {lr}

	bl feeder_on
	bl cop_wakeup
	mov r0, #1
	bl colow_wheel_set_enable
	mov r0, #1
	bl timer_set_enable

	mov r1, #1
	ldr r0, addr_is_running
	str r1, [r0]

	pop {lr}
	bx lr

machine_stop:
	push {lr}
	bl feeder_off
	bl cop_sleep
	mov r0, #0
	bl colow_wheel_set_enable
	mov r0, #0
	bl timer_set_enable

	mov r1, #0
	ldr r0, addr_is_running
	str r1, [r0]

	pop {lr}
	bx lr

swap_led_state:
	ldr r0, [rGPIO, #GPLVL0]
	ands r0, #1 << 19
	mov r0, #1 << 19
	streq r0, [rGPIO, #GPSET0]
	strne r0, [rGPIO, #GPCLR0]
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Enable the buttons
@@@ Inputs: None
@@@ Return: None
buttons_init:
	ldr r0, [rGPIO, #GPFSET0]

	@ Set the button at pin 8 as input
	bic r0, #0b111 << 24

	@ Set the button at pin 9 as input
	bic r0, #0b111 << 27

	str r0, [rGPIO, #GPFSET0]

	@ Set the button at pin 10 as input
	ldr r0, [rGPIO, #GPFSET1]
	bic r0, #0b111
	str r0, [rGPIO, #GPFSET1]

	@ Enable RISING EDGE detect for all buttons
	ldr r0, [rGPIO, #GPREN0]
	orr r0, #0b111 << pin_nBTN1
	str r0, [rGPIO, #GPREN0]

	@ Disable FALLING EDGE detect for all buttons
	ldr r0, [rGPIO, #GPFEN0]
	bic r0, #0b111 << pin_nBTN1
	str r0, [rGPIO, #GPFEN0]

	@ Disable HIGH detect for all buttons
	ldr r0, [rGPIO, #GPHEN0]
	bic r0, #0b111 << pin_nBTN1
	str r0, [rGPIO, #GPHEN0]

	@ Disable LOW detect for all buttons
	ldr r0, [rGPIO, #GPLEN0]
	bic r0, #0b111 << pin_nBTN1
	str r0, [rGPIO, #GPLEN0]
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Disable interrupts
@@@ Inputs: None
@@@ Return: None
interrupts_disable:
	@ Disable timer interrupt
	mov r0, #1
	str r0, [rTIMER, #0x224]

	@ Disable gpio interrupts
	mov r0, #0b1111 << 17
	str r0, [rTIMER, #0x220]

	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Initialize the timer
@@@ Inputs: None
@@@ Return: None
timer_init:

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








/*
calibration:
	bl cop_wakeup

	bl color_wheel_calibrate

	bl outlet_calibrate

	bl feeder_on

main_loop:
	bl color_wheel_rotate90

	bl cop_read_color

	cmp r0, #-1
	beq main_loop

	@@ position outlet
	ldr r2, =color_array
	ldr r3, =outlet_position
	ldr r1, [r3]

	@ calculate offset
	subs r1, r0, r1
	addmi r1, r1, #6
	str r1, [r3]
	mov r1, r1, LSL #2

	ldr r1, [r2, +r1]

	@rotate outlet
	cmp r1, #0
	blt counterclockwise
	beq no_rotation
	clockwise:
		bl outlet_rotate60_clockwise
		subs r1, #1
		bpl clockwise
		beq no_rotation
	counterclockwise:
		bl outlet_rotate60_counterclockwise
		adds r1, #1
		bmi counterclockwise
	no_rotation:
		b main_loop
*/






