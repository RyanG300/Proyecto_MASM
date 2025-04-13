TITLE Sistema de Registro e Inicio de Sesion
INCLUDE Irvine32.inc

STD_INPUT_HANDLE            equ -10
ENABLE_MOUSE_INPUT         equ 0010h
ENABLE_EXTENDED_FLAGS      equ 0080h
FROM_LEFT_1ST_BUTTON_PRESSED equ 0001h

BUFFER_SIZE = 5000

.data
; ===================== INTERFAZ =====================
btn1_linea1 db "====================",0
btn1_linea2 db "|   Registrarse    |",0
btn1_linea3 db "====================",0

btn2_linea1 db "====================",0
btn2_linea2 db "|  Iniciar sesion  |",0
btn2_linea3 db "====================",0

btn3_linea1 db "====================",0
btn3_linea2 db "| Agregar contacto |",0
btn3_linea3 db "====================",0


msgRegistro BYTE "Haz hecho clic en REGISTRARSE", 0
msgLogin    BYTE "Haz hecho clic en INICIAR SESION", 0
msgSalir    BYTE "Saliendo del programa...", 0

hStdIn      DWORD ?
nRead       DWORD ?
ConsoleMode DWORD ?

curX WORD ?
curY WORD ?

archivoUsuarios BYTE "usuarios.txt", 0
usuario      BYTE 32 DUP(0)
password     BYTE 32 DUP(0)
barra        BYTE "|", 0
saltoLinea   BYTE 13, 10, 0
lineaFinal   BYTE BUFFER_SIZE DUP(0)
fileHandle   HANDLE ?
largo        DWORD ?
success      BYTE "Registro guardado correctamente.", 0dh,0ah,0
errorArchivo BYTE "No se pudo crear el archivo.", 0dh,0ah,0

textoUsuario  BYTE "Ingresa tu nombre de usuario: ", 0
textoPassword BYTE "Ingresa tu contrasena: ", 0

textoInicioSesion1 BYTE "Inicio de sesion exitoso.", 0
textoInicioSesion2 BYTE "Credenciales incorrectas.", 0
textoInicioSesion3 BYTE "No se pudo abrir el archivo de usuarios.", 0

txt BYTE ".txt", 0
contactos BYTE "Tus contactos:", 0
textoSinContactos BYTE "La lista de contactos del usuario esta vacia.", 0
textoUsuariosDisponibles BYTE "Usuarios disponibles:", 0
textoAgregarContacto BYTE "Escriba el nombre del usuario que desea agregar a sus contactos:", 0

lineaContacto    BYTE 64 DUP(0)     ; para nombre del contacto ingresado
archivoContacto  BYTE 64 DUP(0)     ; para "<usuario>.txt"

; === Estructura de evento mouse ===
_INPUT_RECORD STRUCT
    EventType   WORD ?
    AlignPad    WORD ?
    MouseEvent  MOUSE_EVENT_RECORD <>
_INPUT_RECORD ENDS

InputRecord _INPUT_RECORD <>

; ===================== MACROS =====================
imprime MACRO texto
    mov edx, OFFSET texto
    call WriteString
ENDM

posicionar_cursor MACRO fila, columna
    mov dh, fila
    mov dl, columna
    call Gotoxy
ENDM

; ===================== MAIN =====================
.code
main PROC
    call Clrscr
    call mostrar_menu
    call esperar_clic
    call salir
main ENDP

; ===================== MENU =====================
mostrar_menu PROC
    posicionar_cursor 10, 25
    imprime btn1_linea1
    posicionar_cursor 11, 25
    imprime btn1_linea2
    posicionar_cursor 12, 25
    imprime btn1_linea3

    posicionar_cursor 14, 25
    imprime btn2_linea1
    posicionar_cursor 15, 25
    imprime btn2_linea2
    posicionar_cursor 16, 25
    imprime btn2_linea3
    ret
mostrar_menu ENDP

esperar_clic PROC
    invoke GetStdHandle, STD_INPUT_HANDLE
    mov hStdIn, eax

    invoke GetConsoleMode, hStdIn, ADDR ConsoleMode
    mov eax, ENABLE_MOUSE_INPUT or ENABLE_EXTENDED_FLAGS
    invoke SetConsoleMode, hStdIn, eax

