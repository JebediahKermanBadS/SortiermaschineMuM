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

@@@ Pins of the Outlet ----------------------------------------------------------------------
	.equ pin_nRSTOut,	11
	.equ pin_StepOut,	12

@@@ Pin of the Color-LEDs -------------------------------------------------------------------
@@@	.equ ledSig, 		18

@@@ Pins of the Hallsensor ------------------------------------------------------------------
	.equ pin_nHallOutlet,	21


@@@ Pins for the objectsensor in the outlet -------------------------------------------------
	.equ pin_objCW,		25
	.equ pin_dirOut,	26

@@@ Define the offset for the GPIO Registers
@@@ -----------------------------------------------------------------------------------------
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

.text

.extern printf
.extern sleep

@ Methods for the feeder
.extern feeder_init
.extern feeder_on
.extern feeder_off

@ From memory_access.S
.extern mmap_gpio
.extern mmap_timerIR
.extern unmap_memory

@ From sortmachine_pin.S
.extern init_output_input
.extern init_timerIR_registers

@ Methods for the leds
.extern leds_Init

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

	@ Map the virtual address for the timer and interrupt register
	bl mmap_timerIR
	mov rTIMER, r0
	cmp rTIMER, #-1
	beq main_munmap_pgpio

	@ Print the virtual address for the gpio reigsters
	ldr r0, =msg_gpio_mem
	mov r1, rGPIO
	bl printf

	@ Print the virutal address for the timer registers
	ldr r0, =msg_timer_mem
	mov r1, rTIMER
	bl printf

init_hardware:

	@@@ Initialize the inputs and outputs for the machine
	@@@ TODO: Uncomment
	@@@ mov r0, rGPIO
	@@@ bl init_output_input

	bl feeder_init
	bl leds_Init

	mov r0, #0
	bl leds_showColor
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

main_end_unmap:
	mov r0, rTIMER
	bl unmap_memory

main_munmap_pgpio:
	mov r0, rGPIO
	bl unmap_memory

main_end:
	mov sp, fp
	pop {fp, lr}
	bx lr



















