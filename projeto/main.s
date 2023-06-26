.equ DATA_REGISTER, 0x10001000              # Registrador de dados da UART
.equ CONTROL_REGISTER, 0x10001004           # Registrador de controle da UART
.equ STACK, 0x10000
.equ TIMER, 0x10002000 
.equ INTERRUPTMASK_PB, 0x10000058
.equ EDGE_CAPTURE_PB, 0x1000005C

.org 0x20
    # PROLOGO SF
    addi sp, sp, -32
    stw ra, 28(sp)
    stw r8, 24(sp)
    stw r9, 20(sp)
    stw r10, 16(sp)
    stw r11, 12(sp)
    stw r12, 8(sp)
    stw r13, 4(sp)
    stw r14, 0(sp)

    rdctl et, ipending              # checar se ocorreu interrupção
    beq et, r0, OTHER_EXCEPTIONS    # se et=0, não é exceção de hardware
    subi ea, ea, 4

    andi r12, et, 1                 # checar se houve interrupção no Timer (IRQ0 asserted)
    beq r12, r0, OTHER_INTERRUPTS   # se não, checar outras exceções externas
    call EXT_IRQ0                   # se sim, tratar a exceção na subrotina EXT_IRQ0

OTHER_INTERRUPTS:
/* Instruções que checam por outras interrupções por hardware devem ser colocadas aqui */
    andi r12, et, 0b10              # checar se houve interrupção no PushButton
    beq r12, r0, END_HANDLER        # se não, ir para END_HANDLER
    call EXT_IRQ1                   # se sim, ir para EXT_IRQ1

OTHER_EXCEPTIONS:
/* Instruções que checam por outros tipos de interrupções devem ser colocadas aqui */

END_HANDLER:
    # EPILOGO SF
    ldw ra, 28(sp)
    ldw r8, 24(sp)
    ldw r9, 20(sp)
    ldw r10, 16(sp)
    ldw r11, 12(sp)
    ldw r12, 8(sp)
    ldw r13, 4(sp)
    ldw r14, 0(sp)
    addi sp, sp, 32
    eret

EXT_IRQ0:
/* Instruções que tratam a interrupção IRQ0 devem ser colocadas aqui */

    # ---- PROLOGO ----
    addi sp, sp, -4
    stw ra, 0(sp)

    movia r8, FLAG_ANIMACAO
    movi r9, 1

    ldw r10, (r8)                           # r8 = FLAG_ANIMACAO
    
    bne r10, r9, NAO_CHAMA_ANIMACAO         # se FLAG_ANIMACAO = 1 (chamar animacao), senao (nao chamar animacao) 
    call ANIMACAO

    NAO_CHAMA_ANIMACAO:
    
    movia r8, FLAG_CRONOMETRO
    movia r12, COUNT_CONTROLE
    movi r14, 4

    ldw r10, (r8)                           # r8 = FLAG_CRONOMETRO
    ldw r13, (r12)                          # r13 = COUNT_CONTROLE 
    bne r10, r9, NAO_CHAMA_CRONOMETRO       # se FLAG_CRONOMETRO = 1 (verificar COUNT_CONTROLE), senao (nao chamar cronometro)
    beq r13, r14, VERIFICAR_PB              # se COUNT_CONTROLE = 5 (chamar cronometro), senao (nao chamar cronometro)
    br NAO_CHAMA_CRONOMETRO

    VERIFICAR_PB:
    movia r8, STATUS_CONTAGEM
    ldw r10, (r8)                           # r10 = STATUS_CONTAGEM
    beq r10, r0, NAO_CHAMA_CRONOMETRO       # se STATUS_CONTAGEM = 0 goto NAO_CHAMA_CRONOMETRO, senao CALL_CRONOMETRO
    call CRONOMETRO

    NAO_CHAMA_CRONOMETRO:
    addi r13, r13, 1
    ble r13, r14, NAO_RESETA_COUNT          # se COUNT_CONTROLE < 5 (nao reseta count), senao (reseta count)
    movi r13, 0

    NAO_RESETA_COUNT:
    stw r13, (r12)

    # desabilitar o bit TO do TIMER_STATUS_REGISTRER
    movia r10, TIMER
    movi r11, 0b10
    stwio r11, (r10)

    # ---- EPILOGO ----
    ldw ra, (sp)
    addi sp, sp, 4

    ret

EXT_IRQ1:
/* Instruções que tratam a interrupção IRQ1 devem ser colocadas aqui */

    # ---- PROLOGO ----
    addi sp, sp, -4
    stw ra, 0(sp)

    movia r8, EDGE_CAPTURE_PB
    
    movi r9, 0b10
    ldwio r10, (r8)                         # lendo edge capture
    beq r10, r9, BOTAO_PRESSIONADO:
    br ZERAR_PB

    BOTAO_PRESSIONADO:
    movia r11, STATUS_CONTAGEM
    ldw r12, (r11)                          # r12 = STATUS_CONTAGEM
    beq r12, r0, RESUMIR_CONTAGEM           # se STATUS_CONTAGEM = 0 (resumir contagem), se STATUS_CONTAGEM = 1 (pausar contagem)
    stw r0, (r11)                           # STATUS_CONTAGEM = 0
    br ZERAR_PB                             # contagem não deve ocorrer

    RESUMIR_CONTAGEM:
    movi r13, 1
    stw r13, (r11)                          # STATUS_CONTAGEM = 1

    ZERAR_PB:
    stwio r0, (r8)                          # zerar edge capture

    # ---- EPILOGO ----
    ldw ra, (sp)
    addi sp, sp, 4

    ret

