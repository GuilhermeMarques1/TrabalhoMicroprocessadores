
.equ LEDS_VERMELHOS, 0x10000000

.global LED
LED:
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
	addi fp, sp, 32						# seta o novo frame pointer


    movia r8, LEDS_VERMELHOS
    movia r9, BUFFER_ESCRITA         

    mov r11, r0
    mov r12, r0

    ldw r10, 4(r9)                      # r10 = acender ou apagar o xx-esimo LED

    ldw r11, 8(r9)                      # r11 = primeiro caractere do xx-esimo LED
    subi r11, r11, 0x30
    beq r11, r0, NAO_SOMAR              # se o primeiro caractere for 0, somar 9
    movi r15, 9
    add r11, r11, r15

    NAO_SOMAR:
    # slli r11, r11, 8
    ldw r12, 12(r9)                     # r12 = segundo caractere do xx-esimo LED
    subi r12, r12, 0x30

    add r11, r11, r12                   # soma os 2 caracteres obtidos
    
    movi r14, '0'
    bne r10, r14, APAGAR_LED            # se r10 == 0 acender led, senao apagar led
    movi r15, 1                         # inicializando r15 com 1
    sll r15, r15, r11                   # shiftar r15 "r11" vezes para a esquerda
    ldwio r14, (r8)                     # pega os bits atuais do LED_VERMELHO
    or r15, r14, r15                    # or para manter os bits que já estavam acesos
    stwio r15, (r8)
    br JA_ACENDEU

    APAGAR_LED:
    movia r15, 0xFFFFFFFE               # inicializando r15 tudo com 1
    rol r15, r15, r11                   # rotacionar r15 "r11" vezes para a esquerda
    ldwio r14, (r8)                     # pega os bits atuais do LED_VERMELHO
    and r15, r14, r15                   # and para manter os bits que já estavam acesos
    stwio r15, (r8)

    JA_ACENDEU:

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