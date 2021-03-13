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

@@@ Renamimg registers ----------------------------------------------------------------------
	rTIMER	.req r9
	rGPIO	.req r10

@@@ Pins for the objectsensor in the outlet -------------------------------------------------
	.equ pin_objCW,		25

@@@ Define the offset for the GPIO Registers ------------------------------------------------
	.equ GPFSET0, 	0x00
	.equ GPFSET1, 	0x04
	.equ GPSET0,	0x1C
	.equ GPCLR0,	0x28
	.equ GPLVL0,	0x34


	.equ pin_nBTN1,		8
	.equ GPEDS0,	0x40


.data
.align 4

msg_init: .asciz "M&M Sorting Machine started!\nThis is a program from the following group:\n\t- Demiroez, Dilara\n\t- Gonther, Levin\n\t- Grajczak, Benjamin\n\t- Pfister, Marc\n"
msg_gpio_mem: 	.asciz "Gpio memory is: %p\n"
msg_timer_mem: 	.asciz "Timer memory is: %p\n"
msg_calibration_finished: .asciz "The calibration of the outlet and the color wheel is finished.\n"

@ This is the waiting remaining time for the co-processor to read a color (in ms). Reset value is defined in cop_reading_time_reset
.align 4
cop_reading_time: .word 1000

@ If the machine is running this is 1
.align 4
is_running:	.word 0

@ Used in the calculation of the outlet position
.align 4
color_array: .word 0
			 .word 1
			 .word 2
			 .word 3
			 .word -2
			 .word -1

@ The current outlet position
.align 4
outlet_position: .word 0


@@@ -----------------------------------------------------------------------------------------
@@@ -----------------------------------------------------------------------------------------
.text

@ Reset value of the co processors reading time
cop_reading_time_reset: .word 1000
addr_cop_reading_time: .word cop_reading_time

addr_is_running: 	.word is_running

@@@ Method to print text to the console
.extern printf

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

.extern segment7_init

.global main
main:
	push {fp, lr}
	mov fp, sp

	@ Print the inital message
	ldr r0, =msg_init
	bl printf

	@ Map the virtual address for the gpio registers
	bl mmap_gpio
	mov rGPIO, r0
	cmp rGPIO, #-1
	beq main_end

	@ Map the virtual address for the timer registers
	bl mmap_timerIR
	mov rTIMER, r0
	cmp rTIMER, #-1
	beq main_end

	@ Print the virtual address for the gpio reigsters
	ldr r0, =msg_gpio_mem
	mov r1, rGPIO
	bl printf

	@ Print the virtual address for the timer reigsters
	ldr r0, =msg_gpio_mem
	mov r1, rTIMER
	bl printf

	@@@ Init all the hardware ---------------------------------------------------------------
	bl cop_init
	bl color_wheel_init
	bl feeder_init
	bl leds_Init
	bl outlet_init
	bl timer_init
	bl buttons_init
	bl segment7_init

	bl calibrate

	ldr r0, =msg_calibration_finished
	bl printf

	ldr r4, =case_rotate_color_wheel
	mov r5, #-1 						@ r5: read color
	main_loop:

		ldr r0, [rGPIO, #GPLEV0]
		ands r0, #1 << pin_objCW
		beq machine_stop		@ Object Pin == 0 : No M&M detected

		ldr r0, [rTIMER, #0x410]
		cmp r0, #0
		beq check_btn

		bl segment7_next

		ldr r0, =is_running
		ldr r0, [r0]
		cmp r0, #0
		beq check_btn


		@ Else:
		mov pc, r4
		case_rotate_color_wheel:
			bl color_wheel_rotate90
			cmp r0, #0
			ldreq r4, =case_read_color

			b case_end

		case_read_color:
			ldr r0, addr_cop_reading_time
			ldr r1, [r0]
			subs r1, #1
			str r1, [r0]
			bne case_end

			ldr r1, cop_reading_time_reset
			str r1, [r0]

			bl color_wheel_reset_rotation

			bl cop_read_color

			@ If the color is not recognized set it to brown
			cmp r0, #-1
			moveq r0, #3
			mov r5, r0

			bl leds_showColor

			@@ position outlet
			ldr r0, =color_array
			ldr r2, =outlet_position
			ldr r1, [r2]
			str r5, [r2]

			@ calculate offset
			subs r1, r5, r1
			addmi r1, r1, #6

			ldr r1, [r0, r1, LSL #2]
			cmp r1, #0
			ldreq r4, =case_rotate_color_wheel  @ r1 == 0
			ldrlt r4, =case_rotate_outlet_cclockwise		@ r1 < 0
			ldrgt r4, =case_rotate_outlet_clockwise

			mov r0, r1
			str r0, [sp, #-4]!
			blgt outlet_rotate_clockwise_initiate

			ldr r0, [sp], #4
			cmp r0, #0
			bllt outlet_rotate_counterclockwise_initiate

			b case_end

		case_rotate_outlet_clockwise:
			bl outlet_rotate60_counterclockwise
			cmp r0, #0
			ldreq r4, =case_rotate_color_wheel

			b case_end

		case_rotate_outlet_cclockwise:
			bl outlet_rotate60_counterclockwise
			cmp r0, #0
			ldreq r4, =case_rotate_color_wheel

			b case_end

		case_end:
		ldr r0, [rTIMER, #0x410]
		str r0, [rTIMER, #0x40C]

		check_btn:
			ldr r0, [rGPIO, #GPEDS0]
			ands r0, #1 << pin_nBTN1
			beq main_loop

			str r0, [rGPIO, #GPEDS0]

			ldr r0, addr_is_running
			ldr r0, [r0]
			cmp r0, #0
			str r0, [sp, #-4]!
			bleq machine_start
			ldr r0, [sp], #4
			cmp r0, #1
			bleq machine_stop

		b main_loop

main_munmap_pgpio:
	mov r0, rTIMER
	bl unmap_memory

	mov r0, rGPIO
	bl unmap_memory

main_end:
	bl leds_DeInit

	mov sp, fp
	pop {fp, lr}
	bx lr


calibrate:
	push {r4, lr}

	mov r0, #1
	bl color_wheel_set_enable
	mov r0, #1
	bl outlet_set_enable
	mov r0, #1
	bl timer_set_enable
	bl cop_wakeup
	calibrate_loop:
		ldr r0, [rTIMER, #0x410]
		cmp r0, #0
		beq calibrate_loop

		@ Timer counted to zero. 1ms is over
		str r0, [rTIMER, #0x40C]
		bl color_wheel_calibrate
		mov r4, r0

		bl outlet_calibrate
		cmp r0, #0
		bgt calibrate_loop
		cmp r4, #0
		bgt calibrate_loop

	bl color_wheel_set_enable
	mov r0, #0
	bl outlet_set_enable
	bl cop_sleep

	pop {r4, lr}
	bx lr

machine_start:
	push {lr}

	bl feeder_on
	bl cop_wakeup
	mov r0, #1
	bl color_wheel_set_enable
	mov r0, #1
	bl outlet_set_enable
	mov r0, #1
	bl timer_set_enable

	mov r1, #1
	ldr r0, addr_is_running
	str r1, [r0]

	pop {lr}
	bx lr

machine_stop:
	push {lr}
	bl feeder_off
	bl cop_sleep
	mov r0, #0
	bl color_wheel_set_enable
	mov r0, #0
	bl outlet_set_enable

	mov r1, #0
	ldr r0, addr_is_running
	str r1, [r0]

	pop {lr}
	bx lr



