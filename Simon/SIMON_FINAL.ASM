	list p=16f887
	INCLUDE "p16F887.inc"
	CBLOCK 0x21
	Cont_Sec
	Cont_Sec1
	Numero_de_valores_de_secuencia
	Contador
	Contador_Aux
	DELAY1
	DELAY2
	VARIABLE_TEMPORAL
	bucle1
	bucle2
	valor
	FLAGS
	Valor_aux
	Primer_valor 
	segundo_valor
	endc
Perdio	EQU 0
Proximo EQU 1
Gano	EQU 2
	org	0x00
	goto 	INICIO
	org	0x04
	goto	INTERRUPCION
	;SOMOS GRUPO 18
INICIO

	call	CFG



MAIN
	call	Generar_Secuencia
	call	Mostrar_Secuencia
	movlw .3
	movwf segundo_valor
	goto Espero

Espero
	clrf	TMR0
	CLRWDT
	btfsc	FLAGS,Proximo	;Si pulso el/los color/es correcto/s, muestro la siguiente secuencia
	call	SIGUIENTE_COLOR
	btfsc 	FLAGS,Perdio	;Si le erro, perdio
	goto	PERDIO_JUEGO
	btfsc	FLAGS,Gano		;Si gano, gano 
	goto	GANO_JUEGO
	goto	Espero
	



PERDIO_JUEGO
	;hacemos algo para mostrar que perdio
	
	bsf 	PORTC,0
	goto 	PERDIO_JUEGO
	
GANO_JUEGO
	;hacemos algo para mostrar que gano
	bsf		PORTC,1
	goto	GANO_JUEGO

	


CFG
						;Habilito los enables de las interrupciones
	banksel INTCON
	movlw	b'10011000'
	movwf 	INTCON
	
	banksel	IOCB
	movlw	b'11111110'
	movwf	IOCB
	


	banksel	WPUB
	movlw	b'11111111'
	movwf	WPUB

	;Configuro timer0 para que sea temporizador interno
	banksel OPTION_REG
	movlw 	b'11000111'
	movwf	OPTION_REG ;Falta configurar PRESCALER
		


	;Configuro el puertoB como digital
	banksel ANSELH
	clrf 	ANSELH


	;Configurar carga al timer
	banksel TMR0
	movlw 	.0
	movwf 	TMR0

	movlw	.1
	movwf	Contador_Aux
	movwf	Contador
	
	;Configuro puertoB como de entrada
	banksel TRISB
	movlw 	b'11111111'
	movwf 	TRISB
	
	;Configuro PuertoC como de salida
	movlw 	b'00000000'
	movwf 	TRISC
	
	movlw 	b'00000000'
	movwf 	TRISD
	bcf		TRISA,1
	
	
	bcf 	STATUS, RP0
	bcf 	STATUS, RP1
	clrf	PORTC
	clrf	PORTB
	clrf	PORTD
	bcf		PORTA,1
	movlw	.140
	movwf	bucle1
	movwf	bucle2
	movlw	0x01
	movwf	valor
	clrf	FLAGS
	
	return

INTERRUPCION
	btfsc	INTCON,RBIF;CHEQUEO DE DONDE VIENEN LAS INTERRUPCIONES
	goto	INT_PUERTOB
	btfsc 	INTCON,INTF
	goto	INT_PUERTOB
	btfsc 	INTCON,T0IF	
	goto	INT_TIMER


INT_PUERTOB
		;bajo bandera de interrupcion
		

ANTIREBOTE_RB

	call 	delay_10ms
	call	delay_10ms ;Espero 10ms a que pase el rebote
	movf 	PORTB, 0 	;muevo el puerto B a w
	andlw 	0xF0	;Hago and con los bits que me importan y los guardo
	movwf 	Valor_aux ;Esta es la variable que utilizo en la rutina para comparar

PROBANDO_RB
	movf 	PORTB,0	;Muevo al puerto B a W
	andlw 	0xF0	;Hago AND a los bits que me interesan
	btfss 	STATUS, Z	;Si todos los bits estan en cero significa que se dejo de pulsar
	goto 	PROBANDO_RB	;Sino, sigo probando hasta que se deje de pulsar el boton
	call 	delay_10ms
	call	delay_10ms	;Hago un delay por el rebote de soltar el pulsador

	
	movf	INDF,0	
	call	TABLA	
	xorwf	Valor_aux, 0	;tengo que ver si el valor que pulso es el que deberia pulsar
	btfss	STATUS,Z
	goto	Levanto_flag_perdio
	goto	SIG



