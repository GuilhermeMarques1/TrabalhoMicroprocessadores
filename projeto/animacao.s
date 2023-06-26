.equ LEDS_VERMELHOS, 0x10000000
.equ SWITCHES, 0x10000040

.global ANIMACAO
ANIMACAO:
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

    movia r8, LEDS_VERMELHOS
    movia r9, SWITCHES
    movia r12, INDICE_LED

    ldwio r10, (r9)                         # r10 = switches
    ldwio r11, (r8)                         # r11 = leds
    ldw r13, (r12)                          # r13 = INDICE_LED
    andi r10, r10, 0b1                      # pega SW0    

    bne r10, r0, SENTIDO_ANTIHORARIO        # se SW0 = 0 => sentido_horario
    movia r14, 0x20000                      # setando somente o ultimo led vermelho para 1
    srl r14, r14, r13                       # shift a direita "r13 vezes" (r13 == INDICE_LED)
    stwio r14, (r8)
    br FIM

    SENTIDO_ANTIHORARIO:
    movi r14, 0b1
    sll r14, r14, r13
    stwio r14, (r8) 

    FIM:
    addi r13, r13, 1

    movi r15, 18
    bne r13, r15, NAO_RESETA
    movi r13, 0

    NAO_RESETA:
    stw r13, (r12)

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