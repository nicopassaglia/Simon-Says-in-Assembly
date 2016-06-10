	list p=16f887
	INCLUDE "p16f887.inc"
	CBLOCK 0x20
CONTADOR_PRUEBA
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
	call	Configuracion_Puerto_Serie
	call	CONVERTIR
	bsf		INTCON,T0IE
	goto	MAIN

MAIN
	nop	
	clrwdt
	goto	MAIN
PRUEBA
	incf 	CONTADOR_PRUEBA
	movf 	CONTADOR_PRUEBA, 0
	movwf 	PUNTAJE
	call 	PUNTAJE_MAYOR?
	call 	CONVERTIR
	return

CFG
	clrf 	CONTADOR_PRUEBA
	clrf	PUNTAJE
	clrf	MAYOR_PUNTAJE
	clrf	DECENAS
	clrf	UNIDADES

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
	banksel	PIR1
	btfsc	PIR1, RCIF
	goto	INT_RX
	bcf 	STATUS, RP0
	bcf 	STATUS, RP1
	retfie

INT_TIMER
	btfss	FLAGS,DISP_UNIDADES
	goto	MOSTRAR_UNIDADES
	goto	MOSTRAR_DECENAS
	
	


CONVERTIR
	clrf 	UNIDADES
	clrf 	DECENAS
	movf	MAYOR_PUNTAJE,0
	movwf	AUX
	movwf 	AUX2
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
	movwf	AUX1			;Paso el valor de puntaje a AUX1
	movf	MAYOR_PUNTAJE,0	;Paso Mayor_Puntaje a W
	subwf	AUX1,1			;Hago AUX1-W (Puntaje-Mayor_Puntaje)
	btfss	STATUS,C		;Si B=0(C=1) entonces guardo a puntaje en Mayor_Puntaje
	return
	movf	PUNTAJE,0
	movwf	MAYOR_PUNTAJE	;Guardo a puntaje en puntaje mayor
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

;-------------------------
Configuracion_Puerto_Serie
;-------------------------
	banksel TRISC
	bcf TRISC, 6	;RC6/TX/CK = output
	bsf TRISC, 7	;RC7/RX/DT = input

	banksel BAUDCTL	
	bcf BAUDCTL, BRG16	;16-bit BAUD Rate Generator is used.
	
	banksel SPBRG
	movlw .51	;baud rate = 38400 --->	Esto seguro hay que modificarlo.
				;(Fosc/(4*(SPBRG+1))) Error + 0.16%
	movwf SPBRG
	clrf SPBRGH

	banksel TXSTA
	bcf TXSTA, TX9 	;Data is 8-bit wide
	bcf TXSTA, TXEN	;Data transmission disabled
	bcf TXSTA, SYNC	;Asynchronous mode
	bsf TXSTA, BRGH	;High-speed baud rate
	
	banksel RCSTA
	bsf RCSTA, SPEN	;RX/DT and TX/CK outputs configuration
	bcf RCSTA, RX9	;Select mode for 8-bit data receive
	bsf RCSTA, CREN	;Receive data enabled
	bcf RCSTA, ADDEN	;No address detection, ninth bit 
						;might be used as parity bit
	bcf RCSTA, FERR
	bcf RCSTA, OERR
	movf RCREG, 0	;cleared RCIF bit

	banksel BAUDCTL
	bcf BAUDCTL, SCKP ;unset inverted mode
;-----------------------
Interrupts_Configuration		;Para Comunicacion Serie
;-----------------------
	banksel PIE1
	bsf PIE1, RCIE	;USART Rx interrupt enabled
	
	banksel INTCON
	bsf INTCON, PEIE

	bcf STATUS, RP0
	bcf STATUS, RP1	

	return

INT_RX
	;bcf 	PIR1, RCIF
	;banksel PIE1
	;bcf 	PIE1, RCIE
	;call 	PRUEBA
	banksel	RCSTA
	btfsc	RCSTA, OERR
	goto	OVERRUN_ERROR
	btfsc	RCSTA, FERR
	goto	FRAMING_ERROR
	goto	RECIBIR_DATO
RECIBIR_DATO
	banksel RCREG
	movf 	RCREG, 0
	movwf 	PUNTAJE
	call	PUNTAJE_MAYOR?
	call	CONVERTIR
	goto	FIN_RX
OVERRUN_ERROR
	banksel RCREG
	movf 	RCREG, 0
	bcf 	RCSTA, OERR
	bsf 	PORTD, 7
	goto	FIN_RX	
FRAMING_ERROR
	banksel RCREG
	movf	RCREG, 0
	movwf 	PUNTAJE
	call 	PUNTAJE_MAYOR?
	call	CONVERTIR
	bcf		RCSTA, FERR
	bsf 	PORTD, 6
	goto	FIN_RX
FIN_RX
	bcf STATUS, RP0
	bcf STATUS, RP1
	retfie

	end