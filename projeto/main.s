.equ DATA_REGISTER, 0x10001000              # Registrador de dados da UART
.equ CONTROL_REGISTER, 0x10001004           # Registrador de controle da UART

/*
    Comando usuários:
        00 xx
        01 xx
        10
        11
        20
        21

    CONFIRMAR:
        ASCII       HEXA
        A           8061

        Tem que tirar o "80" ou manter ??????

    MODIFICAR:

*/

.global _start
_start:
    
    movia r8, DATA_REGISTER
    movia r10, CONTROL_REGISTER
    
    mov r14, r0                                 # r14 armazenará a entrada do usuário
    MENSAGEM_INICIAL:
        # Código para escrever "Entre com um comando"

    movi r15, 0                                 # contador
    movi r16, 2                                 # limite do loop
    LACO_INFINITO:

        POOLING_LEITURA:    
            ldwio r9, (r8)                      # le DATA_REGISTRER
            andi r13, r9, 0x8000                # le RVALID
            beq r13, r0, POOLING_LEITURA        # se r13 == 0, goto pooling.leitura

        POOLING_ESCRITA:
            ldwio r11, (r10)                    # le CONTROL_REGISTRER
            andhi r12, r11, 0xFFFF              # le WSPACE
            beq r12, r0, POOLING_ESCRITA        # se WSPACE == 0 (CHEIO), goto pooling.escrita
            stwio r9, (r8)                      # escreve c no registrador de dados
    
            andi r9, r9, 0b11111111             # remove o "80" do caractere digitado --> PRECISA DISSO ??????????? CONFIRMAR COM PROFESSOR ???????????
            or r14, r14, r9                     # escreve c em r14
            addi r15, r15, 1                    # incrementa o contador 

            beq r15, r16, SAI_POOLING_ESCRITA   # se r15 já for igual ao limite do contador (r16) sai do pooling 
            slli r14, r14, 8                    # mover o ultimo caractere 16 bits a esquerda

        SAI_POOLING_ESCRITA:
        
        
        br LACO_INFINITO
    
STOP:
    br STOP

COMANDOS:
.skip