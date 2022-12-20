.org 0x0000
	jmp start		; Reset handler
.org 0x0016
	jmp pcint1_irq		; Pin Change Interrupt 1
.org 0x0040
	jmp timer0_ovf_irq 	; Timer0 Overflow Handler

.include "include/atmega328p.s"
.include "include/macros.s"

.set timer_cycles_normal, 31250
.set timer_cycles_zadanie_1, 62500
.set timer_cycles_zadanie_2, 12500
.set timer_cycles_zadanie_3, 6250

.section .data
current_timer_dead_cycles:
    .space 2

.section .text

load_current_timer_dead_cycles_to_Z:
    load_register_X current_timer_dead_cycles
    ld r30, X+
    ld r31, X
    ret

; Interrupt handler
timer0_ovf_irq:
	sbiw Z, 1
	brne timer0_ovf_irq_exit
	call load_current_timer_dead_cycles_to_Z

    sts PORTB, r23    

	cpi r21, 0x01
	breq zadanie_1
	cpi r21, 0x02
	breq zadanie_2
	cpi r21, 0x03
	breq zadanie_3
	 
timer0_ovf_irq_exit:
	reti

; Interrupt handler
pcint1_irq:
    load_register_X current_timer_dead_cycles
	lds r17, PINC

pcint1_irq_option_1:

	sbrc r17, 1			;  Skip if Bit in Register is Cleared
	rjmp pcint1_irq_option_2

	ldi r16, lo8(timer_cycles_zadanie_1)
	st X+, r16
	ldi r16, hi8(timer_cycles_zadanie_1)
	st X, r16

	ldi r23, 0x20
	com r23
	sts PORTB, r23

	ldi r18, 0x04 	; Y
	ldi r19, 0x02 	; X
	ldi r21, 0x01 	; mode

	;call load_current_timer_dead_cycles_to_Z

	rjmp pcint1_irq_exit

pcint1_irq_option_2:
	sbrc r17, 2
	rjmp pcint1_irq_option_3

	ldi r16, lo8(timer_cycles_zadanie_2)
	st X+, r16
	ldi r16, hi8(timer_cycles_zadanie_2)
	st X, r16

    ldi r21, 0x02
	ldi r23, 0x9F
	sts PORTB, r23
	;call load_current_timer_dead_cycles_to_Z
	rjmp pcint1_irq_exit

pcint1_irq_option_3:

	sbrc r17, 3
	rjmp pcint1_irq_exit

	;ldi r16, lo8(timer_cycles_zadanie_3)
	;st X+, r16
	;ldi r16, hi8(timer_cycles_zadanie_3)
	;st X, r16

	ldi r23, 0x04
	com r23
	sts PORTB, r23
	
	ldi r21, 0x03 	; mode

	;call load_current_timer_dead_cycles_to_Z
	
	rjmp pcint1_irq_exit

pcint1_irq_exit:
	reti


zadanie_1:
	dec r19
	brne timer0_ovf_irq_exit
	ldi r19, 0x02 
	
	sec
	ror r23
	sts PORTB, r23

	ldi r21, 0x01
	
	dec r18
	brne timer0_ovf_irq_exit
	
	ldi r23, 0x20
	com r23
	ldi r18, 0x04

	reti

zadanie_2:
    com r23
    lsr r23
    com r23
    cpi r23, 0xFE
    breq reload
    
	reti

reload:
    ldi r23, 0x3F


zadanie_3:
	dec r23	
	reti

; Interrupt handler
start:
	load_register_16 SPH, SPL, _stack_top

	load_register_8 DDRB, 0x3C
	ldi r23, 0xFF
	;com r23
	sts PORTB, r23

	load_register_8 TCCR0B, 0x01
	load_register_8 TIMSK0, 0x01
	load_register_8 TCNT0, 0x00

	load_register_8 PCICR, 0x02 ; Pin Change Interrupt Enable 2 ; enabled PCINT[23:16] pin
	load_register_8 PCMSK1, 0x0E

    load_register_X current_timer_dead_cycles
	ldi r16, lo8(timer_cycles_normal)
	st X+, r16
	ldi r16, hi8(timer_cycles_normal)
	st X, r16    
	call load_current_timer_dead_cycles_to_Z

;	load_register_Z timer_cycles_per_second

	sei
sleep:
	sleep
	jmp sleep

