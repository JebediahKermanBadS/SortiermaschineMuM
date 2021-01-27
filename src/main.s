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

@@@ Pins of the Color-Wheel --------------------------------------
	.equ pin_StepCW,	13
	.equ pin_DirCW,		16
	.equ pin_nRSTCW,	17

@@@ Pin of the Color-LEDs ----------------------------------------
@@@	.equ ledSig, 		18

@@@ Pin of the Feeder --------------------------------------------
	.equ pin_feeder,	19

@@@ Pins of the Hallsensor ---------------------------------------
	.equ pin_nHallCW,		20
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

@@@ Constants defining the flags for opening the gpiomem file
@@@ Defined in /usr/include/asm-generic/fcntl.h
	.equ O_RDWR, 	02				@ Read and Write the file.
	.equ O_DSYNC, 	010000
	.equ O_SYNC, 	04000000|O_DSYNC
	.equ O_FLAGS, 	O_RDWR|O_SYNC

@@@ Constants defining the gpio mapping
@@@ Defined in /usr/include/asm-generic/mman-common.h
	.equ PROT_RW, 		0x01|0x02	@ Can read(0x01) and write(0x02) the memory
	.equ MAP_SHARED,	0x01		@ Share the memory with oder processes

	.equ PERIPH,		 0x20000000
	.equ GPIO_OFFSET,	 0x200000
	.equ TIMERIR_OFFSET, 0xB000

	.equ PAGE_SIZE, 4096

@@@ Define the offset for the GPIO Registers
@@@ --------------------------------------------------------------------------
	.equ GPFSEL1,	0x04
	.equ GPFSEL2,	0x08
	.equ GPSET0,	0x1C
	.equ GPCLR0,	0x28
	.equ GPLVL0,	0x34

	.equ OUTPUT,	0b001
	.equ INPUT,		0b000

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

file_mem:		.asciz "/dev/mem"
file_gpiomem: 	.asciz "/dev/gpiomem"

file_open_failure: .asciz "Failure! Cant open the file %s. Try execute wiht sudo\n"
file_close_failure: .asciz "Failure! Not possible to close the file %s correctly.\n"
gpio_munmap_failure: .asciz "Failure unmapping the gpio memory!\n"

msg_gpio_mem: 	.asciz "Gpio memory is: %p\n"
msg_timer_mem: .asciz "Timer memory is: %p\n"

msg_print_int: .asciz "%d\n"
msg_print_hex: .asciz "%x\n"

.align 4
gpio_fsel0_clear: 	@0011 1111 1111 1111 1111 1111 1100 0000
			.word 	0x3FFFFFC0
.align 4
gpio_fsel0_output: 	@0000 1001 0010 0100 1001 0000 0000 0000
			.word	0x09249000

@@@ --------------------------------------------------------------
@@@ Start Text Section -------------------------------------------
.text

openMode:	.word O_FLAGS
gpio: 		.word PERIPH + GPIO_OFFSET
timerIR: 	.word PERIPH + TIMERIR_OFFSET

.extern printf
.extern open
.extern close
.extern mmap
.extern munmap
.extern sleep

.extern init_gpiomem

.extern init_output_input

.global main
main:
	push {fp, lr}
	mov fp, sp

	ldr r0, =msg_init
	bl printf

