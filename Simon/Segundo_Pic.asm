list p=16f887
INCLUDE "p16f887.inc"
CBLOCK 0x20
AUX
AUX1
AUX2
PUNTAJE
FLAGS
MAYOR_PUNTAJE
UNIDADES
DECENAS
ENDC
DISP_0	EQU b'00111111'
DISP_1	EQU b'00000110'
DISP_2	EQU b'11011011'
DISP_3	EQU b'11001111'
DISP_4	EQU b'11100110'
DISP_5	EQU b'11101101'
DISP_6	EQU b'11111101'
DISP_7	EQU b'00000111'
DISP_8	EQU b'11111111'
DISP_9	EQU b'11101111'
DISP_UNIDADES EQU 0
org	0x00
goto	INICIO
org	0x04
goto	INTERRUPCION



INICIO
	call	CFG
	call	CONVERTIR
	bsf		INTCON,T0IE

MAIN
	nop	
	goto	MAIN

CFG
	movlw	.25
	movwf	PUNTAJE
	movlw	0x00
	movwf	MAYOR_PUNTAJE
	movwf	DECENAS
	movwf	UNIDADES

	banksel	OPTION_REG
	movlw	b'00000100'
	movwf	OPTION_REG
	movlw	b'00000000'
	movwf	TRISB
	movwf	TRISD
	
	banksel	ANSELH
	clrf	ANSELH
	
	banksel	INTCON
	movlw	b'10000000'
	movwf	INTCON
	
	movlw	.50
	movwf	TMR0
	movlw	0x00
	movwf	PORTD
	clrf	FLAGS
	
  return

INTERRUPCION
	btfsc	INTCON,T0IF
	goto	INT_TIMER
	


INT_TIMER
	btfss	FLAGS,DISP_UNIDADES
	goto	MOSTRAR_UNIDADES
	goto	MOSTRAR_DECENAS
	
	


CONVERTIR
	movf	PUNTAJE,0
	movwf	AUX
DECENAS_TAG
	movlw	.10
	subwf	AUX,1
	btfss	STATUS,C
	goto	UNIDADES_TAG
	movf	AUX,0
	movwf	AUX2
	incf	DECENAS,1
	goto	DECENAS_TAG

UNIDADES_TAG
	movf	AUX2,0
	movwf	UNIDADES
	return
	
	
PUNTAJE_MAYOR?
	movf	PUNTAJE,0
	movwf	AUX1
	movf	MAYOR_PUNTAJE,0
	subwf	AUX1,1
	btfss	STATUS,C
	return
	movf	PUNTAJE,0
	movwf	MAYOR_PUNTAJE
	return

MOSTRAR_UNIDADES
	clrf	PORTB
	bcf		PORTD,1
	bsf		PORTD,0
	movf	UNIDADES,0
	call	TABLA
	movwf	PORTB
	bsf		FLAGS,DISP_UNIDADES
	goto	FIN_TIMER

MOSTRAR_DECENAS
	clrf	PORTB
	bcf		PORTD,0
	bsf		PORTD,1
	movf	DECENAS,0
	call	TABLA
	bcf		FLAGS,DISP_UNIDADES
	movwf	PORTB
	
FIN_TIMER
	movlw	.50 ;valor de carga de timer
	movwf	TMR0
	bcf		INTCON,T0IF
	retfie
TABLA
	addwf	PCL,1
	retlw	DISP_0
	retlw	DISP_1
	retlw	DISP_2	
	retlw	DISP_3	
	retlw	DISP_4	
	retlw	DISP_5	
	retlw	DISP_6	
	retlw	DISP_7	
	retlw	DISP_8	
	retlw	DISP_9	
end