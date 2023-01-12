;******************************************************************************
;******************************************************************************
;	MODELO PADR�O PARA INICIALIZA��O DE MICROCONTROLADORS PIC16F628A PARA
;   PLATAFORMA DE DESENVOLVIMENTO MPLAB IDE V.8.36
;	DESENVOLVIDO POR FERNANDO FERREIRA
;	DATA: 03/10/2009

;	Select Register Bank 0

bank0	macro
	errorlevel	+302		; Re-enable bank warning
	bcf		STATUS,RP0	; Select Bank 0
	endm

;-------------------------------------------------------------------
;	Select Register Bank 1

bank1	macro
	bsf		STATUS,RP0	; Select Bank 1
	errorlevel	-302		; disable warning
	endm

;-------------------------------------------------------------------
;	Swap bytes in register file via W

swap	macro	this,that

	movf	this,w		; get this
	xorwf	that,f		; Swap using Microchip
	xorwf	that,w		; Tips'n Tricks
	xorwf	that,f		; #18
	movwf	this

	endm
;-------------------------------------------------------------------
;	Copy bytes in register file via W

copy	macro	from,to

	MOVF	from,W
	MOVWF	to

	endm
	
;**************************************************
;	DEFINI��ES DO SISTEMA
;****************************************************	
	#DEFINE	LIGA	PORTB,5	;PINO12
	#DEFINE PESO	PORTB,0 ;PINO7
	#DEFINE DOSADOR PORTB,7 ;PINO14
	#DEFINE	VARRE	PORTB,1	;PINO8
	#DEFINE	BUCHA	PORTB,2	;PINO9
	#DEFINE	FECHA	PORTB,6	;PINO13
	#DEFINE CONT	PORTB,4	;PINO11	
	
;*******************************************************************
;	CPU configuration                                    
;***********************************************************

	MESSG		"Processor = 16F628"
	processor	16f628
	include		<p16f628.inc>
	__CONFIG        _CP_OFF & _WDT_OFF & _PWRTE_ON & _HS_OSC & _BODEN_ON & _LVP_OFF

;********************************

	CBLOCK	0X20
	W_TEMP
	STATUS_TEMP
	ENDC

;*******************************************************
;	VETOR DE RESET DO SISTEMA                          | 
;*******************************************************
	ORG		0X00			;Vetor de reset
	goto	INICIO			;

;*******************************************************
;	INTERRUP��ES                                       |
;*******************************************************
	ORG		0X04			;Vetor comum `as interrupcoes.
	MOVWF	W_TEMP		; SALVA O REGISTRADOR W
	SWAPF	STATUS,W
	MOVWF	STATUS_TEMP	; SALVA O STATUS DO SISTEMA

INT_DEF:
	btfsc	PIR1,RCIF		;Testa se ocorreu Int. Serial de recep��o.
	goto	INT_END			;Trata Recep��o Serial.
	btfsc	INTCON,INTF		;Testa se ocorreu Int. Externa.
	goto	INT_END			;Trata Int. Externa.
	btfsc	INTCON,T0IF		;Testa se ocorreu Int. de overflow do Timer0.
	goto	INT_END			;Trata Int. de Timer0

INT_END:	
	SWAPF	STATUS_TEMP,W
	MOVWF	STATUS		; RETORNA O STATUS DO SISTEMA
	SWAPF	W_TEMP,F	; RETORNA O REGISTRADOR F
	SWAPF	W_TEMP,W	; RETORNA O REGISTRADOR W
	retfie					;Retorna caso ocorra uma interrup��o n�o definida.
	
;********************************
;*** INICIALIZACAO DO SISTEMA ***
;********************************
INICIO
	clrwdt					;Zera WDT e prescaler
	clrf	PORTA			;Zera latchs da PORTA
	clrf	PORTB			;Zera latchs da PORTB
	movlw	b'00000111'		;|Desliga comparadores
	movwf	CMCON			;|
	BANK1					;|Seleciona banco 1	
	movlw	b'00000000'		;|Configura os pinos das portas
	movwf	TRISA			;|input=1
    movlw   b'00000001'     ;|output=0
    movwf   TRISB			;|
    
  	movlw	b'00000000'		;|
	movwf	OPTION_REG		;|
    BANK0					;Seleciona Banco 0
	movlw	b'00000000'		;|
	movwf	INTCON			;|
	bcf	INTCON,GIE			;|Mascara todas as int�s habilitadas.

;////////////////////////////////////////////////////////////////////////////

	bsf		LIGA			;|Liga led indicativo que o sistema est� energizado

;*******************************
; PROGRAMA PRINCIPAL
rotina:
	bsf		DOSADOR			;|liga dosador 
	btfss	PESO			;|verifica se o peso atingiu o valor esperado
	goto	rotina			;|se n�o, continua executando a rotina programada
	bcf		DOSADOR			;|se sim, desliga dosador	
	call	embrulho		;|e inicia processo de embasamento	
	goto	rotina			;|ao final retorna a rotina
	
embrulho:
;	call	delay_			;|espera um tempo de XX segundos para sentar o produtos
	bsf		VARRE			;|liga o pist�o para empurrar o produto para o funil
;	call	delay_			;|espera XX segundos para o pist�o avan�ar
	bcf		VARRE			;|desliga o pist�o
;	call	delay_			;|espera XX segundos para o pist�o recolher
	bsf		BUCHA			;|aciona pist�o para carregar a dose na embalagem
;	call	delay_			;|espera XX segundos para o pist�o avan�ar
	bcf		BUCHA			;|desliga o pist�o
;	call	delay_			;|espera XX segundos para o pist�o recolher
	bsf		FECHA			;|ativa fun��o de fechamento e avan�o de embalagens
;	call	delay_			;|espera XX segundos para a execu��o da a��o
	bcf		FECHA			;|desativa fun��o de fechamento e avan�o de embalagens
	bsf		CONT			;|pulsa pino de contagem
	bcf		CONT			;| 
	return					;|termina processo de embrulho  
end
