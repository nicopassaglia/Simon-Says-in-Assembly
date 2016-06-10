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
	Random
	Puntero
	FLAGS
	Valor_aux
	Primer_valor 
	endc
Perdio	EQU 0
Proximo EQU 1
Gano	EQU 2
Crear	EQU	3
Comenzo EQU 4
MAX_VAL	EQU .8
	org	0x00
	goto 	INICIO
	org	0x04
	goto	INTERRUPCION
	;SOMOS GRUPO 18
INICIO

	call	CFG
	movlw 	MAX_VAL
	movwf 	Numero_de_valores_de_secuencia
MAIN
	;call	Generar_Secuencia	
	incf	Random, 1
	btfss 	FLAGS, Comenzo	;Cuando viene interrupcion por RB0 setea el FLAG
	goto 	MAIN
	movf 	Random, 0
	andlw 	b'00000011'
	movwf 	Primer_valor
	call	Mostrar_Secuencia
	bsf 	INTCON, RBIE
	bsf 	FLAGS, Crear
	
;----BLOQUE QUE ESPERA UNA PULSACION-----
Espero
;{	
	incf	Random,1
	clrf	TMR0
	CLRWDT
	btfsc	FLAGS,Proximo	;Si pulso el/los color/es correcto/s, muestro la siguiente secuencia
	call	SIGUIENTE_COLOR
	btfsc 	FLAGS,Perdio	;Si le erro, perdio
	goto	PERDIO_JUEGO
	btfsc	FLAGS,Gano		;Si gano, gano 
	goto	GANO_JUEGO
	goto	Espero;}

;----FIN BLOQUE ESPERO-----
	

SIGUIENTE_COLOR
;{
	incf 	Contador_Aux,1
	movf	Contador_Aux,0
	movwf	Contador
	bcf 	FLAGS,Proximo
	call 	Mostrar_Secuencia
	return;}



PERDIO_JUEGO
	;{
	;PRENDO LED QUE MUESTRA QUE PERDIO
	bsf 	PORTD,0
	goto 	PERDIO_JUEGO;}


GANO_JUEGO
;{
	;PRENDO LED QUE MUESTRA QUE GANO
	bsf		PORTD,1
	goto	GANO_JUEGO;}


;MUESTRO LA SECUENCIA DE LEDS

	;----MOSTRAR SECUENCIA DE COLORES----
Mostrar_Secuencia
;{
	movf	Contador_Aux,0
	movwf	Contador
	incf 	Contador, 1
	bcf		INTCON,RBIE ;En este momento no se puede interrumpir el programa
	bcf		INTCON,INTE
	movlw 	Primer_valor
	movwf 	FSR
	movlw	.0
	movwf	TMR0
	bsf 	INTCON, T0IE
	movf 	INDF,0
	call 	TABLA
	movwf 	PORTD
	decf	FSR,1
	

ESPERO_TIMER ;EL BLOQUE ESPERO_TIMER HACE UN RETARDO PARA QUE EL COLOR SEA VISIBLE AL OJO
	nop
	btfss 	FLAGS, Proximo 
	goto 	ESPERO_TIMER	
	clrf	PORTD
	bcf 	FLAGS, Proximo
	bsf 	INTCON, INTE ;YA PUEDO TOMAR INTERRUPCIONES POR PUERTO B
	bsf 	INTCON, RBIE
	return
;}
	;----FIN MOSTRAR SECUENCIA DE COLORES-----


	

;--------CONFIGURACION-------

CFG
;{	
	;Habilito los enables de las interrupciones
	banksel INTCON
	movlw	b'10010000'
	movwf 	INTCON

	banksel	IOCB
	movlw	b'11111110'
	movwf	IOCB

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
	movwf 	TRISD
	
	movlw 	b'00000000'
	movwf 	TRISD
	bcf		TRISA,1	
	
	;vuelvo al banco 0
	bcf 	STATUS, RP0
	bcf 	STATUS, RP1
	;Limpio los puertos y el registro de banderas
	clrf	PORTD
	clrf	PORTB
	clrf	PORTD
	clrf	FLAGS
	movlw	Primer_valor
	movwf	Puntero
	incf	Puntero,1
	return
	;}
