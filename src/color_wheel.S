//----------------------------------------------------------------
// project: 	M&M Sortmachine
// group members:
//		- Demiroez, Dilara
//		- Gonther, Levin
//		- Grajczak, Benjamin
//		- Pfister, Marc
//  target:	 	Raspberry Pi Zero
//    date:	 	2020/02/01
// verison: 	1.0.0
//----------------------------------------------------------------
// This document deals with the following tasks:
//		- Method to calibrate the color wheel
//		- Method to roate the color wheel in 90° steps
//----------------------------------------------------------------

.text

.global color_wheel_calibrate
.global color_wheel_rotate90

color_wheel_calibrate:
	bx lr

color_wheel_rotate90:
	bx lr
