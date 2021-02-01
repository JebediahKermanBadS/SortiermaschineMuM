@@@ M&M Sortingmachine
@@@ --------------------------------------------------------------
@@@ group members:
@@@		- Demiroez Dilara
@@@		- Gonther, Levin
@@@		- Grajczak, Benjamin
@@@		- Pfister, Marc
@@@ target:	 Raspberry Pi Zero
@@@	date:	 2020/01/27
@@@	verison: 1.0.0
@@@ --------------------------------------------------------------
@@@ This document deals with the following tasks:
@@@		- Method to set the feeder on
@@@ 	- Method to set the feeder off
@@@ --------------------------------------------------------------

@@@ Pin of the Feeder --------------------------------------------
	.equ pin_feeder,	19

.text

.global set_feeder_on
.global set_feeder_off

@@@ --------------------------------------------------------------
@@@ This method sets the feeder to on
@@@ Input paramter: None
@@@ Returns: Nothing
@@@ --------------------------------------------------------------
set_feeder_on:
	bx lr


set_feeder_off:
	bx lr