delay_10ms	;Retardo por software de 10ms
	movlw 	.20
	movwf 	DELAY2
BUCLE2
	movlw 	.124
	movwf 	DELAY1
BUCLE1
	nop
	decfsz 	DELAY1, 1
	goto 	BUCLE1
	decfsz 	DELAY2, 1
	goto 	BUCLE2
	return		;La formula del delay es R=[(4X)+4]Y+1 donde X=124 e Y=20.

SIG
	decfsz	Contador, 1
	goto	No_Llego_Cero
	goto	Llego_Cero


No_Llego_Cero
	incf 	FSR,1	
	bcf		INTCON,RBIF
	bcf		INTCON,INTF
	retfie

Llego_Cero
	movlw	Primer_valor
	movwf	FSR	
	movf	Numero_de_valores_de_secuencia,0
	xorwf	Contador_Aux, 0
	btfsc	STATUS,Z
	goto	Levanto_bandera_gano
	;incf	Contador_Aux, 1
	;movf	Contador_Aux,0
	;movwf	Contador
	bsf		FLAGS,Proximo
	bcf		INTCON,RBIF
	bcf		INTCON,INTF
	retfie



Levanto_bandera_gano
	bsf		FLAGS,Gano
	bcf		INTCON,RBIF
	bcf		INTCON,INTF
	retfie
	
	
Levanto_flag_perdio

	bsf 	FLAGS,Perdio ;LEVANTO EL FLAG YA QUE PERDIO
	bcf		INTCON,RBIF
	bcf		INTCON,INTF	
	retfie


INT_TIMER
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	incf	FSR,1
	decfsz	Contador,1
	goto	MUESTRO_COLOR
	goto	FIN_INT_TIMER


MUESTRO_COLOR
	clrf	PORTC
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	movf	INDF,0
	call	TABLA
	movwf	PORTC
	movlw	.0
	movwf	TMR0
	bcf		INTCON,T0IF
	retfie

	
FIN_INT_TIMER
	movlw	.0
	movwf	TMR0
	movf	Contador_Aux,0
	movwf	Contador
	bsf		FLAGS,Proximo
	movlw	Primer_valor
	movwf	FSR
	bcf		INTCON,T0IF
	bcf		INTCON,T0IE
	retfie
	

Generar_Secuencia
	movlw	.8
	movwf	Numero_de_valores_de_secuencia

	movlw	.4
	movwf	Cont_Sec
	
	movlw	.2
	movwf	Cont_Sec1


	movlw 	Primer_valor
	movwf	FSR
	clrf	Valor_aux
Bucle
	movf	Valor_aux,0
	movwf	INDF
	incf	Valor_aux,1
	incf	FSR, 1
	decfsz	Cont_Sec, 1
	goto	Bucle
	goto	Bajo_Cont
Bajo_Cont
	movlw	0
	movwf	Valor_aux
	movlw	.4
	movwf	Cont_Sec
	decfsz	Cont_Sec1, 1
	goto	Bucle	
	return
	
	
			 	
	
	
Mostrar_Secuencia
	
	;En este momento no se puede interrumpir el programa
	bcf		INTCON,RBIE
	bcf		INTCON,INTE
	movlw 	Primer_valor
	movwf 	FSR
	movlw	.0
	movwf	TMR0
	bsf 	INTCON, T0IE
	movf 	INDF,0
	call 	TABLA
	movwf 	PORTC

ESPERO_TIMER
	nop
	btfss 	FLAGS, Proximo
	goto 	ESPERO_TIMER	
	clrf	PORTC
	bcf 	FLAGS, Proximo
	bsf 	INTCON, INTE
	bsf 	INTCON, RBIE
	return

SIGUIENTE_COLOR
	incf 	Contador_Aux,1
	movf	Contador_Aux,0
	movwf	Contador
	bcf 	FLAGS,Proximo
	call 	Mostrar_Secuencia
	return


TABLA
	addwf 	PCL,1
	retlw	b'10000000'
	retlw	b'01000000'
	retlw	b'00100000'
	retlw	b'00010000'
		
	end