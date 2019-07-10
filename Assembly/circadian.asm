start:
jmp mstart
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
jmp pwm
mstart:
;r0 is used for various things
;3eh temporarily holds calculated 12 hour time digit
mov r2, #7 ; hours
mov r3, #29 ; minutes
mov r4, #57 ; seconds
mov r5, #0  ; 1/20 seconds
mov 6, #7  	; sunrise hours
mov 7, #30 	; sunrise minutes
mov 1eh, #21 	; sunset hours
mov 1fh, #30 	; sunset minutes


;**--10h through 1fh are registers--**
;**--20h through 2fh is bitspace--**
;**--30h through 7fh is general RAM--**


;-Intensity Values for the LED strip-
mov 10h, #254 	; Red
mov 11h, #40	; Green
mov 12h, #0		; Blue
mov 13h, #20 	; White

;-OnDurations for each PWM loop-
mov 16h, 30h 	; Red
mov 17h, 31h 	; Green
mov 18h, 32h 	; Blue
mov 19h, 33h 	; White

;-Color Counter for each PWM loop-
mov 1ah, #0 	; Red
mov 1bh, #0 	; Green
mov 1ch, #0 	; Blue
mov 1dh, #0 	; White

;-Tracker for pwm-
mov r1, #0
;50h holds the value that was in accumulator
clr 4 ; Bit holds whether to flip the bit

;-How many minutes into the sunrise/sunset-
mov 14h, #0	;sunrise minutes into
mov 15h, #0	;sunset minutes into

;-Clear the clock inputs-
setb p0.7 ; set hours
setb p0.6 ; set minutes
setb p0.5 ; show sun_up
setb p0.4 ; show sun_down

setb p3.4 ; 24 hour time
setb p3.5 ; min:sec mode
setb p3.6 ; light on/off
setb p3.7 ; push night back 1 hour

;-LED output-
clr p0.3 	; Red
clr p0.2	; Green
clr p0.1	; Blue
clr p0.0	; White

;-Stop displaying all the 7-seg displays-
clr P3.0 
clr P3.1 
clr P3.2 
clr P3.3 

;-*TESTING*-
;setb 2
clr p2.0
setb p2.1

;-7segment digit lookup table-
mov 40h, #000111111b ;0  
mov 41h, #000000110b ;1
mov 42h, #001011011b ;2
mov 43h, #001001111b ;3
mov 44h, #001100110b ;4
mov 45h, #001101101b ;5
mov 46h, #001111101b ;6
mov 47h, #000000111b ;7
mov 48h, #001111111b ;8
mov 49h, #001101111b ;9

;mov 12h, #0ffh ;2 ;;;;;;;;;;TESTESTESTEST

mov TMOD, #00010001b ; Tell the timer to run as 16 bit timer for both timers
;mov 88h, #010h ;Tell the timer to run
clr tf0 ; Reset the flipped bits
clr tf1 ; Reset the flipped bits

SETB ET1 ; Enable Timer 1 interrupts
SETB EA  ; Enable interrupts
					

mov 08ch, #04ch ; set up the seconds timer
mov 08ah, #01h ; 8ch = th0, 8ah = tl0

mov TH1, #0ffh ; Timer high byte
mov TL1, #0h ; Timer low byte

setb TR0 ; Turns on timer 0
setb TR1 ; Turns on timer 1

loop:

;-Display X0:00-
	;mov p1, #0h ; Stop displaying a digit
	;clr p3.3  ; Tell the panel to prepare to display the 1000s digit  11
	;setb p3.0 ; cont
	clr 0 ; Tell the getdigit function to display a 10s digit
	jnb p3.4, hours24_X000 ; Display 24 Hour Time?
	jnb p3.5, minutes_X000 ; Display Hours or Minutes?
	jnb p0.5, sunrise_X000
	jnb p0.4, sunset_X000

hours12_X000:
	mov a, r2
	mov b, #012
	div ab
	mov a, b
	mov b, #10
	div ab
	

	cjne a, #0, hour12_skip
	mov r0, b
	cjne r0, #0, hour12_skip 	; Swaps 00 out for 12 in 12 hour time because 12 hour time is weird
	mov a, #1					; cont
	jmp hour12_skip

hours24_X000:
	mov r0, #2
	jmp rest_X000

minutes_X000:
	mov r0, #3
	jmp rest_X000

sunrise_X000:
	mov r0, #6
	jmp rest_X000

sunset_X000:
	mov r0, #1eh

rest_X000:
	lcall getdigit
	hour12_skip:
	mov p1, #0h ; Stop displaying a digit
	clr p3.3  ; Tell the panel to prepare to display the 1000s digit  11
	setb p3.0 ; cont
	lcall lookup

