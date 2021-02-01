@@@ M&M Sortingmachine
@@@ --------------------------------------------------------------------------
@@@ group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ target:	 Raspberry Pi Zero
@@@	date:	 2020/01/26
@@@	verison: 1.0.0
@@@ --------------------------------------------------------------------------

@@@ Pins of the 7-Segment Display --------------------------------
	.equ pin_SER,		2
	.equ pin_SRCLK,		3
	.equ pin_nSRCLR,	4
	.equ pin_RCLK,		5
	.equ pin_SEG_A,		6
	.equ pin_SEG_B,		7

@@@ Pins of the Buttons ------------------------------------------
	.equ pin_nBTN1,		8
	.equ pin_nBTN2,		9
	.equ pin_nBTN3,		10

@@@ Pins of the Outlet -------------------------------------------
	.equ pin_nRSTOut,	11
	.equ pin_StepOut,	12

@@@ Pin of the Color-LEDs ----------------------------------------
@@@	.equ ledSig, 		18

@@@ Pins of the Hallsensor ---------------------------------------
	.equ pin_nHallOutlet,	21

@@@ Pins for the color recognition -------------------------------
	.equ pin_colorBit1,	22
	.equ pin_colorBit2,	23
	.equ pin_colorBit3,	24

@@@ Pins for the objectsensor in the outlet ----------------------
	.equ pin_objCW,		25
	.equ pin_dirOut,	26

@@@ Pin to let the co-processor sleep ----------------------------
	.equ pin_nSLP,		27



@@@ Define the offset for the GPIO Registers
@@@ --------------------------------------------------------------------------
	.equ GPSET0,	0x1C
	.equ GPCLR0,	0x28
	.equ GPLVL0,	0x34

@@@ --------------------------------------------------------------
@@@ Colors from the Co-Prozessor ---------------------------------
	.equ C_RED, 	0b001
	.equ C_GREEN,	0b010
	.equ C_BLUE,	0b011
	.equ C_BRONW,	0b100
	.equ C_ORANGE,	0b101
	.equ C_YELLOW,	0b110
	.equ C_UNKNOWN, 0b000

@@@ --------------------------------------------------------------
@@@ Renamimg registers -------------------------------------------
	rTIMER	.req r9
	rGPIO	.req r10

@@@ --------------------------------------------------------------
@@@ Start Data Section -------------------------------------------
.data
.align 4

msg_init: .asciz "M&M Sorting Machine started!\nThis is a program from the following group:\n\t- Demiroez, Dilara\n\t- Gonther, Levin\n\t- Grajczak, Benjamin\n\t- Pfister, Marc\n"

msg_gpio_mem: 	.asciz "Gpio memory is: %p\n"
msg_timer_mem: 	.asciz "Timer memory is: %p\n"

msg_print_int: 	.asciz "%d\n"
msg_print_hex: 	.asciz "%x\n"

@@@ --------------------------------------------------------------
@@@ Start Text Section -------------------------------------------

.text

.extern printf
.extern open
.extern close
.extern mmap
.extern munmap
.extern sleep

@ From memory_access.S
.extern mmap_gpio_mem
.extern mmap_timerIR_mem
.extern munmap_gpio_mem
.extern munmmap_timerIR_mem

@ From sortmachine_pin.S
.extern init_output_input
.extern init_timerIR_registers

@ Methods for the feeder
.extern set_feeder_on
.extern set_feeder_off

.global main
main:
	push {fp, lr}
	mov fp, sp

	ldr r0, =msg_init
	bl printf

	@ Map the virtual address for the gpio registers
	bl mmap_gpio_mem
	mov rGPIO, r0
	cmp rGPIO, #-1
	beq main_end

	@ Map the virtual address for the timer and interrupt register
	bl mmap_timerIR_mem
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
	mov r0, rGPIO
	bl init_output_input

	@ TODO Uncommend this
	@@@ Initialize the timer and interrupts
	@mov r0, rTIMER
	@bl init_timerIR_registers

	ldr r1, [rTIMER, #0x220]
	bic r1, r1, #0b1111 << 17
	//str r1, [rTIMER, #0x220]

main_loop:

	mov r0, rGPIO
	bl set_feeder_on

	@ Sleep 2 seconds
	mov r0, #2
	bl sleep

	mov r0, rGPIO
	bl set_feeder_off

	mov r0, rGPIO
	bl color_wheel_calibrate

	@ Sleep 2 seconds
	mov r0, #2
	bl sleep

	bl color_wheel_rotate90

main_end_unmap:
	mov r0, rTIMER
	bl munmmap_timerIR_mem

main_munmap_pgpio:
	mov r0, rGPIO
	bl munmap_gpio_mem

main_end:
	mov sp, fp
	pop {fp, lr}
	bx lr



















