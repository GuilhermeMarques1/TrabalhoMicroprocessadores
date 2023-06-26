.equ INTERRUPTMASK_PB, 0x10000058
.equ DISPLAY, 0x10000020

.global CRONOMETRO
CRONOMETRO:
    # -------- Prologo --------
	addi sp, sp, -40
	stw ra, 36(sp)
	stw fp, 32(sp)
	stw r8, 28(sp)
	stw r9, 24(sp)
	stw r10, 20(sp)
	stw r11, 16(sp)
	stw r12, 12(sp)
	stw r13, 8(sp)
	stw r14, 4(sp)
	stw r15, 0(sp)
	addi fp, sp, 32						    # seta o novo frame pointer

    movia r9, DISPLAY
    movia r10, COUNT_CRONOMETRO
    movia r12, TABELA

    movi r14, 9                             # r14 = limite da contagem

    ldw r11, (r10)                          # r11 = unidade
    bgt r11, r14, VERIFICAR_DEZENA          # se unidade > 9 VERIFICAR_DEZENA, senao DISPLAY_CRONOMETRO
    br DISPLAY_CRONOMETRO

    VERIFICAR_DEZENA:
    ldw r11, 4(r10)                         # r11 = dezena
    bgt r11, r14, VERIFICAR_CENTENA         # se dezena > 9 VERIFICAR_CENTENA, senao incrementa_dezena e reseta_unidade
    stw r0, (r10)                           # unidade = 0
    addi r11, r11, 1                        # dezena++
    bgt r11, r14, VERIFICAR_CENTENA         # se dezena > 9 VERIFICAR_CENTENA, senao incrementa_dezena
    stw r11, 4(r10)
    br DISPLAY_CRONOMETRO

    VERIFICAR_CENTENA:
    ldw r11, 8(r10)                         # r11 = centena
    bgt r11, r14, VERIFICAR_MILHAR          # se centena > 9 VERIFICAR_MILHAR, senao incrementa_centena, reseta_dezena e reseta_unidade
    stw r0, (r10)                           # unidade = 0
    stw r0, 4(r10)                          # dezena = 0
    addi r11, r11, 1                        # centena++
    bgt r11, r14, VERIFICAR_MILHAR          # se centena > 9 VERIFICAR_MILHAR, senao incrementa_centena
    stw r11, 8(r10)
    br DISPLAY_CRONOMETRO
    
    VERIFICAR_MILHAR:
    ldw r11, 12(r10)                        # r11 = milhar
    bgt r11, r14, VERIFICAR_CENTENA         # se milhar > 9 RESETAR_TUDO, senao incrementa milhar, reseta_centena, reseta_dezena, reseta_unidade
    stw r0, (r10)                           # unidade = 0
    stw r0, 4(r10)                          # dezena = 0
    stw r0, 8(r10)                          # centena = 0
    addi r11, r11, 1                        # milhar++
    bgt r11, r14, RESETAR_TUDO              # se milhar > 9 VERIFICAR_MILHAR, senao incrementa_milhar
    stw r11, 12(r10)
    br DISPLAY_CRONOMETRO

    RESETAR_TUDO:
    stw r0, (r10)
    stw r0, 4(r10)
    stw r0, 8(r10)
    stw r0, 12(r10)

    DISPLAY_CRONOMETRO:
    movi r15, 4             # limite do loop
    movi r14, 0             # i = 0
    LOOP_DISPLAY:
        bge r14, r15, SAI_LOOP

        ldw r11, (r10)
        slli r11, r11, 2    # pegando indice da tabela   (indice = r11 * 2)
        add r13, r12, r11   # pegando endereco da tabela (r13 = BASE_TABELA + indice)

        ldw r13, (r13)      # carregando count_atual
        stbio r13, (r9)     # colocando count_atual no display

        addi r10, r10, 4    # proxima posicao do COUNT_CRONOMETRO
        addi r9, r9, 1      # proximo display
        addi r14, r14, 1    # i++
        br LOOP_DISPLAY

    SAI_LOOP:

    # Incrementar unidade
    movia r10, COUNT_CRONOMETRO
    ldw r11, (r10)
    addi r11, r11, 1
    stw r11, (r10)

    # -------- Epilogo --------
	ldw ra, 36(sp)
	ldw fp, 32(sp)
	ldw r8, 28(sp)
	ldw r9, 24(sp)
	ldw r10, 20(sp)
	ldw r11, 16(sp)
	ldw r12, 12(sp)
	ldw r13, 8(sp)
	ldw r14, 4(sp)
	ldw r15, 0(sp)
	addi sp, sp, 40

    ret

/*
VALOR           CODIGO 7 SEG
0             0111111 => 0x3f
1             0000110 => 0x6
2             1011011 => 0x5b
3             1001111 => 0x4f
4             1100110 => 0x66
5             1101101 => 0x6d
6             1111101 => 0x7d
7             0000111 => 0x7
8             1111111 => 0xff
9             1100111 => 0x67
*/
TABELA:
.word 0x3f, 0x6, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x7, 0xff, 0x67