;--------FIN CONFIGURACION-----------


;-----INTERRUPCIONES---------
;RUTINA DE INTERRUPCION
INTERRUPCION
	;---VERIFICACION DE DONDE VINO LA INTERRUPCION---
;{
	btfsc 	INTCON,INTF
	goto	INT_PUERTOB
	btfsc	INTCON,RBIF
	goto	INT_PUERTOB1
	btfsc 	INTCON,T0IF	
	goto	INT_TIMER
;}
	;---FIN VERIFICACION---

;-----INTERRUPCION POR PUERTO B-------
INT_PUERTOB
	
ANTIREBOTE_INT
	call 	delay_10ms ;Hago delay para esperar a que pase el rebote
	call 	delay_10ms
PROBANDO_RB0
	btfsc 	PORTB, 0 	;Testeo el bit RB0, si se dejo de pulsar el boton bajara a cero
	goto 	PROBANDO_RB0
	call 	delay_10ms
	call 	delay_10ms	;Una vez que se dejo de presionar el boton, hago un delay de 10 ms para que pase el rebote.

	bcf		INTCON, INTF
	bcf		INTCON, INTE	
	bsf	 	FLAGS, Comenzo
	bcf		INTCON, RBIF
	bcf 	INTCON, T0IF
	retfie
	;---ANTIREBOTE POR SOFTWARE DE LOS PULSADORES-----	

INT_PUERTOB1
ANTIREBOTE_RB
;{
	call 	delay_10ms
	call	delay_10ms ;Espero 10ms a que pase el rebote
	movf 	PORTB, 0 	;muevo el puerto B a w
	andlw 	0xF0	;Hago and con los bits que me importan y los guardo
	movwf 	Valor_aux ;Esta es la variable que utilizo en la rutina para comparar
	movwf	PORTD
	btfsc	FLAGS, Crear
	call	CREAR_RANDOM

PROBANDO_RB
	movf 	PORTB, 0	;Prendemos el led que se pulsa
	andlw 	0xF0	;Hago AND a los bits que me interesan
	btfss 	STATUS, Z	;Si todos los bits estan en cero significa que se dejo de pulsar
	goto 	PROBANDO_RB	;Sino, sigo probando hasta que se deje de pulsar el boton
	call 	delay_10ms
	call	delay_10ms	;Hago un delay por el rebote de soltar el pulsador
	clrf	PORTD
;}

	;-----FIN ANTIREBOTE POR SOFTWARE-----
;{
	;----Comienzo de Rutina de Interrupcion por PUERTO B----	

	movf	INDF,0			;MUEVO EL VALOR AL QUE PUNTA FSR A W
	call	TABLA			
	xorwf	Valor_aux, 0	;tengo que ver si el valor que pulso es el que deberia pulsar
	btfss	STATUS,Z		;SI EL XOR DA 0 ES PORQUE SON IGUALES, ENTONCES PULSO BIEN
	goto	Levanto_flag_perdio;SI NO DA EL BIT Z DE STATUS DA 0 ENTONCES PERDIO
	goto	SIG

;En el bloque SIG, verifico si ya pulso todos o debe seguir pulsando
SIG
	decfsz	Contador, 1
	goto	No_Llego_Cero
	goto	Llego_Cero

;EL CONTADOR NO LLEGO A CERO, EL JUGADOR DEBE CONTINUAR CON LA SECUENCIA
No_Llego_Cero
	incf 	FSR,1	;AUMENTO FSR ASI EN LA SIGUIENTE PULSACION VERIFICO CORRECTAMENTE
	bcf		INTCON,RBIF
	bcf		INTCON,INTF
	retfie

;---EL CONTADOR LLEGO A CERO, ACA DEBO CONTROLAR SI YA GANO 
;O HAY QUE MOSTRAR UNA NUEVA SECUENCIA----
Llego_Cero
	movlw	Primer_valor
	movwf	FSR	
	movf	Numero_de_valores_de_secuencia,0
	xorwf	Contador_Aux, 0
	btfsc	STATUS,Z 	;verifico si ya gano haciendo un xor con la cantidad de valores
	goto	Levanto_bandera_gano
	bsf		FLAGS,Crear
	bsf		FLAGS,Proximo ;Seteo la bandera de proximo para que el programa sepa que debe mostrar la siguiente secuencia
	bcf		INTCON,RBIF
	bcf		INTCON,INTF
	retfie


	;----LEVANTAMIENTO DE BANDERAS DE GANO O PERDIO-----
Levanto_bandera_gano 
	bsf		FLAGS,Gano ;Se levanta el flag de la bandera que gano
	bcf		INTCON,RBIF
	bcf		INTCON,INTF
	retfie

	
Levanto_flag_perdio

	bsf 	FLAGS,Perdio ;LEVANTO EL FLAG YA QUE PERDIO
	bcf		INTCON,RBIF
	bcf		INTCON,INTF	
	retfie;}
	;------	FIN LEVANTAMIENTO DE BANDERAS----------------
