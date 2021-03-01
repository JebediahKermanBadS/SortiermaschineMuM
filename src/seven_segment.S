@@@ -----------------------------------------------------------------------------------------
@@@ Project:	M&M Sortingmachine
@@@  Target:	Raspberry Pi Zero
@@@	   Date:	2021/02/25
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

	.equ GPSET0, 	0x1C
	.equ GPCLR0, 	0x28

.data
	@@@	   __A__
	@@@   |     |
	@@@ F |     | B
	@@@   |     |
	@@@   |--G--|
	@@@   |     |
	@@@ E |     | C
	@@@   |__D__|
	.align 4
	numbers: @A B C D E F G .
		.word 0b11111100 @ 0
		.word 0b01100000 @ 1
		.word 0b11011010 @ 2
		.word 0b11111010 @ 3
		.word 0b01100110 @ 4
		.word 0b10110110 @ 5
		.word 0b10111111 @ 6
		.word 0b11100000 @ 7
		.word 0b11111110 @ 8
		.word 0b11111011 @ 9

	.align 4
	current_segment: 	.word 0

	.align 4
	current_values:
		.word 0
		.word 0
		.word 0
		.word 0

.text

.align 4
outputbits_clr_value: .word 0xFFFFC0
outputbits_set_value: .word 0x249240

.extern usleep

.global segment7_init
.global segment7_setvalue
.global segment7_next

segment7_init:
	push {lr}

	ldr r0, [rGPIO]

	ldr r1, outputbits_clr_value
	bic r0, r1

	ldr r1, outputbits_set_value
	orr r0, r1

	str r0, [rGPIO]

	mov r0, #0
	mov r1, #0
	bl segment7_setvalue

	mov r0, #0
	mov r1, #1
	bl segment7_setvalue

	mov r0, #0
	mov r1, #2
	bl segment7_setvalue

	mov r0, #0
	mov r1, #3
	bl segment7_setvalue

	pop {lr}
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ Inputs:
@@@ 	r0 -> the value
@@@		r1 -> the segmentnumber (0 <= r1 <= 3)
@@@ Return:
segment7_setvalue:
	ldr r2, =numbers
	ldr r0, [r2, r0, LSL #2]

	ldr r2, =current_values
	str r0, [r2, r1, LSL #2]
	bx lr

@@@ Swap the current segment ----------------------------------------------------------------
segment7_next:
	push {r4, r5, r6, lr}

	@ Set the current segment to the next
	ldr r6, =current_segment
	ldr r1, [r6]
	subs r1, #1
	movmi r1, #3
	str r1, [r6]

	@ Set clear both segments to zero
	mov r0, #0b11 << pin_SEG_A
	str r0, [rGPIO, #GPCLR0]

	ldr r0, =current_values
	ldr r4, [r0, r1, LSL #2]

	mov r5, #8
	@ r4: current value
	@ r5: loop counter
	@ r6: addr of current_segment
	next_loop:

		@ Sleep 1us
		mov r0, #1
		bl usleep

		subs r5, #1
		bne next_loop

	mov r0, r1, LSL #pin_SEG_A
	str r0, [rGPIO, #GPSET0]

	pop {r4, r5, r6, lr}
	bx lr

