init_gpio_mem:

	@ Opening the file /dev/gpiomem with read/write access
	ldr r0, =file_gpiomem
	ldr r1, openMode
	bl open

	@ Store the file descriptor (r0) on the top of the stack
	sub sp, sp, #8
	str r0, [sp]

	@ Check if there are any errors
	cmp r0, #-1
	ldreq r0, =file_open_failure
	ldreq r1, =file_gpiomem
	bleq printf
	beq main_end

	@ Map the gpio registers
	ldr r0, gpio
	str r0, [sp, #4]
	mov r0, #0				@ No prefer where to allocate the memory
	mov r1, #PAGE_SIZE
	mov r2, #PROT_RW
	mov r3, #MAP_SHARED
	bl mmap
	@ Store and print the virtual address
	mov rGPIO, r0
	ldr r0, =msg_gpio_mem
	mov r1, rGPIO
	bl printf

	@ Closing the gpio file and restore stack pointer
	ldr r0, [sp], #8
	bl close

	@ Print an error message if its not possible to close the file
	cmp r0, #0
	ldrne r1, =file_gpiomem
	ldrne r0, =file_close_failure
	blne printf

@@@ --------------------------------------------------------------
@@@ Open the file /dev/mem for the timer and interrupts ----------
	ldr r0, =file_mem
	ldr r1, openMode
	bl open

	@ Store the file descriptor (r0) on the top of the stack
	sub sp, sp, #8
	str r0, [sp]

	@ Print an error message if its not possible to open the file
	cmp r0, #-1
	ldreq r0, =file_open_failure
	ldreq r1, =file_mem
	bleq printf
	beq main_end_unmapgpio

	@ Map the timer reigsters
	ldr r0, timerIR
	str r0, [sp, #4]
	mov r0, #0				@ No prefer where to allocate the memory
	mov r1, #PAGE_SIZE
	mov r2, #PROT_RW
	mov r3, #MAP_SHARED
	bl mmap

	@ Store and print the virtual address
	mov rTIMER, r0
	ldr r0, =msg_timer_mem
	mov r1, rTIMER
	bl printf

	@ Closing the mem file and restore stack pointer
	ldr r0, [sp], #8
	bl close

	@ Print an error message if its not possible to close the file
	cmp r0, #0
	ldrne r0, =file_close_failure
	ldrne r1, =file_mem
	blne printf

init_hardware:

	mov r1, #1
	str r1, [rTIMER, #0x18]

	ldr r0, =msg_print_hex
	ldr r1, [rTIMER,#0x408]
	mov r4, r1
	bl printf

	orr r4, r4, #0b101 << 5
	str r4, [rTIMER,#0x408]

	ldr r0, =msg_print_hex
	mov r1, r4
	bl printf

	ldr r0, =msg_print_hex
	ldr r1, [rTIMER,#0x408]
	bl printf

	ldr r1, [rTIMER, #0x218]
	orr r1, r1, #0x01
	@str r1, [rTIMER, #0x218]

	ldr r1, [rTIMER, #0x218]
	ldr r0, =msg_print_hex
	bl printf

@@@ Initialize the inputs and outputs for the machine ------------
	mov r0, rGPIO
	bl init_output_input

@@@ Set the second alternate function select register ------------
/*
	ldr r4, [rGPIO, #GPFSEL1]

	@ Define button3 as input
	bic r4, r4, #0b111

	@ Define color-wheel pins as output
	bic r4, r4, #0b111 << 9
	bic r4, r4, #0b111111 << 18
	orr r4, r4, #OUTPUT << 9
	orr r4, r4, #0b001001 << 18

	@ Define feeder as output
	bic r4, r4, #0b111 << 27
	orr r4, r4, #OUTPUT << 27

	str r4, [rGPIO, #GPFSEL1]
	*/
@@@ --------------------------------------------------------------------------

@@@ Set the third alternate function select register ------------------------
	ldr r4, [rGPIO, #GPFSEL2]

	@ Define the color pins as input
	bic r4, r4, #0b111111 << 9
	bic r4, r4, #0b111 << 6

	str r4, [rGPIO, #GPFSEL2]

	mov r0, rGPIO
	bl init_output_input

main_loop:

	@ Setting the feeder to on
	ldr r1, [rGPIO, #GPSET0]
	mov r4, #0x01
	orr r1, r1, r4, LSL #19
	str r1, [rGPIO, #GPSET0]

	@ Sleep 5 seconds
	mov r0, #5
	bl sleep

	@ Setting the feeder to off
	ldr r1, [rGPIO, #GPCLR0]
	orr r1, r1, r4, LSL #19
	str r1, [rGPIO, #GPCLR0]

main_end_unmap:


main_end_unmapgpio:

	@ Unmap the memory
	mov r0, rGPIO
	mov r1, #PAGE_SIZE
	bl munmap

	@ Display munmap success
	cmp r0, #-1
	ldreq r0, =gpio_munmap_failure
	bleq printf

main_end:
	mov sp, fp
	pop {fp, lr}
	bx lr

irq:
	push {r0, r1, lr}
	ldr r0, =msg_init
	bl printf

	pop {r0, r1, lr}






















