@@@ -----------------------------------------------------------------------------------------
@@@ Project:	M&M Sortingmachine
@@@  Target:	Raspberry Pi Zero
@@@	   Date:	2020/02/02
@@@ Group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ -----------------------------------------------------------------------------------------
@@@ Document description
@@@ -----------------------------------------------------------------------------------------


	@ Constants for the leds ----------------------------------------------------------------
	.equ BRIGHTNESS, 50

.data

.align 4
color_array:
	.word 0xFF0000 @Red
 	.word 0x00FF00 @Green
 	.word 0x0000FF @Blue
 	.word 0x654321 @Brown
 	.word 0xFF8800 @Orange
 	.word 0xFF0000 @Yellow

hex_msg: .asciz "%x\n"

.text

.global leds_Init
.global leds_DeInit
.global leds_showColor

.extern WS2812RPi_Init
.extern WS2812RPi_DeInit

.extern WS2812RPi_SetBrightness
.extern WS2812RPi_SetSingle
.extern WS2812RPi_SetOthersOff
.extern WS2812RPi_AllOff
.extern WS2812RPi_AnimDo
.extern WS2812RPi_Show


.extern printf

leds_Init:
	push {lr}

	bl WS2812RPi_Init

	mov r0, #BRIGHTNESS
	bl WS2812RPi_SetBrightness

	bl WS2812RPi_AllOff
	bl WS2812RPi_Show

	pop {lr}
	bx lr


leds_DeInit:
	push {lr}

	bl WS2812RPi_DeInit

	pop {lr}


@@@ Input: color-core (Red = 0, Green = 1, ....
leds_showColor:
	push {lr}

	str r0, [sp, #-4]!

	ldr r1, =color_array
	ldr r1, [r1, r0]
	add r0, r0, #1

	bl WS2812RPi_SetSingle

	ldr r0, [sp, #+4]!
	bl WS2812RPi_SetOthersOff
	bl WS2812RPi_Show

	pop {lr}
	bx lr



