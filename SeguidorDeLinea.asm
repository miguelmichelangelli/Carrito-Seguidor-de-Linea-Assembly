; PROGRAMA CARRITO SEGUIDOR DE LÍNEA

; CONFIG
; __config 0x3F39
 __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

; limpio los bancos
BCF STATUS, RP0
BCF STATUS, RP1

; me muevo al banco 1 para establecer entradas y salidas en puertos
BSF STATUS, RP0

; puertosB 0 y 1 como entradas (sensores)
BSF TRISB, 0 ; puerto 0 sensor izquierdo
BSF TRISB, 1 ; puerto 1 sensor derecho

; puertosB 2, 3 y 4 como entradas (botones, selector modo)
BSF TRISB, 2 ; MODO 1. Seguidor de Línea
BSF TRISB, 3 ; MODO 2. Seguidor + Memorizar
BSF TRISB, 4 ; MODO 3. Lectura de Trayecto Grabado

; puertosC 0, 1, 2 y 3 como salidas (encendido-apagado de motores) SE USAN 2 PARA C/MOTOR
BCF TRISC, 0 ; motor izquierdo
BCF TRISC, 1
BCF TRISC, 2 ; motor derecho
BCF TRISC, 3

; volviendo al banco 0
BCF STATUS, RP0

GOTO INICIO

INICIO:
;   MENÚ DE SELECCIÓN
    MENU:
        BTFSC PORTB, 2
        GOTO MODO_SEGUIDOR

        BTFSC PORTB, 3
        GOTO MODO_GRABAR

        BTFSC PORTB, 4
        GOTO MODO_LECTURA

;   MODO 1. Seguidor de Línea
    MODO_SEGUIDOR:
        CALL REVISA_DECIDE
        GOTO MODO_SEGUIDOR

;   MODO 2. Seguidor + Memorizar
    MODO_GRABAR:
        ; LIMPIAMOS MEMORA
        CALL LIMPIEZA    
        
        ; ESTABLECEMOS INICIO DE LA MEMORIA 0x20
        MOVLW 0x20
        MOVWF FSR

        ; ENTRAMOS A UN BUCLE QUE EMPIEZA CON LA GRABACION
        BUCLE_GRABACION:
            CALL REVISA_DECIDE
            MOVF PORTC, W
            MOVWF INDF

            INCF FSR, 1

            CALL RETARDO_200MS

            MOVLW 0x80
            SUBWF FSR, 0

            BTFSC STATUS, Z
            GOTO MENU

            GOTO BUCLE_GRABACION

;   MODO 3. Lectura de Trayecto Grabado
    MODO_LECTURA:
        MOVLW 0x20
        MOVWF FSR

        BUCLE_LECTURA:
            MOVF INDF, W
            MOVWF PORTC

            INCF FSR, 1

            CALL RETARDO_200MS

            MOVLW 0x80
            SUBWF FSR, 0

            BTFSC STATUS, Z
            GOTO MENU

            GOTO BUCLE_LECTURA   

    ; revision y decision constante de movimiento
    REVISA_DECIDE:
        ; suponiendo LINEA_NEGRA = 1
        
        BTFSC PORTB, 0 ; revisando si sensor izquierdo ve línea negra
        GOTO CASO_IZQ

        BTFSC PORTB, 1 ; revisando si sensor derecho ve línea negra
        GOTO CASO_DER

        GOTO AVANZAR_RECTO ; si llegó aquí no hay giro
        RETURN

;   SUBRUTINAS DE MOVIMIENTO DE MOTOR
    GIRAR_IZQ: ; derecho avanza, izquierdo retrocede
        MOVLW b'00001010'
        MOVWF PORTC
        RETURN

    GIRAR_DER: ; izquierda avanza, derecha retrocede
        MOVLW b'00000101'
        MOVWF PORTC
        RETURN

    AVANZAR_RECTO: ; ambos avanzan
        MOVLW b'00001001'
        MOVWF PORTC
        RETURN

    FRENAR_MOTOR:
        MOVLW b'00001111'
        MOVWF PORTC
        RETURN

;   SUBRUTINAS DE DECISIÓN
    CASO_IZQ:
        CALL GIRAR_IZQ
        RETURN

    CASO_DER:
        CALL GIRAR_DER
        RETURN

;   SUBRUTINA DE LIMPIEZA
    LIMPIEZA:
        MOVLW 0x20
        MOVWF FSR
        
        BUCLE_LIMPIEZA:
            CLRF INDF

            INCF FSR, 1
            
            MOVLW 0x80
            SUBWF FSR, 0

            BTFSC STATUS, Z
            RETURN

            GOTO BUCLE_LIMPIEZA

;   BUCLE DE RETARDO
    RETARDO_200MS:
        MOVLW d'2'          ; Carga valor Externo
        MOVWF VAR3

    BUCLE_EXTERNO:
        MOVLW d'133'        ; Carga valor Medio
        MOVWF VAR2

    BUCLE_MEDIO:
        MOVLW d'250'        ; Carga valor Interno
        MOVWF VAR1

    BUCLE_INTERNO:
        NOP                 ; (No Operation) Gasta 1 ciclo extra para precisión
        DECFSZ VAR1, 1      ; Resta 1 a VAR1. ¿Es 0?
        GOTO BUCLE_INTERNO  ; No: Repite. Sí: Salta.

        DECFSZ VAR2, 1      ; Resta 1 a VAR2. ¿Es 0?
        GOTO BUCLE_MEDIO    ; No: Recarga VAR1 y repite. Sí: Salta.

        DECFSZ VAR3, 1      ; Resta 1 a VAR3. ¿Es 0?
        GOTO BUCLE_EXTERNO  ; No: Recarga VAR2 y repite. Sí: Salta.

        RETURN              ; ¡Han pasado 200ms!