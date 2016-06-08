	list p=16f887
	INCLUDE "p16F887.inc"
	org	0x00
	goto 	INICIO
	org	0x04
	goto	INTERRUPCION
	
INICIO
	
	call CFG

ESPERA
	nop
	goto ESPERA

CFG
	banksel ANSELH
	clrf	ANSELH

	banksel TRISB
	movlw	b'11111101'
	movwf	TRISB
	bsf	OPTION_REG,6

	banksel INTCON
	movlw	b'10011000'
	movwf 	INTCON
	clrf	PORTB
	return
	
INTERRUPCION
	
	btfsc	INTCON,INTF
	goto	INT_RB0
	btfsc 	INTCON,RBIF
	goto 	INT_RB0
	retfie

INT_RB0
	movf	PORTB,1
	movlw	b'00000010'
	xorwf	PORTB,1
	bcf		INTCON,RBIF
	bcf		INTCON,INTF
	retfie


end
	