;-Display 0X:00-
	;mov p1, #0h ; Stop displaying a digit
	;clr p3.0 ; Tell the panel to prepare to display the 0100s digit  01
	;setb p3.1 ;
	setb 0 ; Tell the getdigit function to display a 1s digit
	jnb p3.4, hours24_0X00 ; Display 24 Hour Time
	jnb p3.5, minutes_0X00 ; Display Minutes
	jnb p0.5, sunrise_0X00 ; Display Sunrise(hours)
	jnb p0.4, sunset_0X00  ; Display Sunset(hours)

hours12_0X00:			  ; Display 12 Hour Time
	mov a, r2
	mov b, #012
	div ab

	mov a, b
	mov b, #10
	div ab
	mov a, b
	
	cjne a, #0, hour12_skip_0X 	;Swaps 00 out for 12 in 12 hour time because 12 hour time is weird
	mov a, #2					;cont
	jmp hour12_skip_0X
	
hours24_0X00:
	mov r0, #2
	jmp rest_0X00

minutes_0X00:
	mov r0, #3
	jmp rest_0X00

sunrise_0X00:
	mov r0, #6
	jmp rest_0X00

sunset_0X00:
	mov r0, #1eh

rest_0X00:
	lcall getdigit
	hour12_skip_0X:
	mov p1, #0h ; Stop displaying a digit
	clr p3.0 ; Tell the panel to prepare to display the 0100s digit  01
	setb p3.1 ;
	lcall lookup
	setb p1.7 ; Display the middle, seperator dot



;-Display 00:X0-
	;mov p1, #0h ; Stop displaying a digit
	;clr p3.1 ; Tell the panel to prepare to display the 0010s digit  10
	;setb p3.2 ;
	clr 0 ; Tell the getdigit function to display a 10s digit
	
	jnb p3.5, secs_00X0 		; Display Seconds
	jnb p0.5, sunrise_00X0 	; Display Sunrise(minutes)
	jnb p0.4, sunset_00X0 	; Display Sunset(minutes)
	mov r0, #3 		  		; Display Minutes
	jmp rest_00X0
	
secs_00X0:
	mov r0, #4 
	jmp rest_00X0 					

sunrise_00X0:
	mov r0, #7
	jmp rest_00X0 

sunset_00X0:
	mov r0, #1fh

rest_00X0:
	lcall getdigit
	mov p1, #0h ; Stop displaying a digit
	clr p3.1 ; Tell the panel to prepare to display the 0010s digit  10
	setb p3.2 ;
	lcall lookup

;-Display 00:0X-
	;mov p1, #0h ; Stop displaying a digit
	;clr p3.2 ; Tell the panel to prepare to display the 0001s digit   00
	;setb p3.3 ;
	setb 0 ; Tell the getdigit function to display a 1s digit
	 			 
	jnb p3.5, secs_000X ; Display Minutes or Seconds?
	jnb p0.5, sunrise_000X ; Display Minutes or Seconds?
	jnb p0.4, sunset_000X ; Display Minutes or Seconds?
	mov r0, #3
	jmp rest_000X

secs_000X:
	mov r0, #4
	jmp rest_000X 					

sunrise_000X:
	mov r0, #7
	jmp rest_000X 

sunset_000X:
	mov r0, #1fh	

rest_000X:
	lcall getdigit ; Find the digitmov p1, #0h ; Stop displaying a digit
	clr p3.2 ; Tell the panel to prepare to display the 0001s digit   00
	setb p3.3 ;
	lcall lookup ; Get the proper code and give it to the 7 segment display
	setb p1.7
	jb 1, timerstuff ; Decide wether to am/pm light TODO: fix
	clr p1.7 ; Set am/pm light

;-Timer Stuff-
timerstuff: 
	jnb tf0, loopm ; Stuff below happens every 20th of a second
	mov TH0, #4ch ; Reset timer
	inc TL0

timeset:
	jnb p0.5, set_sunrise ; alarm
	jnb p0.4, set_sunset ; alarm
	mov r0, #2
	lcall settime
	jmp sunrise_check


set_sunrise:
	mov r0, #6
	lcall settime
	jmp sunrise_check

set_sunset:
	mov r0, #1eh
	lcall settime


sunrise_check:
	mov a, r2 
	cjne a, 6, sunset_check
	mov a, r3
	cjne a, 7, sunset_check
sunrise: 
	setb 2
	; Sunrise Code goes here

	jmp loopm1
loopm:
	jmp loop
loopm1:

sunset_check:
	mov a, r2 
	cjne a, 1eh, countup
	mov a, r3
	cjne a, 1fh, countup
sunset:
	setb 3
	; Sunset Code goes here


