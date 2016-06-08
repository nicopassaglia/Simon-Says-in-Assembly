	list p = 16f887
	include "p16f887.inc"
	
	cblock 0x21
PUNTERO_FSR
w_temp
status_temp
	endc

	org 0x00
	goto INICIO
	org 0x05
	goto INT
	
INICIO
	call Configuracion_Puerto_Serie
	call Interrupts_Configuration
	goto Main

;-------------------------
Configuracion_Puerto_Serie
;-------------------------
	banksel TRISC
	;---------
	;CFG_EXTRA
	;---------
	clrf TRISD
	;FIN CONFIG_EXTRA
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
	bsf BAUDCTL, SCKP ;set inverted mode
	
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
	;Otras interrupciones...
	;bla bla bla
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
	goto FINISH_INT

FRAMING_ERROR
	bcf RCSTA, FERR		;Limpio el bit de Framing Error
	movf RCREG, 0		;Mueve el byte recibido y limpia
	andlw b'00000011'
	movwf PUNTERO_FSR
	incf FSR, 1
	;MOSTRAR QUE HUBO UN ERROR, O USAR BACKUP
	bsf PORTD, 6
	goto FINISH_INT

OVERRUN_ERROR
	bcf RCSTA, OERR	;Limpio el bit de Overrun Error
	movf RCREG, 0
	andlw b'00000011'
	movwf PUNTERO_FSR
	incf FSR, 1
	;MOSTRAR QUE HUBO UN ERROR, O USAR BACKUP
	bsf PORTD, 5
	goto FINISH_INT


FINISH_INT
	;Recupero w y status
	call EXTRA
	swapf status_temp, 0
	movwf STATUS
	swapf w_temp, 1
	swapf w_temp, 0
	retfie

EXTRA
	movf PUNTERO_FSR, 0
	call TABLA
	movwf PORTD
	return
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