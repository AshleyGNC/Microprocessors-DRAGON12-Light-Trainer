; single person ping pong game
; along the LED Ligths
; using push buttons PH3 and PH0 to play
; DIP switches 1-3 (PH7-PH5) to start the game at levels 1-3
; prevent cheating, increase velocity (decrease time delay)
; keep score in seven segment display (up to 5)
; the Blue Display with MyName and Instructions
; Implement levels 2 and 3


#include "reg9s12.h"			; include this file in the directory

lcd_dat equ	PortK   	; LCD data pins (PK5~PK2)
lcd_dir equ   	DDRK    	; LCD data direction port
lcd_E   equ   	$02     	; E signal pin
lcd_RS  equ   	$01     	; RS signal pin

led0:	equ	$01		; 0000 0001 => PB0=1 for LED0
led1:	equ	$02		; 0000 0010 => PB1=1 for LED1
led2:	equ	$04		; 0000 0100 => PB2=1 for LED2
led3:	equ	$08		; 0000 1000 => PB3=1 for LED3
led4: 	equ	$10		; 0001 0000 => PB4=1 for LED4
led5:  equ	$20		; 0010 0000 => PB5=1 for LED5
led6:  equ	$40		; 0100 0000 => PB6=1 for LED6
led7:  equ	$80		; 1000 0000 => PB7=1 for LED7

		org	$1000
select		rmb	1		; Stuff for GAME OVER
d1ms_flag	rmb	1
disp_data	rmb	4
disptn		rmb	4
score		rmb	1		; reserved memory for the score
counter 	rmb	1		; reserved memory for byte
checkLevel	rmb	1		; check what level we are on

		org	$2000		; start of main program
	
; Display INSTRUCTIONS
	
		lds   	#$2000  	; set up stack pointer
		jsr   	openLCD 	; initialize the LCD
		ldx   	#msg1		; point to the first line of message
		jsr   	putsLCD		; display in the LCD screen
		ldaa	#$C0		; move to the second row 
		jsr	cmd2LCD	;	"
		ldx   	#msg2		; point to the second line of message
		jsr   	putsLCD

; here add instructions to shift the display to see the whole sentence,
PlayAgain	ldaa	#$28		; Use $50/2 = $28 to finish at center after 1 round
		staa	counter		; load counter to start from $50 
	
loop		jsr	delayI		; delay before the character move (easier to read from the begining)
		ldaa	#$18		; load $18 to A to use in the subroutine
		jsr	cmd2LCD		; start of subroutine cmd2LCD
		jsr	delayI		; delay after the character move

		dec	counter		; decrement counter
		bne	loop		; continue to loop until counter is 0

		lbra	game


;messages to display
msg1 		dc.b   	"Ashley Garcia",0
msg2 		dc.b  	"Use DIP 1-3 to begin level(s) 1-3",0

; additional delay loop to slow down the display shift 
delayI		ldab	#$30		; blinking rate
delayI1		ldx	#$FFFF		; generate a $FFFF long loop
delayI2		dbne	x,delayI2	; loop x amount of times	
		dbne	b,delayI1	; loop through delay1	 for b amount of times
		rts			; end of subroutine

; the command is contained in A when calling this subroutine from main program
cmd2LCD		psha				; save the command in stack
		bclr  	lcd_dat, lcd_RS	; set RS=0 for IR => PTK0=0
		bset  	lcd_dat, lcd_E 	; set E=1 => PTK=1
		anda  	#$F0    	; clear the lower 4 bits of the command
		lsra 			; shift the upper 4 bits to PTK5-2 to the 
		lsra            	; LCD data pins
		oraa  	#$02  		; maintain RS=0 & E=1 after LSRA
		staa  	lcd_dat 	; send the content of PTK to IR 
		nop			; delay for signal stability
		nop			; 	
		nop			;	
		bclr  	lcd_dat,lcd_E   ; set E=0 to complete the transfer

		pula			; retrieve the LCD command from stack	
		anda  	#$0F    	; clear the lower four bits of the command
		lsla            	; shift the lower 4 bits to PTK5-2 to the
		lsla            	; LCD data pins
		bset  	lcd_dat, lcd_E 	; set E=1 => PTK=1
		oraa  	#$02  		; maintain E=1 to PTK1 after LSLA
		staa  	lcd_dat 	; send the content of PTK to IR
		nop			; delay for signal stability
		nop			;	
		nop			;	
		bclr  	lcd_dat,lcd_E	; set E=0 to complete the transfer

		ldy	#1		; adding this delay will complete the internal
		jsr	delay50us	; operation for most instructions
		rts

