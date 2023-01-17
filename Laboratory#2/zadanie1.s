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

.set timer_cycles_per_half_second, 31250

.section .data
screen_data:
	.space 2

screen_bit:
	.space 1

shift_clk:
	.space 1

stopwatch_value:
	.space 2

stopwatch_seconds:
	.space 1
next_display:
	.space 1

.section .text

;; Interrupt handlers

; Timer0 Overflow Interrupt handler
timer0_ovf_irq:
	call stopwatch_refresh
	call segments_refresh
	reti

; Reset Interrupt handler
start:
	load_register_16 SPH, SPL, _stack_top

	lds r16, DDRB
	sbr r16, 0x21								; set bits register (r16 ori 0x21) to r16, ??1? ???1, SDI PORT_B0
	sts DDRB, r16

	lds r16, DDRD
	sbr r16, 0x90								; set bits register (r16 ori 0x90) to r16, 1??1 ????, shift_clk 7, latch_clk 4
	sts DDRD, r16

	load_register_8 TCCR0B, 0x01
	load_register_8 TIMSK0, 0x01
	load_register_8 TCNT0, 0x00

	load_register_Z shift_clk
	ldi r16, 0xFF
	st Z, r16

	load_register_X next_display
	ldi r16, 0x08
	st X, r16

	ldi r16, 0x08								; load 0x08 to r16
	ldi r17, 0xA4								; load 0xC0 to r17
	call segments_update

	load_register_Z stopwatch_seconds			; counter which count number of digit changes
	ldi r16, 0									; stopwatch_seconds start`s counting from 0
	st Z, r16

	call stopwatch_reset

	sei
sleep:
	sleep
	jmp sleep

;; Functions

; Refresh (send next bit) to the mc74hc device
; Parameters: None
; Returns: None
; Clobbers: r16, r17, r18, Z
segments_refresh:
	; Check screen_bit if -1, skip, because all bits has been sent
	load_register_Z screen_bit
	ld r16, Z
	tst r16
	brmi segments_refresh_zero_latch_clk

	; Check screen_bit if 0, skip, but rise latch_clk
	dec r16
	st Z, r16
	brmi segments_refresh_one_latch_clk

	; Toggle shift clk
	load_register_Z shift_clk
	ld r16, Z
	com r16
	st Z, r16
	lds r17, PORTD
	andi r17, 0x7F
	andi r16, 0x80
	or r17, r16
	sts PORTD, r17

	; Update sdi only on falling edge
	tst r16
	brne segments_refresh_end

	; Rotate screen data, oldest bit in r18
	load_register_Z screen_data
	ld r16, Z+
	ld r17, Z+
	clr r18
	clc
	rol r16
	rol r17
	rol r18
	st -Z, r17
	st -Z, r16

	; Put correct data on sdi
	lds r16, PORTB
	sbrc r18, 0
	sbr r16, 0x01
	sbrs r18, 0
	cbr r16, 0x01
	sts PORTB, r16

	jmp segments_refresh_end

segments_refresh_one_latch_clk:
	lds r16, PORTD
	sbr r16, 0x10
	sts PORTD, r16
	jmp segments_refresh_end
segments_refresh_zero_latch_clk:
	lds r16, PORTD
	cbr r16, 0x10
	sts PORTD, r16
segments_refresh_end:
	ret

; Update value on segment digit
; Parameters:
; 	r16 - segment selection
;	r17 - segments pattern
; Returns: None
; Clobbers: r16, Z
segments_update:
	load_register_Z screen_data
	st Z+, r16
	st Z+, r17
	load_register_Z screen_bit
	ldi r16, 33
	st Z, r16

	ret

; Refresh stop watch, triggers every 1 second
; Parameters: None
; Returns: None
; Clobbers: r16, Z
stopwatch_reset:
	load_register_Z stopwatch_value
	ldi r16, lo8(timer_cycles_per_half_second)
	st Z+, r16
	ldi r16, hi8(timer_cycles_per_half_second)
	st Z, r16

; Refresh stop watch, triggers every 1 second
; Parameters: None
; Returns: None
; Clobbers: r26, r27, Z
stopwatch_refresh:
	load_register_Z stopwatch_value
	ld r26, Z+
	ld r27, Z+
	sbiw r26, 1
	st -Z, r27
	st -Z, r26
	brne stopwatch_refresh_exit
	call stopwatch_reset
	call stopwatch_next
stopwatch_refresh_exit:
	ret


; Refresh stop watch, triggers every 1 second
; Parameters: None
; Returns: None
; Clobbers: r16, r17, Z
stopwatch_next:
	; Toggle led
	lds r16, PORTB
	ldi r17, 0x20
	eor r16, r17								; xor between r16 and r17
	sts PORTB, r16

	; If led is zero, wait next 500ms
	sbrc r16, 5
	jmp stopwatch_next_end

	; Increment current seconds count (wrap at 4)
	load_register_Z stopwatch_seconds
	ld r16, Z
	inc r16
	cpi r16, 4  								; check if counter achieved 4 changes of state
	brne stopwatch_next_less_than_four			; if not
	ldi r16, 0									; if yes
stopwatch_next_less_than_four:
	st Z, r16

	; Load digit pattern (from program memory)
	;load_register_Z patterns
	;add r30, r16								; add without carry r16 to r30
	;ldi r16, 0x00								; load 0x00 to r16
	;adc r31, r16
	
	;load_register_Z 								; add with carry r16 to r31
	;lpm r17, Z									; load byte from reg_Z to r17
								
	; Update displayed digit (pattern already in r17)
	load_register_X next_display
	ld r16, X
	;ldi r16, 0x08
	lsr r16
	cpi r16, 0
	brne update
	ldi r16, 0x08
update:
	st X, r16
	ldi r17, 0xA4
	call segments_update
stopwatch_next_end:
	ret
