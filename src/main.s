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
	.equ GPSET0,	0x1C
	.equ GPCLR0,	0x28
	.equ GPLVL0,	0x34

.data
.align 4

msg_init: .asciz "M&M Sorting Machine started!\nThis is a program from the following group:\n\t- Demiroez, Dilara\n\t- Gonther, Levin\n\t- Grajczak, Benjamin\n\t- Pfister, Marc\n"

msg_gpio_mem: 	.asciz "Gpio memory is: %p\n"
msg_timer_mem: 	.asciz "Timer memory is: %p\n"

msg_print_int: 	.asciz "%d\n"
msg_print_hex: 	.asciz "%x\n"

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

	@ Print the virtual address for the gpio reigsters
	ldr r0, =msg_gpio_mem
	mov r1, rGPIO
	bl printf

init_hardware:

	bl cop_init
	bl color_wheel_init
	bl feeder_init
	bl leds_Init
	bl outlet_init

main_loop:

	mov r0, rGPIO
	bl feeder_on

	@ Sleep 2 seconds
	mov r0, #2
	bl sleep

	mov r0, rGPIO
	bl feeder_off

	mov r0, rGPIO
	bl color_wheel_calibrate

	@ Sleep 2 seconds
	mov r0, #2
	bl sleep

	bl color_wheel_rotate90

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


main_munmap_pgpio:
	mov r0, rGPIO
	bl unmap_memory

main_end:
	mov sp, fp
	pop {fp, lr}
	bx lr



















