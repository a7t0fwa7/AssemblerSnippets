includelib  "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.19041.0\um\x64\ws2_32.lib"
includelib  "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.19041.0\um\x64\user32.lib"
includelib  "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.19041.0\um\x64\kernel32.lib"

.data

EXTERN socket: PROC
EXTERN WSAStartup: PROC
EXTERN connect: PROC
EXTERN send: PROC
EXTERN closesocket: PROC
EXTERN WSACleanup: PROC
EXTERN htons: PROC
EXTERN inet_addr: PROC
EXTERN GetLastError: PROC
EXTERN MessageBoxA: PROC
EXTERN ExitProcess: PROC

AF_INET equ 2
SOCK_STREAM equ 1
IPPROTO_TCP equ 6

WSADATA STRUCT
    wVersion dw ?
    wHighVersion dw ?

    iMaxSockets dw ?
    iMaxUdpDg dw ?
    lpVendorInfo qword ptr ?

    szDescription db ?
    szSystemStatus db ?
WSADATA ENDS

SOCKADDR_IN STRUCT
    sin_family dw 0
    sin_port dw 0
    sin_addr dd 0  ;I am ignoring in_addr structure, normally the result of inet_addr goes here in memory. this workaround works.
    sin_zero db 0,0,0,0,0,0,0,0
SOCKADDR_IN ENDS

errorMsg db 'Socket error!', 0
errorCode dd 0

localhst db '127.0.0.1', 0

_socket dq 0
_server_addr SOCKADDR_IN <0,0>

_send_data db 'Hello, World!',0
_send_length = ($ - _send_data)
_send_ret_val dd 0

_wsaData WSADATA <0,0,0,0,0>

.code

PrintError PROC

    sub rsp, 28h

    call GetLastError
    mov errorCode, eax

    mov rcx, 0
    lea rdx, [errorMsg]
    xor r8d, r8d
    call MessageBoxA
    add rsp, 28h
    ret
PrintError ENDP

;Please pass a WSAData structure as rdx! 
InitializeWinsock PROC

    ; Initialize Winsock
    sub rsp, 28h
    mov rcx, 000000000000202h
    call WSAStartup
    add rsp, 28h
    ret

InitializeWinsock ENDP

CreateTCPSocket PROC

    sub rsp, 28h
    ; Create a socket
    xor eax, eax
    mov rcx, AF_INET
    mov rdx, SOCK_STREAM  
    mov r8, IPPROTO_TCP
    call socket
    add rsp, 28h
    ret
CreateTCPSocket ENDP

sendPacket PROC
    
    sub rsp, 28h
    

    lea rdx, offset [_wsaData]
    call  InitializeWinsock

    cmp eax, 0
    jne failed

    call CreateTCPSocket
   
    cmp eax, 00000000FFFFFFFFh
    je failed

    mov _socket, rax

    ; Connect to the server
    mov rcx, 5445
    call htons

    cmp eax, 00000000FFFFFFFFh
    je failed
    
    mov [_server_addr.sin_port], ax
    
    mov rcx, offset localhst
    call inet_addr
    
    cmp eax, 00000000FFFFFFFFh
    je failed
    
    mov [_server_addr.sin_addr], eax
    mov [_server_addr.sin_family], AF_INET

    lea edx, [_server_addr]
    mov rcx, _socket
    mov r8, sizeof _server_addr
    call connect

    cmp eax, 00000000FFFFFFFFh
    je failed

    ; Send data
    mov rcx, _socket
    lea rdx, [_send_data]
    mov r8, _send_length
    xor r9d,r9d
    call send

    cmp eax, 00000000FFFFFFFFh
    je failed

    mov _send_ret_val, eax

    ; Cnup
    xor eax, eax
    mov rcx, _socket
    call closesocket
    
    cmp eax, 00000000FFFFFFFFh
    je failed

    ; Terminate Winsock
    xor eax, eax
    mov ecx, offset _wsaData
    call WSACleanup

    cmp eax, 00000000FFFFFFFFh
    je failed

    xor rax, rax
    mov eax, _send_ret_val
    add rsp, 28h
    ret

failed:
    call PrintError
    add rsp, 28h
    mov rax, 00000000FFFFFFFFh
    ret

sendPacket ENDP


WinMainCRTStartup PROC

	sub		rsp,28h			; shadow space, aligns stack

	call	sendPacket

	; When the message box has been closed, exit the app with exit code eax
	mov		ecx,eax
	call	ExitProcess  ; close process with return code from our sendPacket function

WinMainCRTStartup ENDP

End
         
