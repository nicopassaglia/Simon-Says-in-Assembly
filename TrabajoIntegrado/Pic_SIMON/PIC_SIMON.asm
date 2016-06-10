	list p=16f887
	INCLUDE "p16F887.inc"
	CBLOCK 0x21
	SCORE
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
MAX_VAL	EQU .4
	org	0x00
	goto 	INICIO
	org	0x04
	goto	INTERRUPCION
	;SOMOS GRUPO 18
INICIO

	call	CFG
	call 	Configuracion_Puerto_Serie
	movlw 	MAX_VAL
	movwf 	Numero_de_valores_de_secuencia
MAIN	
	incf	Random, 1
	btfss 	FLAGS, Comenzo	;Cuando viene interrupcion por RB0 setea el FLAG
	goto 	MAIN
	movf 	Random, 0
	andlw 	b'00000011'
	movwf 	Primer_valor
	clrf	SCORE	;Reinicio SCORE
	bsf 	INTCON, RBIE
	bsf 	FLAGS, Crear
	call	Mostrar_Secuencia
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
	bcf		INTCON, GIE ;No puede haber mas interrupciones
	movf 	SCORE, 0	
	movwf 	TXREG		;Transmito el puntaje al otro PIC
	goto 	$	;}


GANO_JUEGO
;{
	;PRENDO LED QUE MUESTRA QUE GANO
	bsf		PORTD,1
	bcf		INTCON, GIE ;No puede haber mas interrupciones
	movf 	SCORE, 0
	movwf 	TXREG		;Aqui deberia transmitir algo para mostrar que gano.
	goto	$ ;}


;MUESTRO LA SECUENCIA DE LEDS

	;----MOSTRAR SECUENCIA DE COLORES----
Mostrar_Secuencia
;{

	bcf		INTCON,RBIE ;En este momento no se puede interrumpir el programa
	bcf		INTCON,INTE
	movlw 	Primer_valor
	movwf 	FSR
Volver_Hacerlo
	movf 	INDF,0
	call 	TABLA
	movwf 	PORTD

	call delay_100ms
	call delay_100ms
	call delay_100ms
	call delay_100ms
	call delay_100ms
	incf FSR, 1
	clrf PORTD
	call delay_100ms
	decfsz Contador, 1
	goto Volver_Hacerlo

	clrf	PORTD
	bsf 	INTCON, RBIE
	movlw 	Primer_valor
	movwf 	FSR
	movf 	Contador_Aux, 0
	movwf 	Contador
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
	incf SCORE, 1	;Aumento uno al score
	movlw	Primer_valor
	movwf	FSR	
	movf	Numero_de_valores_de_secuencia,0
	xorwf	Contador_Aux, 0
	btfsc	STATUS,Z 	;verifico si ya gano haciendo un xor con la cantidad de valores
	goto	Levanto_bandera_gano
	bsf		FLAGS,Crear
	bsf		FLAGS,Proximo ;Seteo la bandera de proximo para que el programa sepa que debe mostrar la siguiente secuencia
	call delay_100ms
	call delay_100ms
	call delay_100ms
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
;---Retardo por software de 100ms----

delay_100ms	
;{
	movlw 	.200
	movwf 	DELAY2
BUCLE2_100
	movlw 	.124
	movwf 	DELAY1
BUCLE1_100
	nop
	decfsz 	DELAY1, 1
	goto 	BUCLE1_100
	decfsz 	DELAY2, 1
	goto 	BUCLE2_100
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

	bcf STATUS, RP0
	bcf STATUS, RP1
	
	return

	end