siguiente:
    invoke ReadConsoleInput, hStdIn, ADDR InputRecord, 1, ADDR nRead

    movzx eax, InputRecord.EventType
    cmp eax, MOUSE_EVENT
    jne siguiente

    mov eax, InputRecord.MouseEvent.dwButtonState
    and eax, FROM_LEFT_1ST_BUTTON_PRESSED
    cmp eax, FROM_LEFT_1ST_BUTTON_PRESSED
    jne siguiente

    movzx eax, InputRecord.MouseEvent.dwMousePosition.X
    mov curX, ax
    movzx eax, InputRecord.MouseEvent.dwMousePosition.Y
    mov curY, ax

    ; Validar clic en "Registrarse"
    mov ax, curY
    cmp ax, 11
    jb verificar_login
    cmp ax, 12
    ja verificar_login
    mov ax, curX
    cmp ax, 25
    jb verificar_login
    cmp ax, 44
    ja verificar_login 
    invoke SetConsoleMode, hStdIn, ConsoleMode
    jmp registro

verificar_login:
    cmp curY, 15
    jb siguiente
    cmp curY, 16
    ja siguiente
    cmp curX, 25
    jb siguiente
    cmp curX, 44
    ja siguiente
    invoke SetConsoleMode, hStdIn, ConsoleMode
    jmp login
esperar_clic ENDP

; ===================== REGISTRO =====================
registro PROC
    call Clrscr
    imprime msgRegistro
    call Crlf

    ; === Usuario ===
    mov edx, OFFSET textoUsuario
    call WriteString
    mov edx, OFFSET usuario
    mov ecx, 32
    call ReadString

    ; === Contrasena ===
    mov edx, OFFSET textoPassword
    call WriteString
    mov edx, OFFSET password
    mov ecx, 32
    call ReadString

    ; === Crear o abrir archivo usuarios ===
    mov edx, OFFSET archivoUsuarios
    call OpenOrCreateAppendFile
    mov fileHandle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je mostrarError

    ; === Concatenar usuario|password\n ===
    mov edx, OFFSET lineaFinal
    mov ecx, BUFFER_SIZE
    call LimpiarBuffer

    mov edi, OFFSET lineaFinal
    lea esi, usuario
    call ConcatStrings
    lea esi, barra
    call ConcatStrings
    lea esi, password
    call ConcatStrings
    lea esi, saltoLinea
    call ConcatStrings
    mov byte ptr [edi], 0

    mov eax, edi
    sub eax, OFFSET lineaFinal
    mov largo, eax

    mov edx, OFFSET lineaFinal
    call WriteStringToFile
    call CloseFile

    mov edx, OFFSET success
    call WriteString
    call Crlf
    ret

mostrarError:
    mov edx, OFFSET errorArchivo
    call WriteString
    call Crlf
    ret
registro ENDP

; ===================== LOGIN (aun no implementado completamente) =====================
login PROC
    call Clrscr
    imprime msgLogin
    call Crlf

    ; === Ingreso de usuario ===
    mov edx, OFFSET textoUsuario
    call WriteString
    mov edx, OFFSET usuario
    mov ecx, 32
    call ReadString

    ; === Ingreso de contrasena ===
    mov edx, OFFSET textoPassword
    call WriteString
    mov edx, OFFSET password
    mov ecx, 32
    call ReadString

    ; === Abrir archivo de usuarios ===
    mov edx, OFFSET archivoUsuarios
    invoke CreateFile, edx, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    mov fileHandle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je login_error

    ; === Leer archivo byte por byte y construir linea ===
    ; Usamos un buffer temporal y vamos comparando linea por linea
    mov esi, OFFSET lineaFinal    ; reutilizamos como buffer temporal
    mov ecx, 0                    ; contador de bytes en la linea actual

leer_loop:
    mov edx, OFFSET lineaFinal
    call ReadCharFromFile
    cmp eax, 0                    ; EOF?
    je login_fail                 ; no encontrado

     cmp al, 13
    je leer_loop         ; ignorar \r

    cmp al, 10                    ; salto de linea \n (ASCII 10)
    je verificar_linea

    ; almacenar caracter en lineaFinal
    mov [esi], al
    inc esi
    inc ecx
    jmp leer_loop

verificar_linea:
    ; cerrar cadena
    mov byte ptr [esi], 0

    ; comparar con entrada: usuario|password
    mov edi, OFFSET lineaFinal
    lea esi, usuario
    call CompararPrefijo
    cmp eax, 0
    je no_coincide

    ; comparar la parte de la contrasena
    ; edi apunta al caracter justo despues de usuario|
   
    mov edi, OFFSET lineaFinal  ;  volver a apuntar al inicio
    add edi, eax                ; saltar usuario
    inc edi                     ;saltar |
    lea esi, password           ; OK, cadena del usuario

    call StrCompare
    cmp eax, 1
    je login_ok

