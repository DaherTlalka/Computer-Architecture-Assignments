global scheduler
global activeDrones
global drn

extern startCo
extern endCo
extern nextCor
extern k
extern N
extern R
extern printf
extern firstDrone
extern lastDrone

section .data
    activeDrones: dd 0
    liiterKilles: dd 0
    drn: dd 0
    x: dd 90
section .rodata
    Result: db " The Winner is drone: %d",10,0
    noWinner: db " We cant find any Winner!!!",10,0
    str: db "here: %d",10,0
section .text

scheduler:

    mov ecx,dword[N]
    mov [activeDrones],ecx

    mov ebx,1
    call nextCor
    mov ecx,0 ;; counter for the k
    mov edx,0 ;; counter for the R
    inc ebx
_scheduler:

    inc ebx
    inc ecx
    inc edx
    call nextCor
    cmp ecx,dword[k]
    jb noPrint
    push ebx
    mov ebx,1 ;;printed cor
    call nextCor
    pop ebx
    mov ecx,0
noPrint:
    mov esi,edx ;; esi = i
    pushad
    mov eax,edx ;; ecx = i
    mov ecx,[N]
    mov edx,0 
    div ecx     ;; eax = i/N
    ; mov ebx,eax
    cmp eax,0
    je nextCheck ;; if (i/N) = 0 ,no need to check the i/N % R because it is always  = 0
    mov edx,0
    mov ebx,[R]
    div ebx     ;; (i/N) % R = edx
    cmp edx,0
    jne noElimination
nextCheck:
    mov eax,esi 
    mov ecx,[N]
    mov edx,0
    div ecx
    cmp edx,0 ;; edx = i % (N)
    jne noElimination
    popad 
    mov edx,0 ;; start another round
    pushad
    call Elione
    dec dword[activeDrones]
noElimination:
    popad
    cmp dword[activeDrones],1
    je Winner
    call checkNextAlive
    mov eax,0
    mov al,byte[ebx];; eax = drone ID
    mov ebx,eax
    add ebx,2
    cmp eax,[N]
    je here
    jmp _scheduler
here:
    mov ebx,2
    jmp _scheduler


checkNextAlive:
    mov eax,ebx
    sub eax,2 ;; suppouse current drone
    mov ebx,[firstDrone]
    .searching:
        cmp al,byte[ebx]
        je .livecheck
        mov ebx,dword[ebx+26]
        jmp .searching
    .livecheck:
        cmp byte[ebx+30],1
        je .counter
        mov ebx,dword[ebx+26]
        cmp ebx,0
        jne .livecheck
        mov ebx,[firstDrone]
        jmp .livecheck
    .counter:
        mov dword[drn],ebx

    ret
    
Winner:
    mov ebx,[firstDrone]
        
    .WinnerLop:
        cmp byte[ebx+30],0 ;; 0 indicated is the drone is dead
        jne printTheWinner
        cmp dword[ebx+26],0
        je nowinner
        mov ebx,[ebx+26]
    jmp .WinnerLop

    

printTheWinner:
    mov eax,0
    mov al,byte[ebx]
    push eax
    push Result
    call printf
    add esp,8
    call endCo

nowinner:
    push noWinner
    call printf
    add esp,4
    call endCo

Elione:
    push ebp
    mov ebp,esp
    pushad
    mov ebx,[firstDrone]
    mov [lastDrone],ebx

FirAlive:
    cmp byte[ebx+30],1
    je .foundOne
    mov ebx,[ebx+26];; if this drone is dead move to the next one
    jmp FirAlive
    .foundOne:
        mov eax,0
        mov al,byte[ebx+25]
        mov dword[liiterKilles],eax ;; the starting point 
        mov [lastDrone],ebx ;; lastDrone holds the drone to be destroyed
        mov ebx,[ebx+26]
    .searchMin:
        cmp byte[ebx+30],1 
        je .cmpMin  ;; if this drone is not dead
    .counterSeach:
        cmp dword[ebx+26],0
        je .finishSearching ;; we got to the end of the drones list
        mov ebx,[ebx+26] ;; move next
        jmp .searchMin

    .cmpMin: 
        mov eax,0
        mov al,byte[ebx+25] ;; check if we have a new min
        cmp eax,dword[liiterKilles]
        ja .counterSeach
        mov dword[liiterKilles],eax
        mov [lastDrone],ebx
        jmp .counterSeach

    .finishSearching: 
        mov ebx,[lastDrone]
        mov byte[ebx+30],0
        
    popad
    pop ebp
    ret