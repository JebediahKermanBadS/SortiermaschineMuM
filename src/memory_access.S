@@@ M&M Sortingmachine
@@@ -------------------------------------------------------------------
@@@ group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ target:	 Raspberry Pi Zero
@@@	date:	 2020/01/27
@@@	verison: 1.0.0
@@@ -------------------------------------------------------------------
@@@ This document deals with the following tasks:
@@@		- Method to get access to the gpio memory
@@@ 	- Method to get access to the memory for timers and interrupts
@@@ -------------------------------------------------------------------

@@@ Constants defining the flags for opening the gpiomem file
@@@ Defined in /usr/include/asm-generic/fcntl.h
	.equ O_RDWR, 	02				@ Read and Write the file.
	.equ O_DSYNC, 	010000
	.equ O_SYNC, 	04000000|O_DSYNC
	.equ O_FLAGS, 	O_RDWR|O_SYNC

@@@ Constants defining the gpio mapping
@@@ Defined in /usr/include/asm-generic/mman-common.h
	.equ PROT_RW, 			0x01|0x02	@ Can read(0x01) and write(0x02) the memory
	.equ MAP_SHARED,		0x01		@ Share the memory with oder processes

	.equ PERIPH,		 	0x20000000
	.equ GPIO_OFFSET,	 	0x200000
	.equ TIMERIR_OFFSET, 	0xB000

	.equ PAGE_SIZE, 		4096

	.equ FILE_OPEN_ERROR,	-1
	.equ ERROR_CODE,		-1

@@@ -------------------------------------------------------------------
@@@ Start Data Section ------------------------------------------------
.data

@@@ File names
file_mem:		.asciz "/dev/mem"
file_gpiomem: 	.asciz "/dev/gpiomem"

@@@ Failure messages
file_open_failure: .asciz "Failure! Cant open the file %s. Try execute with sudo\n"
file_close_failure: .asciz "Failure! Not possible to close the file %s correctly.\n"
gpio_munmap_failure: .asciz "Failure unmapping the gpio memory!\n"
timerIR_munmap_failure: .asciz "Failure unmapping the timer and interrupt memory!\n"

@@@ -------------------------------------------------------------------
@@@ Start Text Section ------------------------------------------------
.text

.extern open
.extern close
.extern mmap
.extern munmap
.extern printf

.global mmap_gpio_mem
.global mmap_timerIR_mem

.global munmap_gpio_mem
.global munmmap_timerIR_mem

openMode:	.word O_FLAGS
gpio: 		.word PERIPH + GPIO_OFFSET
timerIR: 	.word PERIPH + TIMERIR_OFFSET