no_coincide:
    ; reset buffer
     mov edx, OFFSET lineaFinal
    mov ecx, BUFFER_SIZE
    call LimpiarBuffer

    mov esi, OFFSET lineaFinal
    mov ecx, 0
    jmp leer_loop

login_ok:
    imprime textoInicioSesion1
    call Crlf
    call mostrar_panel_contactos
    jmp salir


login_fail:
    imprime textoInicioSesion2
    call Crlf
    jmp fin_login

login_error:
    imprime textoInicioSesion3
    call Crlf

fin_login:
    call Crlf
    ret
login ENDP

; EDI = puntero a linea leida
; ESI = puntero a usuario ingresado
; Salida: EAX = cantidad de caracteres coincidentes si match, 0 si no

CompararPrefijo PROC
    push ebx
    xor eax, eax

cmp_loop:
    mov bl, [esi]
    cmp bl, 0
    je check_pipe

    cmp bl, [edi]
    jne fail

    inc esi
    inc edi
    inc eax
    jmp cmp_loop

check_pipe:
    cmp byte ptr [edi], '|'
    je end_cmp
fail:
    xor eax, eax
end_cmp:
    pop ebx
    ret
CompararPrefijo ENDP


; ESI y EDI apuntan a cadenas NULL-terminadas
; Retorna EAX = 1 si iguales, 0 si diferentes

StrCompare PROC
    xor eax, eax
cmp_loop:

    mov al, [esi]
    cmp al, [edi]

    jne fail_cmp
    cmp al, 0
    je iguales
    inc esi
    inc edi
    jmp cmp_loop

iguales:
    mov eax, 1
    ret

fail_cmp:
    xor eax, eax
    ret
StrCompare ENDP


ReadCharFromFile PROC
    LOCAL bytesRead:DWORD
    LOCAL oneByte:BYTE
    LOCAL hFile:DWORD
    LOCAL pBuffer:DWORD

    ; Guardar registros en variables locales correctamente
    mov eax, fileHandle
    mov [ebp-8], eax               ; hFile = fileHandle

    lea eax, oneByte
    mov [ebp-12], eax              ; pBuffer = &oneByte

    ; Llamar a ReadFile usando las variables locales
    invoke ReadFile, [ebp-8], [ebp-12], 1, ADDR bytesRead, 0

    ; Verificar si se leyo algo
    cmp bytesRead, 0
    je eof

    movzx eax, oneByte
    ret

eof:
    xor eax, eax
    ret
ReadCharFromFile ENDP

mostrar_panel_contactos PROC
    call Clrscr

    ; Mostrar titulo
    posicionar_cursor 1, 2
    imprime contactos

    ; Construir nombre del archivo de contactos (usuario.txt)
    mov edx, OFFSET lineaFinal
    mov ecx, BUFFER_SIZE
    call LimpiarBuffer

    mov edi, OFFSET lineaFinal
    lea esi, usuario
    call ConcatStrings
    lea esi, txt
    call ConcatStrings

    ; Abrir archivo de contactos
    mov edx, OFFSET lineaFinal
    invoke CreateFile, edx, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    mov fileHandle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je contactos_vacios

    ; Leer linea por linea (contactos)
    mov esi, OFFSET lineaFinal
    mov ecx, 0
    mov bh, 3                 ; fila inicial para imprimir

leer_contactos:
    call ReadCharFromFile
    cmp eax, 0
    je fin_contactos

    cmp al, 13
    je leer_contactos
    cmp al, 10
    je imprimir_contacto

    mov [esi], al
    inc esi
    jmp leer_contactos

imprimir_contacto:
    mov byte ptr [esi], 0
    posicionar_cursor bh, 2
    mov edx, OFFSET lineaFinal
    call WriteString
    inc bh
    mov esi, OFFSET lineaFinal
    jmp leer_contactos

contactos_vacios:
    posicionar_cursor 3, 2
    imprime textoSinContactos
    jmp mostrar_boton

fin_contactos:
    call CloseFile
    mov fileHandle, 0


