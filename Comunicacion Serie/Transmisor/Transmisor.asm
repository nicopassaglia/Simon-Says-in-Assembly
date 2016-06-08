	list p = 16f887
	include "p16f887.inc"
	
	cblock 0x21
PUNTERO_FSR
w_temp
status_temp
contador
	endc

	org 0x00
	goto INICIO
	org 0x05
	goto INT
	
INICIO
	call CFG_EXTRA
	call Configuracion_Puerto_Serie
	call Interrupts_Configuration
	goto Main

;---------
CFG_EXTRA
;---------
	banksel TRISD
	clrf TRISD
	clrf TRISB
	bsf TRISB, 0
	
	banksel ANSELH
	clrf ANSELH
	
	banksel INTCON
	bsf INTCON, GIE
	bsf INTCON, INTE
	
	clrf contador
	return
;FIN CONFIG_EXTRA

;-------------------------
Configuracion_Puerto_Serie
;-------------------------
	banksel TRISC
	bcf TRISC, 6	;RC6/TX/CK = output
	bsf TRISC, 7	;RC7/RX/DT = input

	banksel BAUDCTL	
	bsf BAUDCTL, BRG16	;16-bit BAUD Rate Generator is used.
	
	banksel SPBRG
	movlw .51	;baud rate = 38400 --->	Esto seguro hay que modificarlo.
				;(Fosc/(4*(SPBRG+1))) Error + 0.16%
	movwf SPBRG
	clrf SPBRGH

	banksel TXSTA
	bcf TXSTA, TX9 	;Data is 8-bit wide
	bsf TXSTA, TXEN	;Data transmission enabled	No se para que...
	bcf TXSTA, SYNC	;Asynchronous mode
	bsf TXSTA, BRGH	;High-speed baud rate
	
	banksel RCSTA
	bsf RCSTA, SPEN	;RX/DT and TX/CK outputs configuration
	bcf RCSTA, RX9	;Select mode for 8-bit data receive
	bsf RCSTA, CREN	;Receive data enabled
	bcf RCSTA, ADDEN	;No address detection, ninth bit 
						;might be used as parity bit
	movf RCREG, 0	;cleared RCIF bit

	banksel BAUDCTL
	bcf BAUDCTL, SCKP ;unset inverted mode
	
	return
;-----------------------
Interrupts_Configuration
;-----------------------
	banksel PIE1
	bsf PIE1, RCIE	;USART Rx interrupt enabled
	
	banksel INTCON
	bsf INTCON, PEIE
	bsf INTCON, GIE
	
	return
;--------------
;Rutina de Interrupcion
;--------------
INT
	movwf w_temp
	bcf STATUS, RP0
	bcf STATUS, RP1
	swapf STATUS, 0
	movwf status_temp

	banksel PIE1
	btfss PIE1, RCIE
	goto NOT_RX232_INT
	banksel PIR1
	btfsc PIR1, RCIF	;Test for USART receive interrupt
	goto INTERRUPCION_RX232
NOT_RX232_INT
	banksel INTCON
	btfss INTCON, INTE
	goto NOT_INTE
	btfsc INTCON, INTF
	goto INTERRUPCION_RB0
NOT_INTE
	nop
	;Otras interrupciones...
	;bla bla bla
	goto FINISH_INT

INTERRUPCION_RB0
	bcf INTCON, INTF
	movf contador, 0
	movwf TXREG ;Envia datos al otro pic
	incf contador, 1
	movf contador, 0
	xorlw 0x04
	btfsc STATUS, Z
	clrf contador
	nop
	movlw 0x01
	xorwf PORTD, 1
	goto FINISH_INT

INTERRUPCION_RX232
	banksel RCSTA
	btfsc RCSTA, FERR
	goto FRAMING_ERROR
	btfsc RCSTA, OERR
	goto OVERRUN_ERROR
	goto RECIBIR_DATO

RECIBIR_DATO
	movf RCREG, 0
	andlw b'00000011'
	movwf PUNTERO_FSR
	incf FSR, 1
	goto EXTRA

FRAMING_ERROR
	bcf RCSTA, FERR		;Limpio el bit de Framing Error
	movf RCREG, 0		;Mueve el byte recibido y limpia
	andlw b'00000011'
	movwf PUNTERO_FSR
	incf FSR, 1
	;MOSTRAR QUE HUBO UN ERROR, O USAR BACKUP
	bsf PORTD, 6
	goto EXTRA

OVERRUN_ERROR
	bcf RCSTA, OERR	;Limpio el bit de Overrun Error
	movf RCREG, 0
	andlw b'00000011'
	movwf PUNTERO_FSR
	incf FSR, 1
	;MOSTRAR QUE HUBO UN ERROR, O USAR BACKUP
	bsf PORTD, 5
	goto EXTRA


FINISH_INT
	;Recupero w y status
	swapf status_temp, 0
	movwf STATUS
	swapf w_temp, 1
	swapf w_temp, 0
	retfie

EXTRA
	movf PUNTERO_FSR, 0
	call TABLA
	movwf PORTD
	goto FINISH_INT
TABLA
	addwf PCL, 1
	retlw b'00000001' 
	retlw b'00000010'
	retlw b'00000100'
	retlw b'00001000'
	

;----------
Main
;----------
;Hacer algo para ver si funciona...
	goto $ ;Se queda aca para siempre...

	end