openLCD movb	#$FF,lcd_dir		; configure Port K for output
	ldy   	#2			; wait for LCD to be ready
	jsr   	delay100ms		;	"
	ldaa  	#$28            	; set 4-bit data, 2-line display, 5 × 8 font
	jsr   	cmd2lcd         	;       "	
	ldaa  	#$0F           	; turn on display, cursor, and blinking
	jsr   	cmd2lcd        	;       "
	ldaa  	#$06           	; move cursor right (entry mode set instruction)
	jsr   	cmd2lcd       	  	;       "
	ldaa  	#$01            	; clear display screen and return to home position
	jsr   	cmd2lcd         	;       "
	ldy   	#2              	; wait until clear display command is complete
	jsr   	delay1ms   		;       "
	rts 	

; The character to be output is in accumulator A.
putcLCD	psha                    	; save a copy of the chasracter
	bset  	lcd_dat,lcd_RS		; set RS=1 for data register => PK0=1
	bset  	lcd_dat,lcd_E  	; set E=1 => PTK=1
	anda  	#$F0            	; clear the lower 4 bits of the character
	lsra           		; shift the upper 4 bits to PTK5-2 to the
	lsra            		; LCD data pins
	oraa  	#$03            	; maintain RS=1 & E=1 after LSRA
	staa  	lcd_dat        	; send the content of PTK to DR
	nop                  		; delay for signal stability
	nop                     	;      
	nop                     	;     
	bclr  	lcd_dat,lcd_E   	; set E=0 to complete the transfer

	pula				; retrieve the character from the stack
	anda  	#$0F    		; clear the upper 4 bits of the character
	lsla            		; shift the lower 4 bits to PTK5-2 to the
	lsla            		; LCD data pins
	bset  	lcd_dat,lcd_E   	; set E=1 => PTK=1
	oraa  	#$03            	; maintain RS=1 & E=1 after LSLA
	staa  	lcd_dat			; send the content of PTK to DR
	nop				; delay for signal stability
	nop				;
	nop				;
	bclr  	lcd_dat,lcd_E   	; set E=0 to complete the transfer

	ldy	#1			; wait until the write operation is complete
	jsr	delay50us		; 
	rts


putsLCD		ldaa  	1,X+   		; get one character from the string
		beq   	donePS		; reach NULL character?
		jsr   	putcLCD
		bra   	putsLCD
donePS		rts 


delay1ms 	movb	#$90,TSCR	; enable TCNT & fast flags clear
		movb	#$06,TMSK2 	; configure prescale factor to 64
		bset	TIOS,$01		; enable OC0
		ldd 	TCNT
again0		addd	#375		; start an output compare operation
		std	TC0		; with 50 ms time delay
wait_lp0	brclr	TFLG1,$01,wait_lp0
		ldd	TC0
		dbne	y,again0
		rts

delay100ms 	movb	#$90,TSCR	; enable TCNT & fast flags clear
		movb	#$06,TMSK2 	; configure prescale factor to 64
		bset	TIOS,$01		; enable OC0
		ldd 	TCNT
again1		addd	#37500		; start an output compare operation
		std	TC0		; with 50 ms time delay
wait_lp1	brclr	TFLG1,$01,wait_lp1
		ldd	TC0
		dbne	y,again1
		rts

delay50us 	movb	#$90,TSCR	; enable TCNT & fast flags clear
		movb	#$06,TMSK2 	; configure prescale factor to 64
		bset	TIOS,$01		; enable OC0
		ldd 	TCNT
again2		addd	#15		; start an output compare operation
		std	TC0		; with 50 ms time delay
wait_lp2	brclr	TFLG1,$01,wait_lp2
		ldd	TC0
		dbne	y,again2	; decrease y, loop to again if y is not 0
		rts			; end of subroutine
		
		bra	game

;end of INSTRUCTIONS display

;game program

game		movb	#$FF, DDRB	; set bits 0-7 of port B as output AND 7-Segment Display
		bset	DDRJ, $02	; set port J bit 1 =1 for output (in Dragon12 board)
		bclr	PTJ, $02	; set port J bit 1 =0 to enable the LEDs 

		movb	#$FF, DDRP	; set port P as output
		movb	#$0F, PTP	; turn off 7-segment displays (in Dragon12 board) [LATER TRY TO TURN OONNN]
		movb	#$00, DDRH	; set port H as input for DIP switches
 
		