mostrar_boton:
    ; Boton Agregar contacto a la derecha
    posicionar_cursor 4, 75
    imprime btn3_linea1
    posicionar_cursor 5, 75
    imprime btn3_linea2
    posicionar_cursor 6, 75
    imprime btn3_linea3

    call esperar_clic_agregar_contacto
    ret
mostrar_panel_contactos ENDP


esperar_clic_agregar_contacto PROC
    invoke GetStdHandle, STD_INPUT_HANDLE
    mov hStdIn, eax

    invoke GetConsoleMode, hStdIn, ADDR ConsoleMode
    mov eax, ENABLE_MOUSE_INPUT or ENABLE_EXTENDED_FLAGS
    invoke SetConsoleMode, hStdIn, eax


nuevamente:
    invoke ReadConsoleInput, hStdIn, ADDR InputRecord, 1, ADDR nRead

    movzx eax, InputRecord.EventType
    cmp eax, MOUSE_EVENT
    jne nuevamente

    mov eax, InputRecord.MouseEvent.dwEventFlags
    cmp eax, 0
    jne nuevamente

    mov eax, InputRecord.MouseEvent.dwButtonState
    and eax, FROM_LEFT_1ST_BUTTON_PRESSED
    cmp eax, FROM_LEFT_1ST_BUTTON_PRESSED
    jne nuevamente

    movzx eax, InputRecord.MouseEvent.dwMousePosition.X
    mov curX, ax
    movzx eax, InputRecord.MouseEvent.dwMousePosition.Y
    mov curY, ax

    ; Detectar clic en boton (lineas 4 6, columnas 60 80)
    mov ax, curY
    cmp ax, 4
    jb nuevamente
    cmp ax, 6
    ja nuevamente

    mov ax, curX
    cmp ax, 75
    jb nuevamente
    cmp ax, 95
    ja nuevamente

    ; clic confirmado
    invoke SetConsoleMode, hStdIn, ConsoleMode
    jmp agregar_contacto
esperar_clic_agregar_contacto ENDP



agregar_contacto PROC
    call Clrscr
    imprime textoUsuariosDisponibles
    call Crlf

    ; Abrir usuarios.txt y mostrar lista
    mov edx, OFFSET archivoUsuarios
    invoke CreateFile, edx, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    mov fileHandle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je salir

    ; ?? LIMPIAMOS registros antes de empezar a procesar usuarios
    xor esi, esi
    xor edi, edi
    xor eax, eax

    mov esi, OFFSET lineaFinal
    mov ecx, 0
    mov bh, 2


leer_usuarios:
    call ReadCharFromFile
    cmp eax, 0
    je solicitar_usuario

    cmp al, 13
    je leer_usuarios
    cmp al, 10
    je procesar_usuario

    mov [esi], al
    inc esi
    jmp leer_usuarios

procesar_usuario:
    mov byte ptr [esi], 0

    ; Limpiar registros antes de manipular datos en lineaFinal
    xor edi, edi
    mov edi, OFFSET lineaFinal

buscar_pipe:
    mov al, [edi]
    cmp al, '|'
    je encontrado_pipe
    cmp al, 0
    je omitir_linea
    inc edi
    jmp buscar_pipe

encontrado_pipe:
    mov byte ptr [edi], 0

    xor eax, eax       ; Pone EAX = 0

    ; Comparar con el usuario actual
    lea esi, usuario
    lea edi, lineaFinal
    call StrCompare
    cmp eax, 1
    je omitir_linea

    ; Imprimir si es distinto
    posicionar_cursor bh, 2
    mov edx, OFFSET lineaFinal
    call WriteString
    inc bh

omitir_linea:

    xor esi, esi       ; Pone ESI = 0
    xor edi, edi       ; Pone EDI = 0
    xor eax, eax       ; Pone EAX = 0

    mov esi, OFFSET lineaFinal
    jmp leer_usuarios

