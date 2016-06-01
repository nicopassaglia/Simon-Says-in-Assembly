	list p=16f887
	INCLUDE "p16F887.inc"
	CBLOCK 0x21
	Cont_Sec
	Cont_Sec1
	Numero_de_valores_de_secuencia
	Contador
	Contador_Aux
	FLAGS
	Valor_aux
	Primer_valor 
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

Espero
	nop
	btfsc	FLAGS,Proximo	;Si pulso el/los color/es correcto/s, muestro la siguiente secuencia
	call	SIGUIENTE_COLOR
	btfsc 	FLAGS,Perdio	;Si le erro, perdio
	goto	PERDIO_JUEGO
	btfsc	FLAGS,Gano		;Si gano, gano 
	goto	GANO_JUEGO
	goto	Espero
	



PERDIO_JUEGO
	;hacemos algo para mostrar que perdio
	
GANO_JUEGO
	;hacemos algo para mostrar que gano

	


CFG
	;Habilito los enables de las interrupciones
	banksel INTCON
	movlw	b'10011000'
	movwf 	INTCON
	bcf INTCON, INTE

	
	
	;Configuro timer0 para que sea temporizador interno
	banksel OPTION_REG
	movlw 	b'00000111' ;Falta configurar PRESCALER
		


	;Configuro el puertoB como digital
	banksel ANSELH
	clrf 	ANSELH

	;Configurar carga al timer
	banksel TMR0
	movlw 	b'00000000' 
	movwf 	TMR0

	movlw	.1
	movwf	Contador_Aux
	movwf	Contador
	
	;Configuro puertoB como de entrada
	banksel TRISB
	movlw 	b'11111111'
	movwf 	TRISB
	
	;Configuro PuertoA como de salida
	movlw 	b'00000000'
	movwf 	TRISC
	
	bcf STATUS, RP0
	bcf STATUS, RP1

	return

INTERRUPCION
	btfsc 	INTCON,T0IF	;CHEQUEO DE DONDE VIENEN LAS INTERRUPCIONES
	goto	INT_TIMER
	btfsc	INTCON,RBIF
	goto	INT_PUERTOB
	;ALGO
	


INT_PUERTOB
	bcf		INTCON,RBIF	;bajo bandera de interrupcion
	movlw	0xF0
	andwf	PORTB,0
	movwf	Valor_aux
	movf	INDF,0	
	call	TABLA	
	xorwf	Valor_aux, 0	;tengo que ver si el valor que pulso es el que deberia pulsar
	btfsc	STATUS,Z
	goto	Levanto_flag_perdio
	goto	SIG
	


SIG
	decfsz	Contador, 1
	goto	No_Llego_Cero
	goto	Llego_Cero


No_Llego_Cero
	incf 	FSR,1	
	retfie

Llego_Cero
	movf	Primer_valor,0
	movwf	FSR	
	movf	Numero_de_valores_de_secuencia,0
	xorwf	Contador_Aux, 0
	btfsc	STATUS,Z
	goto	Levanto_bandera_gano
	incf	Contador_Aux, 1
	movlw	Contador_Aux
	movwf	Contador
	bsf		FLAGS,Proximo
	retfie



Levanto_bandera_gano
	bsf		FLAGS,Gano
	retfie
	
	
Levanto_flag_perdio

	bsf 	FLAGS,Perdio	;LEVANTO EL FLAG YA QUE PERDIO
	retfie


INT_TIMER
	bcf		INTCON,T0IF
	incf	FSR,1
	decfsz	Contador,1
	goto	MUESTRO_COLOR
	goto	FIN_INT_TIMER


MUESTRO_COLOR
	movf	INDF,0
	call	TABLA
	movwf	PORTC
	;Falta reiniciar TIMER
	retfie

	
FIN_INT_TIMER
	bsf		FLAGS,Proximo
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
	movlw	.4
	movwf	Cont_Sec
	decfsz	Cont_Sec1, 1
	goto	Bucle	
	return
	
	
			 	
	
	
Mostrar_Secuencia
	bcf 	INTCON, INTE
	bcf 	INTCON, RBIE ;En este momento no se puede interrumpir el programa
	movf 	Primer_valor,0
	movwf 	FSR
	bsf 	INTCON, T0IE
	movf 	INDF,0
	call 	TABLA
	movwf 	PORTC
ESPERO_TIMER
	nop
	btfss 	FLAGS, Proximo
	goto 	ESPERO_TIMER	
	bcf 	FLAGS, Proximo
	bsf 	INTCON, INTE
	bsf 	INTCON, RBIE
	return

SIGUIENTE_COLOR
	incf 	Contador_Aux,1
	movf 	Contador_Aux, 0
	movwf 	Contador
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