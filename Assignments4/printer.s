extern printf
extern nextCor
extern firstDrone
extern x_target
extern y_target
extern activeDrones
extern N

global printer

section .rodata
    TargForma: db "%.2f, %.2f",10,0
    DronForm: db "%d, %.2f, %.2f, %.2f, %.2f, %d",10,0 ;; id, x, y, alpha, speed, hits
    NUMform: db "we got to: %d and c = %d",10,0
section .data
    tmp: dd 0
    c: dd 0
    x: dd 0
section .text

%macro debug 0
    pushad
    push dword[c]
    push dword[activeDrones]
    push NUMform
    call printf
    add esp,8
    inc dword[c]
    popad
%endmacro

printer:
    dec dword[x]
    push dword[x_target+4] ;; push a qword
    push dword[x_target]
    push dword[y_target+4] ;; push a qword
    push dword[y_target]
    push TargForma
    call printf
    add esp,20
    mov ebx,[firstDrone]
    finit

printDrones:
    push ebx
    cmp ebx,0 ;; finish
    je stopPrint
    jmp DoPrint

DoPrint:
    pop ebx
    mov eax,0
    mov al,byte[ebx+25] ;;targets hit
    push eax 

    fld qword[ebx+31]
    sub esp,8
    fstp qword[esp]

    fld qword[ebx+17];;the alpha drone
    sub esp,8
    fstp qword[esp]

    fld qword[ebx+9];;the y drone
    sub esp,8
    fstp qword[esp]

    fld qword[ebx+1];; the x drone
    sub esp,8
    fstp qword[esp]

    mov eax,0
    mov al,byte[ebx]
    push eax ;; ID
    
    mov dword[tmp],ebx
    push DronForm
    call printf

    add esp, (4*11)

    mov ebx,dword[tmp]
    mov ebx,[ebx+26]
    jmp printDrones

stopPrint:
    mov ebx,0 ;; scheduler is cor 0
    call nextCor
    jmp printer

