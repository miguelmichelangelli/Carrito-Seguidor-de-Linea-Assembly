; PROGRAMA CARRITO SEGUIDOR DE LÍNEA
    LIST P=16F877A
    #include <p16f877a.inc>
    __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

    CBLOCK 0x20
        BANDERA_T
        SENSOR_IZQ
        SENSOR_DER
        W_TEMP
        TIEMPO_A
        TIEMPO_B
        ULT_MOV
    ENDC

    ; CODIFICACIÓN DE ULT_MOV
    ; 1. GIRAR IZQUIERDA -> '00000001' 
    ; 2. GIRAR DERECHA -> '00000010'
    ; 3. IR CENTRO -> '00000011'
    ; 0. FIN GRABACIÓN -> '00000000'

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

    ; ajuste de trisA | BOTONES
    BSF TRISA, 0 ; Modo 1
    BSF TRISA, 1 ; Modo 2
    BSF TRISA, 2 ; Modo 3

    ; ajuste de trisB | SENSORES
    BSF TRISB, 0 ; Sensor Izq
    BSF TRISB, 1 ; Sensor Der

    ; ajuste de trisC | MOTORES/SERVO   
    BCF TRISC, 0 ; Motor Izq
    BCF TRISC, 1
    BCF TRISC, 2 ; Motor Der
    BCF TRISC, 3
    BCF TRISC, 4 ; Servo

    ; Vuelvo al banco 0 para continuar con la lógica del PROGRAMA
    BCF STATUS, RP0

    CLRF PORTC ; Limpio el PuertoC (los motores) para evitar posibles inicios con arranques por basura en memoria

; MENÚ DE SELECCIÓN DE MODO DE OPERACION (Botones viven en PuertoA)
MENU:
    BTFSC PORTA, 0 ; Si se presiona botón 0
    GOTO MODO_SEGUIDOR ; ejecuta esto

    BTFSC PORTA, 1 ; si se presiona botón 1
    GOTO MODO_GRABADOR ; ejecuta esto

    BTFSC PORTA, 2 ; si se presiona botón 2
    GOTO MODO_LECTURA ; ejecuta esto

    GOTO MENU ; si no se presiona ninguno volver al menú

MODO_SEGUIDOR:
    CLRF BANDERA_T

    CALL SIGUE_LINEA

    BTFSC BANDERA_T, 0
    GOTO MENU

    GOTO MODO_SEGUIDOR

SIGUE_LINEA:
    CALL REVISA_FIN
    BTFSC BANDERA_T, 0
    RETURN

    CALL REVISA_DIRECCION
    RETURN
    

MODO_GRABADOR:
    MOVLW 0x30
    MOVWF FSR

BUCLE_LIMPIEZA:
    CLRF INDF

    INCF FSR, 1
    CALL REV_FIN_MEMORIA
    BTFSS STATUS, Z
    GOTO BUCLE_LIMPIEZA

; GRABACION
    MOVLW 0x30
    MOVWF FSR

    CLRF BANDERA_T

BUCLE_GRABACION:
    CALL SIGUE_LINEA

    MOVF ULT_MOV, 0
    MOVWF INDF

    BTFSC BANDERA_T, 0
    GOTO MENU

    INCF FSR

    CALL REV_FIN_MEMORIA

    BTFSS STATUS, Z
    GOTO BUCLE_GRABACION

    GOTO MENU ; si llega acá se llenó la memoria, sin encontrarse nunca una "T"

REV_FIN_MEMORIA:
    MOVLW 0x80
    SUBWF FSR, 0
    RETURN

REVISA_FIN:
    BTFSS PORTB, 0 ; si sensor izq es 0
    RETURN ; ejecuta esto
    BTFSS PORTB, 1 ; si sensor der es 0
    RETURN ; ejecuta esto

    ; si se llegó hasta acá, encontró una T, se debe frenar e ir al menú
    CALL FRENAR_MOTORES
    BSF BANDERA_T, 0
    RETURN

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
    CALL IR_CENTRO

    RETURN

; Motor Der -> ON / Motor Izq -> OFF / Servo -> Izq
GIRAR_IZQ:
    ; viven en el Puerto C
    ; Pin 0 y 1 Motor Derecho
    ; Pin 2 y 3 Motor Izquierdo
    ; Pin 4 Servomotor

    MOVLW d'1'
    MOVWF ULT_MOV

    MOVLW b'11110000' ; se apagan los motores
    ANDWF PORTC, 1

    BSF PORTC, 4 ; se pone en alto el pin del servo
    CALL RETARDO_1000USEG ; retardo de 1ms

    BCF PORTC, 4 ; se pone en bajo el pin del servo
    
    MOVLW b'00000001'
    MOVWF PORTC

    CALL RETARDO_19000USEG ; retardo de 19ms

    CLRF SENSOR_IZQ

    RETURN

; Motor Der -> OFF / Motor Izq -> ON / Servo -> Der
GIRAR_DER:
    ; viven en el Puerto C
    ; Pin 0 y 1 Motor Derecho
    ; Pin 2 y 3 Motor Izquierdo
    ; Pin 4 Servomotor

    MOVLW d'2'
    MOVWF ULT_MOV

    MOVLW b'11110000' ; se apagan los motores
    ANDWF PORTC, 1

    BSF PORTC, 4 ; se pone en alto el pin del servo
    CALL RETARDO_1000USEG ; retardo de 1ms
    CALL RETARDO_1000USEG ; retardo de 1ms

    BCF PORTC, 4 ; se pone en bajo el pin del servo

    MOVLW b'00000100'
    MOVWF PORTC

    CALL RETARDO_18000USEG ; retardo de 18ms

    CLRF SENSOR_DER

    RETURN

; Motor Der -> ON / Motor Izq -> ON / Servo -> Cen
IR_CENTRO:
    ; viven en el Puerto C
    ; Pin 0 y 1 Motor Derecho
    ; Pin 2 y 3 Motor Izquierdo
    ; Pin 4 Servomotor

    MOVLW d'3'
    MOVWF ULT_MOV

    MOVLW b'11110000' ; se apagan los motores
    ANDWF PORTC, 1

    BSF PORTC, 4 ; se pone en alto el pin del servo
    CALL RETARDO_1500USEG ; retardo de 1.5ms

    BCF PORTC, 4 ; se pone en bajo el pin del servo
    MOVLW b'00000101'
    MOVWF PORTC

    CALL RETARDO_18500USEG ; retardo de 18.5ms

    RETURN

FRENAR_MOTORES:
    MOVLW b'00001111'
    MOVWF PORTC

    RETURN