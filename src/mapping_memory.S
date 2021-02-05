@@@ -----------------------------------------------------------------------------------------
@@@ Project:	M&M Sortingmachine
@@@  Target:	Raspberry Pi Zero
@@@	   Date:	2020/27/01
@@@ Group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ -----------------------------------------------------------------------------------------
@@@ This document deals with the following tasks:
@@@		- Method to get access to the gpio memory
@@@ 	- Method to get access to the memory for timers and interrupts
@@@ -----------------------------------------------------------------------------------------

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

	.equ NO_PREF,			0
	.equ PAGE_SIZE, 		4096

	.equ FILE_OPEN_ERROR,	-1
	.equ ERROR_CODE,		-1

.data

@@@ File names
file_mem:		.asciz "/dev/mem"
file_gpiomem: 	.asciz "/dev/gpiomem"

@@@ Failure messages
file_open_failure: .asciz "Failure! Cant open the file %s. Try execute with sudo\n"
file_close_failure: .asciz "Failure! Not possible to close the file %s correctly.\n"
unmap_failure: .asciz "Failure unmapping the virtual address: %p\n"

.text

.global mmap_gpio
.global mmap_timerIR

.global unmap_memory


.extern open
.extern close
.extern mmap
.extern munmap
.extern printf

openMode:	.word O_FLAGS
gpio: 		.word PERIPH + GPIO_OFFSET
timerIR: 	.word PERIPH + TIMERIR_OFFSET

@@@ -----------------------------------------------------------------------------------------
@@@ Creates a virtual address to access the gpio registers
@@@ Inputs: None
@@@ Return:
@@@		r0: The virtual adddress
@@@			If (r0 == -1) --> Error! Don't use this as address ;)
mmap_gpio:
	push {lr}

	ldr r0, =file_gpiomem
	ldr r1, gpio
	bl mapFileToMemory

	pop {lr}
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Creates a virtual address to access the timer and interrupt registers
@@@ Inputs: None
@@@ Return:
@@@		r0: The virtual adddress
@@@			If (r0 == -1) --> Error! Don't use this as address ;)
mmap_timerIR:
	push {lr}

	ldr r0, =file_mem
	ldr r1, timerIR
	bl mapFileToMemory

	pop {lr}
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Unmaps a virutal address
@@@ Inputs:
@@@		r0: The virtual address
@@@ Return: None
unmap_memory:
	push {lr}

	@ Unmap the memory
	mov r1, #PAGE_SIZE
	bl munmap

	@ Display munmap success
	cmp r0, #-1
	ldreq r0, =unmap_failure
	bleq printf

	pop {lr}
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Creates a virtual address from a specific file
@@@ Inputs:
@@@		r0: The filename
@@@		r1: The offset for the register
@@@ Return:
@@@		r0: The virtual adddress
@@@			If (r0 == -1) --> Error! Don't use this as address ;)
mapFileToMemory:
	push {r0, fp, lr}
	mov fp, sp

	sub sp, sp, #8 		@ Stack: (sp)None, None
	str r1, [sp, #4]	@ Stack: (sp)None, Offset

	ldr r1, openMode
	bl open

	str r0, [sp]		@ Stack: (sp)FileDescriptor, Offset

	@ If the open method returned an error code: exit and print error code
	cmp r0, #FILE_OPEN_ERROR
	ldreq r0, =file_open_failure
	beq mapFileToMemory_ERROR

	mov r0, #NO_PREF
	mov r1, #PAGE_SIZE
	mov r2, #PROT_RW
	mov r3, #MAP_SHARED
	bl mmap

	@ Store the virutal address in the stack
	str r0, [sp, #4]	@ Stack: (sp)FileDescriptor, VirtualAddress

	@ Pop the file descriptor from the stack
	ldr r0, [sp], #4 	@ Stack: (sp)VirtualAddress
	bl close

	@ If the close method returned an error code: exit and print error code.
	cmp r0, #0
	ldrne r0, =file_close_failure
	bne mapFileToMemory_ERROR

	@ Pop the virtual address from the stack
	@ Stack: fp, lr
	ldr r0, [sp]		@ Stack: (sp)VirtualAddress
	b mapFileToMemory_exit

mapFileToMemory_ERROR:
	@ Load the Filename from the stack to print
	mov sp, fp
	pop {r1}
	bl printf
	mov r0, #ERROR_CODE

mapFileToMemory_exit:
	mov sp, fp
	pop {r1, fp, lr}
	bx lr

