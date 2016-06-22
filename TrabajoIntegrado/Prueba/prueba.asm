list p = 16f887
include "p16f887.inc"

__CONFIG    _CONFIG1, _LVP_OFF & _FCMEN_ON & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_OFF & _WDT_OFF & _XT_OSC
    __CONFIG    _CONFIG2, _WRT_OFF & _BOR21V
;__CONFIG _XT_OSC & _PWRTE_OFF & _BOREN_OFF & _CP_OFF & _WDT_OFF & _DP_OFF & _CPC_OFF

cblock 0x30
DELAY1
DELAY2
endc

org 	0x00
goto 	INICIO
org 	0x04
goto 	INT

INT
	ANTIREBOTE_INT
	call 	delay_100ms
PROBANDO_RB0
	btfsc 	PORTB, 0 	;Testeo el bit RB0, si se dejo de pulsar el boton bajara a cero
	goto 	PROBANDO_RB0
	call 	delay_100ms	;Una vez que se dejo de presionar el boton, hago un delay de 10 ms para que pase el rebote.
	banksel INTCON
	movlw 	b'00000010'
	xorwf 	PORTA, 1
	bcf 	INTCON, INTF
	retfie

INICIO
	;banksel OSCCON
	;movlw 	b'10101100'
	;movwf	OSCCON
	
	banksel TRISA
	bsf 	TRISB, 0
	bcf 	TRISA, 1
	
	banksel ANSEL
	clrf 	ANSEL
	clrf	ANSELH
	
	banksel OPTION_REG
	movlw 	b'11000000'
	movwf 	OPTION_REG

	banksel INTCON
	bsf		INTCON, GIE
	bsf		INTCON, INTE

	bcf 	PORTA, 1
	nop
	nop
HOLA
	nop
	clrwdt
	goto HOLA
delay_100ms	
;{
	movlw 	.200
	movwf 	DELAY2
BUCLE2_100
	movlw 	.124
	movwf 	DELAY1
BUCLE1_100
	clrwdt
	decfsz 	DELAY1, 1
	goto 	BUCLE1_100
	decfsz 	DELAY2, 1
	goto 	BUCLE2_100
	return		;La formula del delay es R=[(4X)+4]Y+1 donde X=124 e Y=20.
;}

end