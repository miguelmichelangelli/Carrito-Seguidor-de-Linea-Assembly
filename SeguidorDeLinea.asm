; PROGRAMA CARRITO SEGUIDOR DE LÍNEA

; limpio los bancos
BCF STATUS, RP0
BCF STATUS, RP1

; me muevo al banco 1 para establecer entradas y salidas en puertos
BSF STATUS, RP0

; puertosB 0 y 1 como entradas (sensores)
BSF TRISB, 0 ; puerto 0 sensor izquierdo
BSF TRISB, 1 ; puerto 1 sensor derecho

; puertosB 2, 3 y 4 como entradas (botones, selector modo)
BSF TRISB, 2
BSF TRISB, 3
BSF TRISB, 4

; puertosC 0, 1, 2 y 3 como salidas (encendido-apagado de motores) SE USAN 2 PARA C/MOTOR
BCF TRISC, 0 ; motor izquierdo
BCF TRISC, 1
BCF TRISC, 2 ; motor derecho
BCF TRISC, 3

; volviendo al banco 0
BCF STATUS, RP0

GOTO INICIO

INICIO:
;   MODO 1. Seguidor de Línea
    MODO_SEGUIDOR:
        CALL REVISA_DECIDE
        GOTO MODO_SEGUIDOR

;   MODO 2. Seguidor + Memorizar
    MODO_GRABAR:
        ; LIMPIAMOS MEMORA
        CALL LIMPIAR_MEMORIA

        ; ESTABLECEMOS INICIO DE LA MEMORIA 0x20

        ; ENTRAMOS A UN BUCLE QUE EMPIEZA CON LA GRABACION

        

    ; revision y decision constante de movimiento
    REVISA_DECIDE:
        ; suponiendo LINEA_NEGRA = 1
        
        BTFSC PORTB, 0 ; revisando si sensor izquierdo ve línea negra
        CALL GIRAR_IZQ

        BTFSC PORTB, 1 ; revisando si sensor derecho ve línea negra
        CALL GIRAR_DER

        CALL AVANZAR_RECTO ; si llegó aquí no hay giro
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

    FRENAR MOTOR:
        MOVLW b'00001111'
        MOVWF PORTC
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

            GOTO LIMPIEZA

