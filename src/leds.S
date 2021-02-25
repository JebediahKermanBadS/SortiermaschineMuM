@@@ -----------------------------------------------------------------------------------------
@@@ Project:	M&M Sortingmachine
@@@  Target:	Raspberry Pi Zero
@@@	   Date:	2021/02/20
@@@ Group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ -----------------------------------------------------------------------------------------
@@@ This document deals with the following tasks:
@@@		- Method to init and deinit the leds
@@@		- Method to set a led to a specific color
@@@ -----------------------------------------------------------------------------------------

@@@ Constants for the leds ------------------------------------------------------------------
	.equ BRIGHTNESS, 100

.data

@@@ Inputs: r0: (0 = Red, 1 = Green, 2 = Blue, 3 = Brown, 4 = Orange, 5 = Yellow)
.align 4
outletpos_to_ledpos:
	.word 2
	.word 1
	.word 3
	.word 5
	.word 6
	.word 4

@@@ Define the colors for the leds as array with the size 6
.align 4
color_array:
 	.word 0x00FF00 @Green
	.word 0xFF0000 @Red
 	.word 0x0000FF @Blue
 	.word 0xFFFF00 @Yellow
 	.word 0x654321 @Brown
 	.word 0xFF8800 @Orange

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

@@@ -----------------------------------------------------------------------------------------
@@@ This method initialize the leds
@@@ Inputs: None
@@@ Return: None
leds_Init:
	push {lr}

	bl WS2812RPi_Init

	mov r0, #BRIGHTNESS
	bl WS2812RPi_SetBrightness

	bl WS2812RPi_AllOff
	bl WS2812RPi_Show

	pop {lr}
	bx lr

@@@ -----------------------------------------------------------------------------------------
@@@ This method deinitialize the leds
@@@ Inputs: None
@@@ Return: None
leds_DeInit:
	push {lr}

	bl WS2812RPi_DeInit

	pop {lr}
	bx lr


@@@ -----------------------------------------------------------------------------------------
@@@ This method sets the color of a led
@@@ Inputs: r0: (0 = Red, 1 = Green, 2 = Blue, 3 = Brown, 4 = Orange, 5 = Yellow)
@@@ Return: None
leds_showColor:
	push {lr}

	@ Get the color in hex from the color array and store in stack
	ldr r1, =color_array
	ldr r1, [r1, r0, LSL #2]
	str r1, [sp, #-4]!			@ Stack: (sp)Color

	@ Get the position of the led to show and store in stack
	ldr r1, =outletpos_to_ledpos
	ldr r1, [r1, r0, LSL #2]
	str r0, [sp, #-4]!			@ Stack: (sp)LedPos, Color

	bl WS2812RPi_AllOff
	bl WS2812RPi_Show

	ldr r0, [sp], #4			@ Stack: (sp)Color
	ldr r1, [sp], #4			@ Stack: None

	bl WS2812RPi_SetSingle
	bl WS2812RPi_Show

	pop {lr}
	bx lr


@@@ -----------------------------------------------------------------------------------------
@@@ This method sets all leds to off
@@@ Inputs: None
@@@ Return: None
leds_allOff:
	push {lr}

	bl WS2812RPi_AllOff
	bl WS2812RPi_Show

	pop {lr}
	bx lr