.global _start
_start:
    movia sp, STACK                         /* Configura registrador da pilha */
    mov	fp,  sp                             /* Configura frame pointer */

    movia r8, DATA_REGISTER
    movia r10, CONTROL_REGISTER
    movia r14, BUFFER_ESCRITA
    movia r11, 10000000                     # estabelecer periodo da contagem
    movia r12, TIMER                        # endereco base do timer
    movia r13, INTERRUPTMASK_PB

    /* Habilitar interrupção do push button */

    # configurar qual dos botões gera interrupção - somente KEY1
    movi r9, 0b010                          # máscara KEY1
    stwio r9, (r13)                         # registrador de máscara de interrupção

    /* Habilitar interrupção do timer */

    # colocar periodo de contagem (parte baixa e parte baixa)
    andi r13, r11, 0xFFFF                   # pega a parte baixa
    srli r9, r11, 16                        # parte alta
    stwio r13, 8(r12)                       # parte baixa <- r17
    stwio r9, 12(r12)                       # parte alta  <- r18

    # setar os bits timer
    movi r11, 0b0111
    stwio r11, 4(r12)                       # TIMER CONTROL REGISTRER <- [UNUSED] | STOP=0 | START=1 | CONT=1 | ITO=1

    # habilitar o Timer (IRQ0) e Push BUtton (IRQ1) no ienable
    movi r15, 0b11
    wrctl ienable, r15

    # habilitar o bit PIE do status (processador)
    wrctl status, r15

    # Imprimindo a mensagem inicial
    movia r9, MENSAGEM_INICIAL
    IMPRIMIR_MENSAGEM:
        ldb r13, (r9)
        beq r13, r0, PARAR_IMPRESSAO
        stwio r13, (r8)
        addi r9, r9, 1
        br IMPRIMIR_MENSAGEM

    PARAR_IMPRESSAO:

    movi r15, 0                                 # contador
    movi r15, 0xa                               # r15 recebe o caractere "enter"
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
    
            andi r9, r9, 0b11111111             # remove o "80" do caractere digitado

            beq r9, r15, SAI_LACO_INFINITO      # se usuario digitou enter -> sai do LACO_INFINITO
            stw r9, (r14)                       # escreva o caractere no buffer

            addi r14, r14, 4
            br POOLING_LEITURA

        br LACO_INFINITO

    SAI_LACO_INFINITO:

        movia r14, BUFFER_ESCRITA               # volta para o começo do BUFFER_ESCRITA
        ldw r9, (r14)                           # le BUFFER_ESCRITA

        movi r14, '0'                           # movendo o caractere '0' para r14
        beq r9, r14, CALL_LED
        
        movi r14, '1'                           # movendo o caractere '1' para r14
        beq r9, r14, SETAR_ANIMACAO

        movi r14, '2'                           # movendo o caractere '2' para r14
        beq r9, r14, SETAR_CRONOMETRO

        CALL_LED:
            call LED
            br FIM
        
        SETAR_ANIMACAO:
            movia r11, FLAG_ANIMACAO
            movia r14, BUFFER_ESCRITA

            ldw r9, 4(r14)                       # r9 = 0 ou 1
            movi r13, '0'
            bne r9, r13, SETA_ZERO_ANIMACAO      # se entrada=10 (seta FLAG_ANIMACAO para 1), se entrada=11 (seta FLAG_ANIMACAO para 0)
            movi r9, 1
            stw r9, (r11)                        # FLAG_ANIMACAO = 1
            br FIM

            SETA_ZERO_ANIMACAO:
            stw r0, (r11)                        # FLAG_ANIMACAO = 0
            br FIM

        SETAR_CRONOMETRO:
            movia r11, FLAG_CRONOMETRO
            movia r14, BUFFER_ESCRITA

            ldw r9, 4(r14)                      # r9 = 0 ou 1
            movi r13, '0'
            bne r9, r13, SETA_ZERO_CRONOMETRO   # se entrada=10 (seta FLAG_CRONOMETRO para 1), se entrada=11 (seta FLAG_CRONOMETRO para 0)
            movi r9, 1
            stw r9, (r11)                       # FLAG_CRONOMETRO = 1
            br FIM

            SETA_ZERO_CRONOMETRO:
            stw r0, (r11)                       # FLAG_CRONOMETRO = 0

        FIM:
        movia r14, BUFFER_ESCRITA
        br LACO_INFINITO
STOP:
    br STOP

.org 0x500

.global BUFFER_ESCRITA
BUFFER_ESCRITA:
.skip 16

FLAG_ANIMACAO:
.word 0

FLAG_CRONOMETRO:
.word 0

COUNT_CONTROLE:
.word 0

/* 
    COUNT_CRONOMETRO --> estrutura de dados que efetivamente realizará a contagem

    COUNT_CRONOMETRO = unidade, dezena, centena, milhar
*/
.global COUNT_CRONOMETRO
COUNT_CRONOMETRO:
.word 0, 8, 9, 9

/*
STATUS_CONTAGEM = 0 (false) ----> contagem está pausada
STATUS_CONTAGEM = 1 (true)  ----> contagem está resumida
*/
STATUS_CONTAGEM:
.word 1

.global INDICE_LED
INDICE_LED:
.word 0

MENSAGEM_INICIAL:
.asciz "Entre com o comando:\n"