solicitar_usuario:
    call CloseFile
    mov fileHandle, 0
    call Crlf
    imprime textoAgregarContacto
    call Crlf

     ; ?? Limpiar registros antes de preparar buffers
    xor esi, esi
    xor edi, edi
    xor eax, eax
    xor edx, edx

    mov edx, OFFSET lineaContacto
    mov ecx, BUFFER_SIZE
    call LimpiarBuffer

    mov edx, OFFSET lineaContacto
    mov ecx, 32
    call ReadString

    ; Limpiar espacios finales del nombre ingresado
    mov edx, OFFSET lineaContacto
    mov ecx, BUFFER_SIZE
    call TrimTrailingSpaces

    ; Concatenar salto de linea
    mov edi, OFFSET lineaContacto
    call buscar_final_contacto
    lea esi, saltoLinea
    call ConcatStrings

    xor edx, edx

    ; Construir nombre del archivo: usuario.txt ? en archivoContacto
    mov edx, OFFSET archivoContacto
    mov ecx, 64
    call LimpiarBuffer

    lea edi, archivoContacto
    lea esi, usuario
    call ConcatStrings
    lea esi, txt
    call ConcatStrings

    ; calcular longitud real sin Str_length
    ;mov eax, edi
    ;sub eax, OFFSET archivoContacto
    ;mov largo, eax

    ; Abrir o crear archivo y guardar contacto
    mov edx, OFFSET archivoContacto
    call OpenOrCreateAppendFile
    mov fileHandle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je error_crear_archivo

    push edi
    ; === Calcular largo del contenido a escribir (lineaContacto) ===
    mov edi, OFFSET lineaContacto         ; edi apunta al inicio
    call buscar_final_contacto            ; mueve edi al final
    mov eax, edi
    sub eax, OFFSET lineaContacto
    mov largo, eax  
    pop edi

    mov edx, OFFSET lineaContacto  
    call WriteStringToFile
    call CloseFile
    mov fileHandle, 0


    jmp salir

error_crear_archivo:

    posicionar_cursor 20, 2
    imprime errorArchivo
    call Crlf
    jmp salir


agregar_contacto ENDP


buscar_final_contacto PROC
    push eax
buscar:
        mov al, [edi]
        cmp al, 0
        je listo
        inc edi
        jmp buscar
listo:
    pop eax
    ret
buscar_final_contacto ENDP


; EDX = puntero a la cadena terminada en NULL
TrimTrailingSpaces PROC
    push eax
    push ecx
    push edi

    mov edi, edx         ; puntero a la cadena original

buscar_final:
    mov al, [edi]
    cmp al, 0
    je retroceder
    inc edi
    jmp buscar_final

retroceder:
    dec edi              ; ir al ultimo caracter real

recortar:
    mov al, [edi]
    cmp al, ' '          ; si es espacio
    je borrar
    cmp al, 13           ; si es '\r'
    je borrar
    cmp al, 10           ; si es '\n'
    je borrar
    jmp fin              ; si no es ninguno, fin

borrar:
    mov byte ptr [edi], 0
    dec edi
    jmp recortar

fin:
    pop edi
    pop ecx
    pop eax
    ret
TrimTrailingSpaces ENDP


; ===================== UTILIDADES =====================
salir PROC
    call Crlf
    mov edx, OFFSET msgSalir
    call WriteString
    call Crlf
    exit
salir ENDP

; ==== UTILIDADES: ABRIR ARCHIVO ====
OpenOrCreateAppendFile PROC
    push edx

    invoke CreateFile, edx, GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    mov ebx, eax
    cmp eax, INVALID_HANDLE_VALUE
    je fin
    invoke SetFilePointer, ebx, 0, 0, FILE_END
    mov eax, ebx
fin:
    pop edx
    ret
OpenOrCreateAppendFile ENDP

WriteStringToFile PROC
    push eax
    push ecx

    cmp fileHandle, 0
    je salir ; evita usar handle nulo

    cmp fileHandle, INVALID_HANDLE_VALUE
    je salir

    mov ecx, largo
    mov eax, fileHandle
    cmp fileHandle, 0
    je fin ;Mejor salta a una etiqueta local dentro de la misma función

    ; si fileHandle es valido, continua con WriteToFile
    mov ecx, largo
    mov eax, fileHandle
    call WriteToFile

fin:
    pop ecx
    pop eax
    ret

WriteStringToFile ENDP

ConcatStrings PROC
    push eax
    push ecx
    push edx
buscar_final:
    mov al, [edi]
    cmp al, 0
    je copiar
    inc edi
    jmp buscar_final
copiar:
    mov al, [esi]
    mov [edi], al
    cmp al, 0
    je fin
    inc edi
    inc esi
    jmp copiar
fin:
    pop edx
    pop ecx
    pop eax
    ret
ConcatStrings ENDP

LimpiarBuffer PROC
    push eax
    push edi
    mov edi, edx
    mov al, 0
    rep stosb
    pop edi
    pop eax
    ret
LimpiarBuffer ENDP

END main