;---------FIN INTERRUPCIONES PUERTO B---------

;-------INTERRUPCION POR TIMER0--------
INT_TIMER
;{
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
	call	delay_10ms	
	call	delay_10ms	
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms
	call	delay_10ms	
	decfsz	Contador,1 ;aca controlo si debo mostrar un color mas o ya termino esa secuencia
	goto	MUESTRO_COLOR
	goto	FIN_INT_TIMER

	;-----MOSTRAR COLOR------
MUESTRO_COLOR
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
	call	delay_10ms	
	call	delay_10ms	
	call	delay_10ms
	incf	FSR,1
	movf	INDF,0		;MUEVO EL VALOR AL QUE APUNTA FSR A W Y LUEGO LLAMO A LA TABLA
	call	TABLA
	movwf 	PORTD		;LE MANDO W AL PUERTOD PARA QUE SE PRENDA EL LED CORRESPONDIENTE
	movlw	.0
	movwf	TMR0
	bcf		INTCON,T0IF	;BAJO BANDERA DEL TIMER
	retfie
	;---FIN MOSTRAR COLOR----
	
FIN_INT_TIMER
	;ESTE BLOQUE MANEJA CUANDO YA TERMINO DE MOSTRAR TODA LA SECUENCIA DE COLORES.
	movlw	.0
	movwf	TMR0
	movf	Contador_Aux,0
	movwf	Contador
	bsf		FLAGS,Proximo	;ESTA BANDERA LA SETEO PARA QUE SALGA DEL BUCLE ESPERO_TIMER
	movlw	Primer_valor
	movwf	FSR				;REINICIO EL VALOR AL QUE APUNTA FSR
	bcf		INTCON,T0IF		;BAJO BANDERA DE TIMER0
	bcf		INTCON,T0IE		;DESHABILITO LA INTERRUPCIONES POR TIMER
	retfie
;}
	;------FIN INTERRUPCION POR TIMER0-------





;-----FIN INTERRUPCIONES---------

;---TABLA DE VALORES PARA LOS LEDS----

TABLA
;{
	addwf 	PCL,1
	retlw	b'10000000'
	retlw	b'01000000'
	retlw	b'00100000'
	retlw	b'00010000'

;}
;-------FIN TABLA---------------

;----BLOQUE QUE GENERA LA SECUENCIA----

Generar_Secuencia
;{
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
;}
;-------FIN BLOQUE GENERADOR DE SECUENCIA---------------

;---Retardo por software de 10ms----

delay_10ms	
;{
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
;}
;--------FIN RETARDO--------------

CREAR_RANDOM
	movf	Puntero,0
	movwf	FSR
	movf	Random,0
	andlw	b'00000011'
	movwf	INDF
	movlw	Primer_valor
	movwf	FSR
	incf	Puntero,1
	bcf		FLAGS,Crear
	return
	end