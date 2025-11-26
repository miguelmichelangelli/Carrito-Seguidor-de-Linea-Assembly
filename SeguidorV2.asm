; PROGRAMA CARRITO SEGUIDOR DE LÍNEA
    LIST P=16F877A
    #include <p16f877a.inc>
    __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

    CBLOCK 0x20
        BANDERA_T
        SENSOR_IZQ
        SENSOR_DER
        W_TEMP
    ENDC

    ORG 0x00
    GOTO INICIO

INICIO:
    ; limpio la posición de los bancos
    BCF STATUS, RP0
    BCF STATUS, RP1

    ; me muevo al banco 1 para ajustar los puertos a utilizar
    BSF STATUS, RP0

    ; AJUSTE DE PUERTOA COMO DIGITAL
    MOVLW 0x06
    MOVWF ADCON1

    ; usaré:
    ; PuertosA: Botones de selección de modo (0, 1 y 2) - INPUT
    ; PuertosB: Sensores de Línea (0 y 1) - INPUT
    ; PuertosC: Encendido y apagado de motores, salidas por pareja [(0 y 1), (2 y 3)] - OUTPUT

    ; ajuste de trisA
    BSF TRISA, 0 ; Modo 1
    BSF TRISA, 1 ; Modo 2
    BSF TRISA, 2 ; Modo 3

    ; ajuste de trisB
    BSF TRISB, 0 ; Sensor Izq
    BSF TRISB, 1 ; Sensor Der

    ; ajuste de trisC
    BCF TRISC, 0 ; Motor Izq
    BCF TRISC, 1
    BCF TRISC, 2 ; Motor Der
    BCF TRISC, 3

    ; Vuelvo al banco 0 para continuar con la lógica del PROGRAMA
    BCF STATUS, RP0

; MENÚ DE SELECCIÓN DE MODO DE OPERACION (Botones viven en PuertoA)
MENU:
    BTFSC PORTA, 0 ; Si se presiona botón 0
    GOTO MODO_SEGUIDOR ; ejecuta esto

    BTFSC PORTA, 1 ; si se presiona botón 1
    GOTO MODO_GRABADOR ; ejecuta esto

    BTFSC PORTA, 2 ; si se presiona botón 2
    GOTO MODO_LECTURA ; ejecuta esto

    GOTO MENU ; si no se presiona ninguno volver al menú

; MODO 1. Seguidor de Línea (Sensores de línea viven en PuertoB)
MODO_SEGUIDOR: ; ---------------------
    CLRF BANDERA_T

    CALL SIGUE_LINEA

    BTFSC BANDERA_T, 0
    GOTO MENU

    GOTO MODO_SEGUIDOR

SIGUE_LINEA: ; ----------------------------
    ; ASUMIENDO 1 = SENSOR VE LÍNEA NEGRA
    CALL REVISA_FIN
    BTFSC BANDERA_T, 0
    RETURN

    CALL REVISA_DIRECCION
    RETURN

; Rutina para verificar si se llegó al final de la lína (encuentra una T)
REVISA_FIN:
    ; ASUMIENDO 1 = SENSOR VE LÍNEA NEGRA
    BTFSS PORTB, 0 ; si sensor izq es 0
    RETURN ; ejecuta esto
    BTFSS PORTB, 1 ; si sensor der es 0
    RETURN ; ejecuta esto

    ; si se llegó hasta acá, encontró una T, se debe frenar e ir al menú
    CALL FRENAR_MOTORES
    BSF BANDERA_T, 0
    RETURN

; Rutina para decidir dirección del carrito
REVISA_DIRECCION:
    ; ASUMIENDO 1 = SENSOR VE LÍNEA NEGRA
    BSF SENSOR_IZQ, 0
    BSF SENSOR_DER, 0

    BTFSC PORTB, 0
    CALL GIRAR_IZQ

    BTFSC PORTB, 1
    CALL GIRAR_DER

    MOVF SENSOR_IZQ, 0
    ANDWF SENSOR_DER, 0
    MOVWF W_TEMP

    BTFSC W_TEMP, 0
    CALL AVANZAR_RECTO

    RETURN

; motor izq retrocede, motor derecho avanza (Salidas viven en PuertoC)
GIRAR_IZQ:
    ; PINES 3 y 2 MOTOR IZQ
    ; PINES 1 y 0 MOTOR DER
    MOVLW b'00000110'
    MOVWF PORTC

    CLRF SENSOR_IZQ

    RETURN

; motor der retrocede, motor izq avanza (Salidas viven en PuertoC)
GIRAR_DER:
    ; PINES 3 y 2 MOTOR IZQ
    ; PINES 1 y 0 MOTOR DER
    MOVLW b'00001001'
    MOVWF PORTC

    CLRF SENSOR_DER

    RETURN

; ambos motores avanzan (Salidas viven en PuertoC)
AVANZAR_RECTO:
    ; PINES 3 y 2 MOTOR IZQ
    ; PINES 1 y 0 MOTOR DER
    MOVLW b'00001010'
    MOVWF PORTC

    RETURN

; ambos motores se detendrán, usando freno magnético (5V a todos los pines)
FRENAR_MOTORES:
    ; PINES 3 y 2 MOTOR IZQ
    ; PINES 1 y 0 MOTOR DER
    MOVLW b'00001111'
    MOVWF PORTC

    RETURN

MODO_GRABADOR:
    GOTO MENU

MODO_LECTURA:
    GOTO MENU

    END