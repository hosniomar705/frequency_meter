Certainly! Here's the translated version of the comments in English:

```assembly
; Simplest frequency meter for ATtiny2313(A) up to 10 MHz.
; 20 MHz crystal
; Created by: DANYK
; http://danyk.cz

.NOLIST
.INCLUDE "tn2313def.inc"
.LIST

.DEF CIF1=R9       ; lowest digit
.DEF CIF2=R10      ; ...
.DEF CIF3=R11      ; ...
.DEF CIF4=R12      ; ...
.DEF CIF5=R13      ; ...
.DEF CIF6=R14      ; ...
.DEF CIF7=R15      ; highest digit

.DEF REG=R16        ; temporary register

.DEF UDAJ1=R17      ; lower 8 bits of the 24-bit result
.DEF UDAJ2=R18      ;
.DEF UDAJ3=R19      ; upper 8 bits of the 24-bit result

.DEF DELREG=R20     ; 2 registers for dividing frequency from 625 to 1 Hz
.DEF DELREG2=R21
.DEF PRETREG=R22    ; register where the 16-bit counter1 overflows
.DEF MULTREG=R23    ; register remembers the state of the multiplexer

.DEF ROZREG=R24     ; range

.EQU SMER=DDRB      ; PORT for the display - anode segments
.EQU PORT=PORTB
.EQU SMER2=DDRD     ; PORT for the multiplexer - cathode segments, input
.EQU PORT2=PORTD

.CSEG
.ORG 0
RJMP START

; Program jumps here when an interrupt occurs
.ORG OVF1addr
INC PRETREG
RETI

.ORG OC0Aaddr
RJMP CITAC0

START:
; Set port as output
LDI REG,0xFF
OUT SMER,REG
LDI REG,0xFF
OUT PORT,REG

; Set bits 0,1,2,3 as output and bits 4,5,6 as input
LDI REG,0b00001111
OUT SMER2,REG
LDI REG,0b11010000
OUT PORT2,REG

LDI REG,LOW(RAMEND)
OUT SPL,REG

; Disable analog comparator to save energy
LDI REG,0b10000000
OUT ACSR,REG

; Sleep mode: IDLE
LDI REG,0b00100000
OUT MCUCR,REG

; CONFIGURE COUNTER/TIMER
LDI REG,0b00000010  ; Set timer0 for clear-on-compare match...
OUT TCCR0A,REG      ; ...(CTC) mode, OC0 not used, prescaler 256
LDI REG,0b00000100  ;
OUT TCCR0B,REG
LDI REG,124          ; Compare value for generating 625Hz (multiplex 156.25Hz)
OUT OCR0A,REG

LDI REG,0b00000000  ; Set timer1 for normal mode
OUT TCCR1A,REG      ; 
LDI REG,0b00000111  ; External clock source
OUT TCCR1B,REG

LDI REG,0b10000001  ; Enable interrupts
OUT TIMSK,REG       ; (bit 0 enables timer0A, bit 7 enables overflow interrupt1)

; Initialize/reset registers
CLR REG
LDI DELREG,1
LDI DELREG2,1
CLR PRETREG
LDI MULTREG,1
CLR CIF1
CLR CIF2
CLR CIF3
CLR CIF4
CLR CIF5
CLR CIF6
CLR CIF7

SEI ; Enable global interrupts

; Main loop
SMYCKA:
SLEEP
RJMP SMYCKA

MULT:
LDI REG,0b11010000
OUT PORT2,REG

CPI MULTREG,1
BREQ MULT1
CPI MULTREG,2
BREQ MULT2
CPI MULTREG,3
BREQ MULT3
CPI MULTREG,4
BREQ MULT4

MULT1:
MOV REG,CIF1
RCALL DISPLAY
CPI ROZREG,3
BRNE DOT1NE
SUBI REG,128         ; Illuminate the dot
DOT1NE:
OUT PORT,REG
LDI REG,0b11010001  ; Set bit0 of the port to logic 1
OUT PORT2,REG
RET

MULT2:
MOV REG,CIF2
RCALL DISPLAY
CPI ROZREG,2
BRNE DOT2NE
SUBI REG,128         ; Illuminate the dot
DOT2NE:
OUT PORT,REG
LDI REG,0b11010010  ; Set bit1 of the port to logic 1
OUT PORT2,REG
RET

MULT3:
MOV REG,CIF3
RCALL DISPLAY
CPI ROZREG,1
BRNE DOT3NE
SUBI REG,128         ; Illuminate the dot
DOT3NE:
OUT PORT,REG
LDI REG,0b11010100  ; Set bit2 of the port to logic 1
OUT PORT2,REG
RET

MULT4:
MOV REG,CIF4
RCALL DISPLAY
CPI ROZREG,0
BRNE DOT4NE
SUBI REG,128         ; Illuminate the dot
DOT4NE:
OUT PORT,REG
LDI REG,0b11011000  ; Set bit3 of the port to logic 1
OUT PORT2,REG
RET

DISPLAY:

CPI REG,0
BREQ DISPLAY0
CPI REG,1
BREQ DISPLAY1
CPI REG,2
BREQ DISPLAY2
CPI REG,3
BREQ DISPLAY3
CPI REG,4
BREQ DISPLAY4
CPI REG,5
BREQ DISPLAY5
CPI REG,6
BREQ DISPLAY6
CPI REG,7
BREQ DISPLAY7
CPI REG,8
BREQ DISPLAY8
CPI REG,9
BREQ DISPLAY9

LDI REG,0b11110111
RET

DISPLAY0:
LDI REG,0b11000000
RET

DISPLAY1:
LDI REG,0b11111001
RET

DISPLAY2:
LDI REG,0b10100100
RET

DISPLAY3:
LDI REG,0b10110000
RET

DISPLAY4:
LDI REG,0b10011001
RET

DISPLAY5:
LDI REG,0b10010010
RET

DISPLAY6:
LDI REG,0b10000010
RET

DISPLAY7:
LDI REG,0b11111000
RET

DISPLAY8:
LDI REG,0b10000000
RET

DISPLAY9:
LDI REG,0b10010000
RET

UPDATE:

MOV UDAJ3,PRETREG
IN UDAJ1,TCNT1L
IN UDAJ2,TCNT1H
CLR PRETREG
OUT TCNT1H,PRETREG
OUT TCNT1L,PRETREG

CLR ROZREG
CLR CIF1


CLR CIF2
CLR CIF3
CLR CIF4
CLR CIF5
CLR CIF6
CLR CIF7

CPI UDAJ1,128       ; 24-bit condition less than 10,000,000
LDI REG,150
CPC UDAJ2,REG
LDI REG,152
CPC UDAJ3,REG
BRLO DO9999999
SER REG
MOV CIF7,REG
MOV CIF6,REG
MOV CIF5,REG
MOV CIF4,REG
MOV CIF3,REG
MOV CIF2,REG
MOV CIF1,REG
SER ROZREG
RJMP END_UPDATE
DO9999999:

AGAIN_7:
CPI UDAJ1,64        ; 24-bit condition less than 1,000,000
LDI REG,66
CPC UDAJ2,REG
LDI REG,15
CPC UDAJ3,REG
BRLO LESS_7
SUBI UDAJ1,64        ; Subtract 1,000,000 from the result
SBCI UDAJ2,66
SBCI UDAJ3,15
INC CIF7
RJMP AGAIN_7
LESS_7:

AGAIN_6:
CPI UDAJ1,160       ; 24-bit condition less than 100,000
LDI REG,134
CPC UDAJ2,REG
LDI REG,1
CPC UDAJ3,REG
BRLO LESS_6
SUBI UDAJ1,160       ; Subtract 100,000 from the result
SBCI UDAJ2,134
SBCI UDAJ3,1
INC CIF6
RJMP AGAIN_6
LESS_6:

AGAIN_5:
CPI UDAJ1,16        ; 24-bit condition less than 10,000
LDI REG,39
CPC UDAJ2,REG
LDI REG,0
CPC UDAJ3,REG
BRLO LESS_5
SUBI UDAJ1,16        ; Subtract 10,000 from the result
SBCI UDAJ2,39
SBCI UDAJ3,0
INC CIF5
RJMP AGAIN_5
LESS_5:

AGAIN_4:
CPI UDAJ1,232       ; 16-bit condition less than 1,000
LDI REG,3
CPC UDAJ2,REG
BRLO LESS_4
SUBI UDAJ1,232       ; Subtract 1,000 from the result
SBCI UDAJ2,3
INC CIF4
RJMP AGAIN_4
LESS_4:

AGAIN_3:
CPI UDAJ1,100       ; 16-bit condition less than 100
LDI REG,0
CPC UDAJ2,REG
BRLO LESS_3
SUBI UDAJ1,100       ; Subtract 100 from the result
SBCI UDAJ2,0
INC CIF3
RJMP AGAIN_3
LESS_3:

AGAIN_2:
CPI UDAJ1,10        ; 8-bit condition less than 10
BRLO LESS_2
SUBI UDAJ1,10        ; Subtract 10 from the result
INC CIF2
RJMP AGAIN_2
LESS_2:

MOV CIF1,UDAJ1

SHIFT_AGAIN:
CLR REG
CP CIF7,REG
BRNE SHIFT
CP CIF6,REG
BRNE SHIFT
CP CIF5,REG
BRNE SHIFT
RJMP END_SHIFT
SHIFT:
MOV CIF1,CIF2
MOV CIF2,CIF3
MOV CIF3,CIF4
MOV CIF4,CIF5
MOV CIF5,CIF6
MOV CIF6,CIF7
CLR CIF7
INC ROZREG
RJMP SHIFT_AGAIN
END_SHIFT:

END_UPDATE:

; Interrupt for controlling multiplex and 1Hz source
CITAC0:
RCALL MULT
DEC MULTREG
BRNE MULT_LOOP
LDI MULTREG,4
MULT_LOOP:

DEC DELREG
BRNE DELAY_LOOP
LDI DELREG,125
DEC DELREG2
BRNE DELAY_LOOP
LDI DELREG2,5
RCALL UPDATE
DELAY_LOOP:

RETI
```