global startCo
global Randomy
global nextCor
global k;; for the scheduler
global N;; for the scheduler
global R
global d
global changeTheTarget
global firstDrone
global lastDrone
global x_target
global y_target
global lfsr
global startState
global curr_cor
global endCo
global droneCor

extern scheduler ;; the main function for the scheduler
extern drones ;; the main function for the drones
extern printer ;; the main function in the printer
extern createTarget


section .data
    droneID: db 0
    index: dd 0
    struc drone
        id: resb 1 
        x: resw 4 ;; 1
        y: resw 4 ;; 9
    endstruc

    here: db "here",10,0
    lfsr: dd 0
    startState: dw 0
    counter: dd 0
    x_target: dq 0
    y_target: dq 0
    val87: dq 0
    targetFormat: db "%.2f, %.2f",10,0
    pos: dd 0
    
section	.rodata
    align 16 
    
    errorIn: db "Sorry user,You should put 6 args but recieved:-> %d",10,0
    sscanfRead: db "%d" ,0
    nums: db "%d",10,0

section .bss
    N: resd 1
    tmpN: resd 1
    R: resd 1
    k: resd 1
    d: resd 1
    seed: resd 1
    mainSP: resd 1
    curr_cor: resd 1
    stcksz: equ 16*1024
    droneCor: resd 1
    cors: resd 10000 
    stacks: resb 10000 * stcksz
    stateNumber: resb 16
    mulNumber: resb 4
    firstDrone: resb 4
    lastDrone: resb 4 

section .text
    align 16
    global main
    extern malloc
    extern calloc
    extern free
    extern printf
    extern sscanf
    extern sscanf


%macro sscanfCall 0
    push sscanfRead
    push eax
    call sscanf
    add esp,12
%endmacro

%macro looplfsr 0
    mov eax,0
    mov ebx,0
    mov ax,[lfsr];;16 byte
    mov bx,[lfsr]
    shr ax,2
    mov ecx,0
    mov cx,ax
    mov ax,[lfsr]
    shr ax,3
    mov edx,0
    mov dx,ax
    mov ax,[lfsr]
    shr ax,5
    xor bx,cx
    xor bx,dx
    xor bx,ax
    and bx,1
    mov ax,0
    mov ax,[lfsr]
    shr ax,1
    shl bx,15
    or ax,bx
    mov [lfsr],ax
%endmacro

%macro addDrone 0+
    cmp dword[firstDrone],-1 ;;the first drone
    je %%_firstDrone
    mov ebx, [lastDrone]
    mov [ebx + 26],eax
    mov [lastDrone], eax
    jmp %%end
    %%_firstDrone:
        mov [firstDrone], eax
        mov [lastDrone], eax
    %%end:
%endmacro

%macro FreeD 0+
    mov ebx,[firstDrone]
    %%loopFree:
        mov eax,[ebx+26]
        mov dword[lastDrone],eax
        push ebx
        call free
        add esp,4
        cmp dword[lastDrone],0
        je %%end
        mov ebx,dword[lastDrone]
        jmp %%loopFree
    %%end:
%endmacro

errorInput:
    push eax
    push errorIn
    call printf
    mov eax,1
    mov ebx,0
    int 0x80


main:
    mov eax,[esp+4] ;; argc
    cmp eax,7
    jne errorInput
    mov esi,[esp+8] ;; argv**
    mov dword[index], 1 ;; the argv[1] is ./ass3

    mov ecx,dword[index]
    mov eax, [esi+ 4*ecx]
    push N
    sscanfCall

    inc dword[index]
    mov ecx,dword[index]
    mov eax, [esi+ 4*ecx]
    push R
    sscanfCall


    inc dword[index]
    mov ecx,dword[index]
    mov eax, [esi+ 4*ecx]
    push k
    sscanfCall


    inc dword[index]
    mov ecx,dword[index]
    mov eax, [esi+ 4*ecx]
    push d
    sscanfCall

    
    inc dword[index]
    mov ecx,dword[index]
    mov eax, [esi+ 4*ecx]
    push seed
    sscanfCall
    mov ax,word[seed]
    mov word[startState],ax


    mov ebx,0 ;; we consider the scheduler as co-routine 0 so we need to instantiate it by calling the beganCo from the prac session
    push ebx
    mov edx, scheduler
    call beganCo ;;which is a func
    pop ebx

    inc ebx ;; this co_routine is for the printer = 1
    mov edx,printer
    push ebx
    call beganCo
    pop ebx

    inc ebx ;; and finally we will amke the target as co_routine 2
    push ebx
    mov edx, createTarget
    call beganCo
    pop ebx
    
    finit       ;;initialize the x87 thing
    mov dword[stateNumber],65535
    mov dword[mulNumber],100
    mov dword[firstDrone],-1
    mov dword[lastDrone],0
    call changeTheTarget

    call createDrones

