@@@ M&M Sortingmachine
@@@ --------------------------------------------------------------------------
@@@ group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ target:	 Raspberry Pi Zero
@@@	date:	 2020/01.22
@@@	verison: 1.0.0
@@@ --------------------------------------------------------------------------

@@@ Constants defining the flags for opening the gpiomem file
@@@ Defined in /usr/include/asm-generic/fcntl.h
	.equ O_RDWR, 	2  				@ Read and Write the file.
	.equ O_DSYNC, 	010000
	.equ O_SYNC, 	04000000|O_DSYNC
	.equ O_FLAGS, 	O_RDWR|O_SYNC

@@@ Constants defining the gpio mapping
@@@ Defined in /usr/include/asm-generic/mman-common.h
	.equ PROT_RW, 		0x01|0x02	@ Can read(0x01) and write(0x02) the memory
	.equ MAP_SHARED,	0x01		@ Share the memory with oder processes

	.equ PERIPH,		0x20000000
	.equ GPIO_OFFSET,	0x200000

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

@@@ Define constants for the connected pins
@@@ --------------------------------------------------------------------------
	.equ pin_nBTN1,		8
	.equ pin_nBTN2,		9
	.equ pin_nBTN3,		10
@@@ --------------------------------------------------------------------------
	.equ pin_StepCW,	13
	.equ pin_DirCW,		16
	.equ pin_nRSTCW,	17
@@@ --------------------------------------------------------------------------
	.equ pin_feeder,	19
@@@ --------------------------------------------------------------------------
	.equ pin_colorBit1,	22
	.equ pin_colorBit2,	23
	.equ pin_colorBit3,	24


@@@ Rename some registers
@@@ --------------------------------------------------------------------------
	rGPIO	.req r10


@@@ Start Data Section
@@@ --------------------------------------------------------------------------
.data
.align 4

msg_init: .asciz "M&M Sorting Machine started!\nThis is a program from the following group:\n\t- Demiroez, Dilara\n\t- Gonther, Levin\n\t- Graiczak, Benjamin\n\t- Pfister, Marc\n"

msg_fd: .asciz "File descriptor is: %d\n"
msg_gpio_mem: .asciz "Gpio memory is: %p\n"

msg_closeFile_succes: .asciz "Succesfully closed the file /dev/gpiomem\n"
msg_closeFile_failure: .asciz "Failure closing the file /dev/gpiomem\n"

msg_munmap_succes: .asciz "Gpio memory succesfully unmapped!\n"
msg_munmap_failure: .asciz "Failure unmapping the gpio memory!\n"

gpio_file: .asciz "/dev/gpiomem"
gpio_openMode: .word O_FLAGS

msg_print_int: .asciz "%d\n"
msg_print_hex: .asciz "%x\n"

@@@ --------------------------------------------------------------------------
@@@ Start Text Section
@@@ --------------------------------------------------------------------------
.text

gpio_addr: .word PERIPH+GPIO_OFFSET

.extern printf
.extern open
.extern close
.extern mmap
.extern munmap
.extern sleep

.global main
main:
	push {fp, lr}
	mov fp, sp

	ldr r0, =msg_init
	bl printf

init_gpio_mem:
	@ Opening the file /dev/gpiomem with read/write access
	ldr r0, =gpio_file
	ldr r1, =gpio_openMode
	ldr r1, [r1]
	bl open

	@ Store the file descriptor (r0) on the top of the stack
	sub sp, sp, #8
	str r0, [sp]

	@ Display the file descriptor
	ldr r1, [sp]
	ldr r0, =msg_fd
	bl printf

	@ Map the gpio registers
	ldr r0, gpio_addr
	str r0, [sp, #4]
	mov r0, #0			@ No prefer where to allocate the memory
	mov r1, #PAGE_SIZE
	mov r2, #PROT_RW
	mov r3, #MAP_SHARED
	bl mmap

	@ Store the virtual address
	mov rGPIO, r0

	@ Closing the gpio file and restore stack pointer
	ldr r0, [sp], #8
	bl close

	@ Print succesfull closing
	cmp r0, #0
	ldreq r0, =msg_closeFile_succes
	ldrne r0, =msg_closeFile_failure
	bl printf

	@ Printing the virtual address
	ldr r0, =msg_gpio_mem
	mov r1, rGPIO
	bl printf

init_hardware:
@@@ Set the first alternate function select register -------------------------
	ldr r4, [rGPIO]

	@ Define button1 and 2 as input
	bic r4, r4, #0b111111 << 24

	str r4, [rGPIO]
@@@ --------------------------------------------------------------------------

@@@ Set the second alternate function select register ------------------------
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
@@@ --------------------------------------------------------------------------

@@@ Set the third alternate function select register ------------------------
	ldr r4, [rGPIO, #GPFSEL2]

	@ Define the color pins as input
	bic r4, r4, #0b111111 << 9
	bic r4, r4, #0b111 << 6

	str r4, [rGPIO, #GPFSEL2]

main_loop:
	@ Setting the feeder to on
	ldr r1, [rGPIO, #GPSET0]
	mov r4, #0x01
	orr r1, r1, r4, LSL #pin_feeder
	str r1, [rGPIO, #GPSET0]

	@ Sleep 5 seconds
	mov r0, #5
	bl sleep

	@ Setting the feeder to off
	ldr r1, [rGPIO, #GPCLR0]
	orr r1, r1, r4, LSL #pin_feeder
	str r1, [rGPIO, #GPCLR0]

main_end:

	@ Unmap the memory
	mov r0, rGPIO
	mov r1, #PAGE_SIZE
	bl munmap

	@ Display munmap success
	cmp r0, #-1
	ldrne r0, =msg_munmap_succes
	ldreq r0, =msg_munmap_failure
	bl printf

	mov sp, fp
	pop {fp, lr}
	bx lr
