countup:
	inc r5 				;20th of a second
	
	cjne r5, #20, bcj	; Carry to seconds
	mov r5, #0 ; Reset 1/20s counter
	inc r4 ; Second
	
	;-*THIS IS HERE ONLY FOR DEMONSTRATION PURPOSES*-
	jnb 2, sunrise_skipt
	inc 11h
	inc 12h
	inc 13h
	sunrise_skipt:
	;-*THIS IS HERE ONLY FOR DEMONSTRATION PURPOSES*-
	
	cjne r4, #60, bcj	; Carry to minutes
	mov r4, #0 ; 
	inc r3 ; Minute

	;Sunrise
	jnb 2, sunrise_skip

	mov a, 11h
	cjne a, #254, green_skip
	inc 11h
	green_skip:
	mov a, 12h
	cjne a, #254, blue_skip
	inc 12h
	blue_skip:
	mov a, 13h
	cjne a, #254, white_skip
	inc 13h
	white_skip:

	inc 14h
	mov a, 14h
	cjne a, #0, sunrise_skip ; If it flipped over
	clr 2
	sunrise_skip:

	;Sunset
	jnb 3, sunset_skip

	mov a, 11h
	cjne a, #40, green_skip1
	dec 11h
	green_skip1:
	mov a, 12h
	cjne a, #0, blue_skip1
	dec 12h
	blue_skip1:
	mov a, 13h
	cjne a, #20, white_skip1
	dec 13h
	white_skip1:

	inc 15h
	mov a, 15h
	cjne a, #0, sunset_skip ; If it flipped over
	clr 3
	sunset_skip:
	
	cjne r3, #60, bcj 	; Carry to hours
	mov r3, #0 
	inc r2 ; Hour
	
	cjne r2, #12, notsetpm ; Set PM if hour 12
	setb 1					; cont
	notsetpm:				; cont
	
	cjne r2, #24, bcj 	; reset hours at 24 for new day
	mov r2, #0			; cont
	clr 1				; Set AM
	

bcj: ; Unset the flipped bit and loop
	jbc tf0, loopm


lookup:
	add a, #40h
	mov r0, a
	mov p1, @r0
	ret


settime:
	jb p0.7, setmin ; If hour_set button not pressed, check for minutes
	inc @r0
	cjne @r0, #24, setend
	mov @r0, #0
	jmp setend

setmin:
	jb p0.6, setend ; If minute_set button not pressed, exit timeset
	inc r0
	inc @r0
	cjne @r0, #60, setend
	mov @r0, #0
	dec r0
	inc	@r0
	cjne @r0, #24, setend
	mov @r0, #0

setend:
	ret


getdigit:
	mov a, @r0 ; Checks r0 for what register to get the number from.
	mov b, #10
	div ab
	
	jnb 0, ones ; Checks bit 0 for 10s (0 value) or 1s (1 value).
	mov a, b	; cont
	ones:		; cont

	ret


pwm:
	mov TH1, #0ffh ; Timer high byte
	mov TL1, #0e0h ; Timer low byte
		
	;-Red-
	mov r1, 10h
	cjne r1, #0, pwm_red ; Skip everything if intensity is 0
	jmp pwm_red_skipped
	
	pwm_red:
	mov r1, 1ah
	cjne r1, #0, red_skipflip
	
	jb p0.3, red_turnoff
	setb p0.3
	mov 1ah, 10h
	jmp red_skipflip

	red_turnoff:
	clr p0.3
	mov a, 10h
	cpl a
	mov 1ah, a

	red_skipflip:
	dec 1ah

	pwm_red_skipped:

	;-Green-
	mov r1, 11h
	cjne r1, #0, pwm_green ; Skip everything if intensity is 0
	jmp pwm_green_skipped
	
	pwm_green:
	mov r1, 1bh
	cjne r1, #0, green_skipflip
	
	jb p0.2, green_off
	setb p0.2
	mov 1bh, 11h
	jmp green_skipflip

	green_off:
	clr p0.2
	mov a, 11h
	cpl a
	mov 1bh, a

	green_skipflip:
	dec 1bh

	pwm_green_skipped:

	;-Blue-
	mov r1, 12h
	cjne r1, #0, pwm_blue ; Skip everything if intensity is 0
	jmp pwm_blue_skipped
	
	pwm_blue:
	mov r1, 1ch
	cjne r1, #0, blue_skipflip
	
	jb p0.1, blue_off
	setb p0.1
	mov 1ch, 12h
	jmp blue_skipflip

	blue_off:
	clr p0.1
	mov a, 12h
	cpl a
	mov 1ch, a

	blue_skipflip:
	dec 1ch

	pwm_blue_skipped:

	;-White-
	mov r1, 13h
	cjne r1, #0, pwm_white ; Skip everything if intensity is 0
	jmp pwm_white_skipped
	
	pwm_white:
	mov r1, 1dh
	cjne r1, #0, white_skipflip
	
	jb p0.0, white_off
	setb p0.0
	mov 1dh, 13h
	jmp white_skipflip

	white_off:
	clr p0.0
	mov a, 13h
	cpl a
	mov 1dh, a

	white_skipflip:
	dec 1dh

	pwm_white_skipped:

	reti
