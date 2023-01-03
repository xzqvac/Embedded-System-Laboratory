.org 0x0000
	jmp start		; Reset handler
.org 0x0040
	jmp timer0_ovf_irq 	; Timer0 Overflow Handler

.include "include/atmega328p.s"
.include "include/macros.s"

; 7 segment controller mc74hc595
; SDI - portb 0
; SHIFT CLK - portd 7
; LATCH CLK - portd 4

.section .data
screen_data:
	.space 2

screen_bit:
	.space 1

shift_clk:
	.space 1

.section .text

; Interrupt handler
timer0_ovf_irq:
	; screen_bit = 32, decrement with every interrupt till -1
	; Check screen_bit if -1, skip, because all bits has been sent OR 000???

	load_register_Z screen_bit 				; pointer to screen_bit, reg_Z pointer to screen_bit address
	ld r16, Z 								; load reg_Z to reg_16
	tst r16 								; check if <= 0, set flag Z or N flag if <= 0
	brmi timer0_ovf_irq_zero_latch_clk 		; branch if minus, check N flag

	; Check screen_bit if 0, skip, but rise latch_clk
	
	dec r16 								; decrement reg_16, sets N flag
	st Z, r16 								; store reg_16 to reg_Z(screen_bit)
	brmi timer0_ovf_irq_one_latch_clk 		; screen_bit = 32

	; Toggle shift clk 
	
	load_register_Z shift_clk				; pointer to shitf_clk
	ld r16, Z								; load reg_Z(shift_clk) to reg_16, on start 1111 1111
	com r16									; negation of reg_16, on start 0000 0000
	st Z, r16								; store reg_16 in reg_Z(shitf_clk)
	lds r17, PORTD 							; logical state, on start portD = 1??1 ????
	andi r17, 0x7F 							; logical AND immediatly with 0x7F
	andi r16, 0x80 							; logical AND immediatly with 0x80
	or r17, r16    							; logical OR r17, r16
	sts PORTD, r17 							; store r17 to PORTD (0??? ????)

	; Update sdi only on falling edge

	tst r16									; test for Zero or Minus on r16
	brne timer0_ovf_irq_end					; test Z flag, if true go to timer0_ovf_irq_end

	; Rotate screen data, oldest bit in r18
	; on start sceen_data = 0x08 and A4;
	load_register_Z screen_data 			; pointer do screen_data, reg_Z pointer to scree_data address
	ld r16, Z+								; load reg_Z to r16, plus increment address to r17
	ld r17, Z+								; load reg_Z to r17, plus increment address(FOR WHAT???)
	clr r18 								; clear register 18 with xnor operation
	clc 									; clear C(carry) flag
	rol r16 								; rotate left with carry
	rol r17 								; rotate left wtih carry
	rol r18 								; rotate left with carry
	st -Z, r17 								; store to reg_Z(31) from reg_17
	st -Z, r16								; store to reg_Z(30) from reg_16

	; Put correct data on sdi

	lds r16, PORTB							; load direct from PORTB data space to r16, SDI PORTB0
	sbrc r18, 0 							; check bit 0 is zero, skip next instruction if bit 0 in register r18 is cleared
	sbr r16, 0x01 							; do ORI operation on reg_16 if not skipped
	sbrs r18, 0 							; check bit 0 is zero 
	cbr r16, 0x01 							; do operation AND clear
	sts PORTB, r16 							; store direct to data space

	jmp timer0_ovf_irq_end

timer0_ovf_irq_one_latch_clk:				; push all data after 33 cycles
	lds r16, PORTD							; load direct from PORTD data space to reg_16
	sbr r16, 0x10 							; set 0x10 (0001 0000) on reg_16
	sts PORTD, r16							; store direct to PORTD from reg_16
	jmp timer0_ovf_irq_end					
timer0_ovf_irq_zero_latch_clk:		
	lds r16, PORTD							; load direct from PORTD data space to reg_16
	cbr r16, 0x10 							; clear bits in register, do AND register
	sts PORTD, r16
timer0_ovf_irq_end:
	reti

; Interrupt handler
start:
	load_register_16 SPH, SPL, _stack_top

	lds r16, DDRB 							; DDRB at start is 0x24 = 0010 0100
	sbr r16, 0x01 							; set bits register (r16 ori 0x01) to r16, ???? ???1, SDI PORT_B0
	sts DDRB, r16 

	lds r16, DDRD 							; DDRA start is 0x2A = 0010 1010
	sbr r16, 0x90 							; set bits register (r16 ori 0x90) to r16, 1??1 ????, shift_clk 7, latch_clk 4
	sts DDRD, r16

	load_register_8 TCCR0B, 0x01
	load_register_8 TIMSK0, 0x01
	load_register_8 TCNT0, 0x00
											; loading pointers to SRAM
	load_register_Z shift_clk 				; load shift_clk to register Z, pointer to shift_clk. Data are stored on shift_clk 
	ldi r16, 0xFF 							; load 0xFF to r16
											; store Indirect From Register to Data Space using Index X
	st Z, r16 								; load r16 to reg_Z(shift_clk)

	load_register_Z screen_data 			; data to shift register
	ldi r16, 0x08 							; load imiedietly enable display
	st Z+, r16 								; load r16 to reg_Z(shift_clk) and inc address of reg_Z
	ldi r16, 0xA4 							; load imiedietly segments of digit
	st Z, r16 								; load r16 to reg_Z

	load_register_Z screen_bit 				; how many bits are send
	ldi r16, 33 							; counting from 33 to 1(8 bits for enable display, 8 bits for enable segments), last bit is for setting SDI on 1
	st Z, r16 								; load r16 to reg Z

	sei 									; sets flag interrupt
sleep:
	sleep
	jmp sleep