@@@ --------------------------------------------------------------
@@@ This method create a virtual address to access the gpio registers
@@@ Input paramter:
@@@			- None
@@@ Returns:
@@@			- r0: 	The virtual adddress
@@@					If (r0 == -1) --> Error! You should exit the program
@@@ --------------------------------------------------------------
mmap_gpio_mem:
	@ Stack: fp, lr
	push {fp, lr}
	mov fp, sp

	@ Opening the file /dev/gpiomem with read/write access
	ldr r0, =file_gpiomem
	ldr r1, openMode
	bl open

	@ Store the file descriptor (r0) on the top of the stack
	@ Stack: file_descriptor, X, fp, lr
	sub sp, sp, #8
	str r0, [sp]

	@ If there was an error, print a message and exit the function with an error code
	cmp r0, #FILE_OPEN_ERROR
	ldreq r0, =file_open_failure
	ldreq r1, =file_gpiomem
	bleq printf
	moveq r0, #ERROR_CODE
	beq exit_mmap_gpio_mem

	@ Map the gpio registers
	@ Stack: file_descriptor, gpio, fp, lr
	ldr r0, gpio
	str r0, [sp, #4]
	mov r0, #0				@ No prefer where to allocate the memory
	mov r1, #PAGE_SIZE
	mov r2, #PROT_RW
	mov r3, #MAP_SHARED
	bl mmap

	@ Store the virutal address in the stack
	@ Stack: file_descriptor, virtual_address, fp, lr
	str r0, [sp, #4]

	@ Closing the gpio file
	@ Stack: virtual_address, fp, lr
	ldr r0, [sp], #4
	bl close

	@ Print an error message if its not possible to close the file
	cmp r0, #0
	ldrne r1, =file_gpiomem
	ldrne r0, =file_close_failure
	blne printf
	movne r0, #ERROR_CODE
	bne exit_mmap_gpio_mem

	@ Load the gpiomem register from the stack and restore the stack pointer
	@ Stack: fp, lr
	ldr r0, [sp], #4

exit_mmap_gpio_mem:
	mov sp, fp
	pop {fp, lr}
	bx lr
@@@ --------------------------------------------------------------


@@@ --------------------------------------------------------------
@@@ This method create a virtual address to access the timer and interrupt register
@@@ Input paramter:
@@@			- None
@@@ Returns:
@@@			- r0: 	The virtual adddress
@@@					If (r0 == -1) --> Error! You should exit the program
@@@ --------------------------------------------------------------
mmap_timerIR_mem:
	@ Stack: fp, lr
	push {fp, lr}
	mov fp, sp

	@ Opening the file /dev/mem with read/write access
	ldr r0, =file_mem
	ldr r1, openMode
	bl open

	@ Store the file descriptor (r0) on the top of the stack
	@ Stack: file_descriptor, X, fp, lr
	sub sp, sp, #8
	str r0, [sp]

	@ If there was an error, print a message and exit the function with an error code
	cmp r0, #FILE_OPEN_ERROR
	ldreq r0, =file_open_failure
	beq exit_mmap_timerIR_mem_ERROR

	@ Map the timer reigsters
	@ Stack: file_descriptor, gpio, fp, lr
	ldr r0, timerIR
	str r0, [sp, #4]
	mov r0, #0				@ No prefer where to allocate the memory
	mov r1, #PAGE_SIZE
	mov r2, #PROT_RW
	mov r3, #MAP_SHARED
	bl mmap

	@ Store the virutal address in the stack
	@ Stack: file_descriptor, virtual_address, fp, lr
	str r0, [sp, #4]

	@ Pop the file descriptor and close the mem file
	@ Stack: virtual_address, fp, lr
	ldr r0, [sp], #4
	bl close

	@ Print an error message if its not possible to close the file
	cmp r0, #0
	ldrne r0, =file_close_failure
	bne exit_mmap_timerIR_mem_ERROR

	@ Pop the virtual address from the stack
	@ Stack: fp, lr
	ldr r0, [sp], #4
	b exit_init_timerIR_mem

exit_mmap_timerIR_mem_ERROR:
	ldr r1, =file_mem
	bl printf
	mov r0, #ERROR_CODE

exit_init_timerIR_mem:
	mov sp, fp
	pop {fp, lr}
	bx lr
@@@ --------------------------------------------------------------


@@@ --------------------------------------------------------------
@@@ Unmaps the virtual gpio address
@@@ Input paramter:
@@@			- r0: 	The virtual address
@@@ Returns:
@@@			- None
@@@ --------------------------------------------------------------
munmap_gpio_mem:
	push {lr}

	@ Unmap the memory
	mov r1, #PAGE_SIZE
	bl munmap

	@ Display munmap success
	cmp r0, #-1
	ldreq r0, =gpio_munmap_failure
	bleq printf

	pop {lr}
	bx lr
@@@ --------------------------------------------------------------


@@@ --------------------------------------------------------------
@@@ Unmaps the virtual timer interrupt address
@@@ Input paramter:
@@@			- r0: 	The virtual address
@@@ Returns:
@@@			- None
@@@ --------------------------------------------------------------
munmmap_timerIR_mem:
	push {lr}

	@ Unmap the memory
	mov r1, #PAGE_SIZE
	bl munmap

	@ Display munmap success
	cmp r0, #-1
	ldreq r0, =timerIR_munmap_failure
	bleq printf

	pop {lr}
	bx lr
@@@ --------------------------------------------------------------