; clear all bits to turn off LED0-7 connected PortB bits 0-7
		bclr	PORTB,led0+led1+led2+led3+led4+led5+led6+led7

main		ldx	#$00			; set score to 0
		stx	score			; 	"
		brset	PTH,$80,longlevel1	; test the status of PH7 (DIP Switch #1), branch to respective level
		brset	PTH,$40,longlevel2	; test the status of PH6 (DIP Switch #2), branch to respective level
		brset	PTH,$20,longlevel3	; test the status of PH5 (DIP Switch #3), branch to respective level	
		bra	main			; branch to main
longlevel1	lbra	level1
longlevel2	lbra	level2
longlevel3	lbra	level3

lost		movb	#$00, PTP		; turn on 7-segment displays (in Dragon12 board)
		bra	displayScore		; dsiplay scores up to 5

continue	lbra	PlayAgain		; want to play again? Start at the instruction sequence
		jsr 	delay 			; time delay for DISP1
		swi

; displays scores up to 5!!
displayScore	ldaa	score

zero		cmpa 	#$00 			; compare with digit 1
		bne 	one
		movb 	#$3F,PortB 		; show digit 1
		lbra 	show

one		cmpa 	#$01 			; compare with digit 1
		bne 	two
		movb 	#$06,PortB 		; show digit 1
		lbra 	show

two 		cmpa 	#$02 			; compare with digit 2
		bne 	three
		movb 	#$5B,PortB 		; show digit 2
		lbra 	show
three 		cmpa 	#$03 			; compare with digit 3
		bne 	four
		movb 	#$4F,PortB 		; show digit 3
		lbra 	show
four 		cmpa 	#$04 			; compare with digit 4
		bne 	five
		movb 	#$66,PortB 		; show digit 4 
		lbra 	show
five 		cmpa 	#$05 			; compare with digit 5
		lbgt 	continue		; don't show if >5
		movb 	#$6D,PortB 		; show digit 5
		lbra 	show

show 		movb 	#$0E, PTP 		; turn on DISP1 (leftmost) 
		jsr 	delay 			; time delay for DISP1 
		lbra 	continue 


;Cheating Prevention
cheater		ldaa	#$00			; display score of 0 for cheaters
		staa	score
		lbra	lost



;------------------------------------GAME-CODE----------------------------------------------	

level1		; Single Ping Pong Ball (slow)   
		;starting round
		bset	PortB, led3		; LED 3 on;
		jsr	delay			; generate the desired delay
		bclr	PortB, led3		; LED 3 off; 
		jsr	delay			; generate delay again

		bset	PortB, led2		; LED 2 on; 
		jsr	delay			; generate the desired delay
		bclr	PortB, led2		; LED 2 off; 
		jsr	delay			; generate delay again

		bset	PortB, led1		; LED 1 on; 
		jsr	delay			; generate the desired delay
		bclr	PortB, led1		; LED 1 off; 
		jsr	delay			; generate delay again
		brclr	PTH,$01,cheater	; check if person pressing PHO :( CHEATER

			
		;START!!
		bset	PortB, led0		; LED 0 on; 
		jsr	delay			; generate the desired delay
		brclr	PTH,$01,point		; check if person pressed PHO :), if they didn't, they lost
		lbra	lost

point		inc	score
		bclr	portB, led0		; LED 0 off; 
		jsr	delay			; generate delay again

		bset	PortB, led1		; LED 1 on;
		jsr	delay			; generate the desired delay
		bclr	PortB, led1		; LED 1 off; 
		jsr	delay			; generate delay again

		bset	PortB, led2		; LED 2 on; 
		jsr	delay			; generate the desired delay
		bclr	PortB, led2		; LED 2 off; 
		jsr	delay			; generate delay again

		bset	PortB, led3		; LED 3 on; 
		jsr	delay			; generate the desired delay
		bclr	PortB, led3		; LED 3 off; 
		jsr	delay			; generate delay again

		bset	PortB, led4		; LED 4 on; 
		jsr	delay			; generate the desired delay
		bclr	PortB, led4		; LED 4 off; 
		jsr	delay			; generate delay again

		bset	PortB, led5		; LED 5 on; 
		jsr	delay			; generate the desired delay
		bclr	PortB, led5		; LED 5 off; 
		jsr	delay			; generate delay again

		bset	PortB, led6		; LED 6 on; 
		jsr	delay			; generate the desired delay
		bclr	PortB, led6		; LED 6 off; 
		jsr	delay			; generate delay again

		brset	PTH,$08,keep1		; check if person pressing PH3 :( CHEATER
		lbra	cheater

keep1		bset	PortB, led7		; LED 7 on; 
		jsr	delay			; generate the desired delay

		brclr	PTH,$08,point2		; check if person pressed PH3 :), if they didn't, they lost
		lbra	lost

point2		inc	score
		bclr	PortB, led7		; LED 7 off; 
		jsr	delay			; generate delay again
	
	;bounce back
		bset	PortB, led6		; LED 6 on; 
		jsr	delay			; generate the desired delay
		bclr	PortB, led6		; LED 6 off; 
		jsr	delay			; generate delay again

		bset	PortB, led5		; LED 5 on; 
		jsr	delay			; generate the desired delay
		bclr	PortB, led5		; LED 5 off; 
		jsr	delay			; generate delay again

		bset	PortB, led4		; LED 4 on; 
		jsr	delay			; generate the desired delay
		bclr	PortB, led4		; LED 4 off; 
		jsr	delay			; generate delay again

		bset	PortB, led3		; LED 3 on; 
		jsr	delay			; generate the desired delay
		bclr	PortB, led3		; LED 3 off; 
		jsr	delay			; generate delay again

		bset	PortB, led2		; LED 2 on; 
		jsr	delay			; generate the desired delay
		bclr	PortB, led2		; LED 2 off; 
		jsr	delay			; generate delay again


		bset	PortB, led1		; LED 1 on; 
		jsr	delay			; generate the desired delay
		bclr	PortB, led1		; LED 1 off; 
		jsr	delay			; generate delay again


		brset	PTH,$01,keep2		; check if person pressing PHO :( CHEATER
		lbra	cheater

keep2		bset	PortB, led0		; LED 0 on; 
		jsr	delay			; generate the desired delay

		brclr	PTH,$01,point3		; check if person pressed PHO :), if they didn't, they lost
		lbra	lost

point3		lbra	point
			


; delay subroutine; use 2 loops to set the desired time delay
delay:		ldab	#$30			; adjust the value to change blinking rate 
delay1:		ldx	#$FFFF		 	; generate a $FFFF long loop
delay2:		dbne	x,delay2		; loop x amount of times
		dbne	b,delay1		; loop throguh delay1 for b amount of times
		rts


cheaterL2	lbra	cheater
level2 		;Single PingPong Ball (fast)
;starting round
		bset	PortB, led3		; LED 3 on;
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led3		; LED 3 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led2		; LED 2 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led2		; LED 2 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led1		; LED 1 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led1		; LED 1 off; 
		jsr	delayPrime		; generate delay again
		brclr	PTH,$01,cheaterL2	; check if person pressing PHO :( CHEATER


			
		;START!!
		bset	PortB, led0		; LED 0 on; 
		jsr	delayPrime		; generate the desired delay
		ldaa	PTH
		brclr	PTH,$01,pointL2	; check if person pressed PHO :), if they didn't, they lost
		lbra	lost

pointL2		inc	score
		bclr	portB, led0		; LED 0 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led1		; LED 1 on;
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led1		; LED 1 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led2		; LED 2 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led2		; LED 2 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led3		; LED 3 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led3		; LED 3 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led4		; LED 4 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led4		; LED 4 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led5		; LED 5 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led5		; LED 5 off; 
		jsr	delayPrime		; generate delay again


		bset	PortB, led6		; LED 6 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led6		; LED 6 off; 
		jsr	delayPrime		; generate delay again

		brset	PTH,$08,keepL2.1	; check if person pressing PH3 :( CHEATER
		lbra	cheater

keepL2.1	bset	PortB, led7		; LED 7 on; 
		jsr	delayPrime		; generate the desired delay

		brclr	PTH,$08,pointL2.2	; check if person pressed PH3 :), if they didn't, they lost
		lbra	lost

pointL2.2	inc	score
		bclr	PortB, led7		; LED 7 off; 
		jsr	delayPrime		; generate delay again
	
	;bounce back
		bset	PortB, led6		; LED 6 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led6		; LED 6 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led5		; LED 5 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led5		; LED 5 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led4		; LED 4 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led4		; LED 4 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led3		; LED 3 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led3		; LED 3 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led2		; LED 2 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led2		; LED 2 off; 
		jsr	delayPrime		; generate delay again


		bset	PortB, led1		; LED 1 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led1		; LED 1 off; 
		jsr	delayPrime		; generate delay again

		brset	PTH,$01,keepL2.2	; check if person pressing PHO :( CHEATER
		lbra	cheater

keepL2.2	bset	PortB, led0		; LED 0 on; 
		jsr	delayPrime		; generate the desired delay

		brclr	PTH,$01,pointL2.3	; check if person pressed PHO :), if they didn't, they lost
		lbra	lost

pointL2.3	lbra	pointL2

; delay subroutine for level 2 and 3
delayPrime:	ldab	#$20			; adjust the value to change blinking rate 
delayPrime1:	ldx	#$FFFF		 	; generate a $FFFF long loop
delayPrime2:	dbne	x,delayPrime2		; loop x amount of times
		dbne	b,delayPrime1		; loop throguh delay1 for b amount of times
		rts

cheaterL3	lbra	cheater
level3		;Double PingPong Ball
		
		;starting round
		bset	PortB, led3		; LED 3 on;
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led3		; LED 3 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led2		; LED 2 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led2		; LED 2 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led1		; LED 1 on; 
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led1		; LED 1 off; 
		jsr	delayPrime		; generate delay again
		brclr	PTH,$01,cheaterL3	; check if person pressing PHO :( CHEATER


			
		;START!!
pointL3Prime	bset	PortB, led0		; LED 0 on; 
		jsr	delayPrime		; generate the desired delay
		ldaa	PTH
		brclr	PTH,$01,pointL3	; check if person pressed PHO :), if they didn't, they lost
		lbra	lost

pointL3		inc	score
		bclr	PortB, led0		; LED 0 off; 
		jsr	delayPrime		; generate delay again

		bset	PortB, led1		; LED 1 on;
		bset	PortB, led4		; LED 4 on;
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led1		; LED 1 off; 
		bclr	PortB, led4		; LED 4 off;
		jsr	delayPrime		; generate delay again

		bset	PortB, led2		; LED 2 on; 
		bset	PortB, led5		; LED 5 on;
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led2		; LED 2 off; 
		bclr	PortB, led5		; LED 5 off;
		jsr	delayPrime		; generate delay again
		brset	PTH,$01,keepL3.1	; check if person pressing PH0 :( CHEATER
		lbra	cheater

keepL3.1	bset	PortB, led3		; LED 3 on; 
		bset	PortB, led6		; LED 6 on;
		jsr	delayPrime		; generate the desired delay
		brclr	PTH,$01,cont1		; check if person pressed PH0 :), if they didn't, they lost
		lbra	lost

cont1		bclr	PortB, led3		; LED 3 off; 
		bclr	PortB, led6		; LED 6 off;
		jsr	delayPrime		; generate delay again
		brset	PTH,$08,keepL3.2	; check if person pressing PH3 :( CHEATER
		lbra	cheater

keepL3.2	bset	PortB, led7		; LED 7 on; 
		bset	PortB, led2		; LED 2 on;
		jsr	delayPrime		; generate the desired delay
		brclr	PTH,$08,pointL3.2	; check if person pressed PH3 :), if they didn't, they lost
		lbra	lost

pointL3.2	inc	score
		bclr	PortB, led7		; LED 7 off; 
		bclr	PortB, led2		; LED 2 off;
		jsr	delayPrime		; generate delay again
	
	;bounce back
		bset	PortB, led6		; LED 6 on; 
		bset	PortB, led1		; LED 1 on;
		jsr	delayPrime		; generate the desired delay
		bclr	PortB, led6		; LED 6 off; 
		bclr	PortB, led1		; LED 1 off;
		jsr	delayPrime		; generate delay again
		brset	PTH,$01,keepL3.3	; check if person pressing PH0 :( CHEATER
		lbra	cheater

keepL3.3	bset	PortB, led5		; LED 5 on; 
		bset	PortB, led0		; LED 0 on;
		jsr	delayPrime		; generate the desired delay
		brclr	PTH,$01,cont2		; check if person pressed PHO :), if they didn't, they lost
		lbra	lost

cont2		bclr	PortB, led5		; LED 5 off; 
		bclr	PortB, led0		; LED 0 off;
		jsr	delayPrime		; generate delay again
		brset	PTH,$08,keepL3.4	; check if person pressing PH3 :( CHEATER
		lbra	cheater

keepL3.4	bset	PortB, led4		; LED 4 on; 
		jsr	delayPrime		; generate the desired delay
		brclr	PTH,$08,pointL3.3	; check if person pressed PH3 :), if they didn't, they lost
		lbra	lost

pointL3.3	bclr	PortB, led4		; LED 4 off;
		jsr	delayPrime		; generate the desired delay
		lbra	pointL3Prime
		
		end				; end of user program	
