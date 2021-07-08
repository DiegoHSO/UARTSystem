.text
.globl main

# SALTA PARA O IN�CIO DO C�DIGO DO USU�RIO
#####################################################
main:
        j MyMain


# ENDERE�O DA TABELA DE ENDERE�AMENTO DE INTERRUP��ES
########################################################
TabelaDeInterrupcoes:
        j CPU_to_UART
        j UART_to_CPU


# ROTINAS PARA TRATAR AS INTERRUP��ES
#####################################
CPU_to_UART: # Tratamento de interrup��o de ESCRITA na UART
	addiu $sp, $sp, -8 # Aloca espa�o na pilha
        sw $t0, 0($sp) # Salva o conte�do do registrador na pilha
        sw $t1, 4($sp) # Salva o conte�do do registrador na pilha
	addiu $s0, $s0, 1     # Incrementa o ponteiro de mensagemTransmitida
	eret # Fim da rotina de tratamento de interrup��o
        
#############################################
UART_to_CPU: # Tratamento de interrup��o de LEITURA da UART
	lbu $s4, 8($s2)        # L� o caractere escrito na UART B e passa para o registrador $s4
	sb $s4, 0($s1)        # Armazena caractere no mensagemRecebida
	addiu $s1, $s1, 1     # Incrementa ponteiro de mensagemRecebida
	eret # Fim da rotina de tratamento de interrup��o


# IN�CIO DO PROGRAMA DO USU�RIO NO ENDERE�O
#############################################
MyMain:
	la $s0, mensagemTransmitida  # $s0 � o ponteiro de mensagemTransmitida
	la $s1, mensagemRecebida     # $s1 � o ponteiro de mensagemRecebida
        li $t0, 1 # Carrega valor qualquer no registrador
        li $t1, 2 # Carrega valor qualquer no registrador
        li $t2, 0 # Carrega valor qualquer no registrador
	la $s2, EnderecoUART # Carrega o endere�o da UART na mem�ria no registrador
	lw $s2, 0($s2) # Carrega o endere�o da UART no registrador
			
SaltoMyMain: 
	lbu $s3, 0($s0)  # Carrega a letra da mensagem em $s3
       	beq $s3, $zero, UltimoCaracter # Caso o caract�re lido seja igual a 0 (fim da frase), desvia para o fim do programa
       	sb $s3, 4($s2)  # Armazena a letra na UART A
        nop
        lw $t1, 4($sp) # Recupera o valor de $t1 salvo na pilha
       	lw $t0, 0($sp) # Recupera o valor de $t2 salvo na pilha
        addiu $sp, $sp, 8 # Libera o espa�o anteriormente armazenado na pilha
        j SaltoMyMain
 
 
UltimoCaracter:	
       	sb $s3, 4($s2)  # Armazena a letra na UART A
        nop
        lw $t1, 4($sp) # Recupera o valor de $t1 salvo na pilha
       	lw $t0, 0($sp) # Recupera o valor de $t2 salvo na pilha
        addiu $sp, $sp, 8 # Libera o espa�o anteriormente armazenado na pilha
	
Fim:	
	j Fim




.data
# Mensagem transmitida do 'SisA' pro 'SisB'
mensagemTransmitida:            .asciiz "Isto eh um teste!" 
# Mensagem recebida pelo 'SisA' do 'SisB'
mensagemRecebida:               .asciiz "                      " 

EnderecoUART:			.word 0xFFE00000