changeTheTarget:
    call Randomy
    mov ax,[lfsr] ;; save the new random number
    mov [startState],ax

    ;;the x coordinate of the target
    fild dword[lfsr]
    fidiv dword[stateNumber]
    fimul dword[mulNumber]
    fstp qword[x_target]

    ;; now we will do the same thing for the y coordinate
    call Randomy
    mov ax,[lfsr] ;; save the new random number
    mov [startState],ax

    fild dword[lfsr]
    fidiv dword[stateNumber]
    fimul dword[mulNumber]
    fstp qword[y_target]
    ret

createDrones:

    ;;struct size is 17 bytes == 68 bits
    mov byte[droneID],1
    mov eax,dword[N]
    mov dword[tmpN],eax
    .droneloop:
        cmp dword[tmpN],0
        je InitilizedRou

        push 39
        call malloc
        add esp,4
        mov cl,byte[droneID]
        mov byte[eax],cl ;; the first byte in the struct is the id
        mov byte[eax + 25],0 ;;the hit targets
        mov dword[eax + 26],0 ;; this drone is the last drone in the current list
        mov dword[eax + 30],1 ;; the drone is not dead yet
        mov dword[eax + 31],0 ;; initial speed
        mov dword[eax + 35],0
        inc byte[droneID]
            ;;calc the initial x coordinate of the drone
        push eax
        call Randomy
        
        fild dword[lfsr]
        fidiv dword[stateNumber]
        fimul dword[mulNumber]
        fstp qword[val87] ;; fstp return qword
        mov ebx,dword[val87]
        pop eax
        mov dword[eax + 1],ebx
        mov ebx,dword[val87+4]
        mov dword[eax + 5],ebx
        ;;calc the initial y coordinate of the drone
        push eax
        call Randomy
        pop eax
        
        fild dword[lfsr]
        fidiv dword[stateNumber]
        fimul dword[mulNumber]
        fstp qword[val87] ;; fstp return qword
        mov ebx,dword[val87]
        mov dword[eax + 9],ebx        
        mov ebx,dword[val87+4]
        mov dword[eax + 13],ebx
        ;;calc the initial alpha of the drone
        push eax
        call Randomy
        pop eax
        mov dword[mulNumber],360 ;;for the alpha --> radian
        fild dword[lfsr]
        fidiv dword[stateNumber]
        fimul dword[mulNumber]
        mov dword[mulNumber],100
        fstp qword[val87] ;; fstp return qword
        mov ebx,dword[val87]
        mov dword[eax + 17],ebx
        mov ebx,dword[val87+4]
        mov dword[eax+21],ebx
        addDrone
        dec dword[tmpN]
        jmp .droneloop

Randomy:
    push ebp
    pushad
    pushf
    mov ebp,esp

    mov dword[counter],2
    mov eax,0
    mov ax,word[startState]
    mov [lfsr],ax

    .looplfsr:
        looplfsr
        dec dword[counter]
        cmp dword[counter],0
        jne .looplfsr

    mov ax,[lfsr]
    mov [startState],ax
    popf
    popad
    pop ebp
    ret

beganCo:
    push edx ;; here the edx is the retun address like scheduler and printer ...
    ;;ebx is the core ID
    mov edx,0
    mov eax, stcksz
    mul ebx
    pop edx ;; restore the retun address afher the mul

    add eax, stacks + stcksz ;; here after we got the eaxt to points to the statr of the wanted stack, we move it to the end of it so that he would be ready for use as a regualr stack
    mov [cors + 4*ebx],eax;; save the top of the stack in it's array
    mov dword[mainSP],esp
    mov esp,eax
    push edx;; the return address
    pushf
    pushad
    mov [cors +ebx*4],esp ;;update the cor esp
    mov esp,dword[mainSP]
    ret

endCo:
    mov esp,[mainSP]
    popad 
    ret
    
nextCor: ;; ebx holds the next Cor
    pushfd
    pushad
        ; debug ebx
    mov edx,[curr_cor]
    mov [droneCor],edx
    mov [cors+4*edx],esp ;; save the stack top of the last used one
    .do_nextCor:
        mov esp,[cors + ebx*4]
        mov [curr_cor],ebx
        popad
        popfd
        ret
    
InitilizedRou:
    
    mov esi,0
    mov eax,dword[N]
    mov dword[tmpN],eax
    
    .cores:
        cmp dword[tmpN],0
        je .endOfTheGameDrones ;; here we need to exit totally
    .BeganDrones:
        mov edx, drones
        mov ebx,3 ;; because the first thre co-routines are the schedulet, printer nad target
        add ebx,esi ;; esi iterates through all the drones 
        call beganCo
        inc esi
        dec dword[tmpN]
        jmp .cores

    .endOfTheGameDrones:
        mov ebx,0 ;; after creating everything start the scheduler
        pushad 
        mov [mainSP],esp
        mov [curr_cor],ebx ;;store the current co-routine
        jmp nextCor.do_nextCor

end_program: 
    FreeD
    mov eax,1
    mov ebx,0
    int 0x80
    nop
