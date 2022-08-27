extern createTarget
extern x_target
extern y_target
extern Randomy
extern lfsr
extern  startState
extern nextCor
extern curr_cor
extern firstDrone
extern printf
extern d
extern drn

global drones

section .bss
    stateNumber: resb 16
    multTheNumbers: resb 4
    oldAlf: resq 1
    oldSpd: resd 2
    cordenant: resq 1
    rad: resq 1
    clamp: resd 1

section .data
    delta_alpha: dq 0.0
    speedChanged: dq 0
    alignment: dd 0
    val87: dq 0
    x: dd 160
    temp: dq 0

section .rodata
    error: db "Drone not found",10,0
    here: db "here: %d",10,0
    ffor: db "%f",10,0

section .text

%macro calcBounds 0
    mov dword[clamp],100 ;;the board limits

    fild dword[clamp]
    fcomi st0, st1 ;; st0 = 100 and st1 = new X
    ja %%dontWorbIflessTheneZero
    fsubp
    fst qword[cordenant]
    fstp qword[val87]
        
    jmp %%end
    %%dontWorbIflessTheneZero:
        fstp qword[val87];; pop the 100
        mov dword[clamp],0
        fild dword[clamp]
        fcomi
        jb %%dontWrap
        faddp
        mov dword[clamp],100
        fild dword[clamp]
        faddp
        fst qword[val87]
        fst qword[cordenant]
        jmp %%end
    %%dontWrap:
        fstp qword[val87];; take out the 0 we pushed in

        fst qword[val87]
    %%end:
%endmacro

%macro debug 1
    cmp dword[x],0
    je %%dont
    dec dword[x]
    pushad
    push %1
    push here
    call printf
    add esp,8
    popad
%%dont:
%endmacro

%macro droneID 0
    push eax
    mov eax,0
    mov al,byte[ebx]
        debug eax
    pop eax
%endmacro

%macro posSpeed 2
        cmp dword[x],0
        je %%dont
        dec dword[x]
        push %2
        push %1
        push ffor
        call printf
        add esp,12
%%dont:
%endmacro

drones:
    finit

        ; debug dword[curr_cor]
    
    mov eax,0
    mov ebx, [firstDrone]
    mov al,byte[ebx]
    add eax,2

    cmp eax,dword[curr_cor]
    je FoundTarget
nextDrone:
    mov ebx,dword[ebx+26] ;; next drone
    cmp ebx,0
    je NotFound
    mov eax,0
    mov al,byte[ebx]
    add eax,2
    cmp eax,dword[curr_cor]
    je FoundTarget
    jmp nextDrone
FoundTarget:
    mov dword[drn],ebx ;; drn point to the drone for further use
    call randomAlpha
    call speedChange
    call newPos
    call mayDead

    

randomAlpha:
    push ebp
    mov ebp,esp

    call Randomy
    mov ax,word[lfsr]
    mov word[ startState],ax
        ; debug dword[ startState]
    mov dword[stateNumber],65535
    mov dword[multTheNumbers],120
    fild dword[lfsr]
        ; debug dword[lfsr]
    fidiv dword[stateNumber]
    fimul dword[multTheNumbers]
    mov dword[alignment],60
    fisub dword[alignment]
    fstp qword[delta_alpha]

    mov esp,ebp
    pop ebp
    ret

speedChange:
    push ebp
    mov ebp,esp

    call Randomy
    mov ax,word[lfsr]
    mov word[ startState],ax
    mov dword[stateNumber],65535
    mov dword[multTheNumbers],20
    fild dword[lfsr]
    fidiv dword[stateNumber]
    fimul dword[multTheNumbers]
    mov dword[alignment],10
    fisub dword[alignment]
    fstp qword[speedChanged]
    mov esp,ebp
    pop ebp
    ret

newPos:
    push ebp
    mov ebp,esp
    mov eax, dword[ebx+17]
    mov dword[oldAlf],eax
    mov eax,dword[ebx+21]
    mov dword[oldAlf+4],eax
    mov eax,dword[ebx+31]
    mov dword[oldSpd],eax
    mov eax,dword[ebx+35]
    mov dword[oldSpd+4],eax

calcX:
    fld qword[oldAlf]
        ; posSpeed dword[oldAlf],dword[oldAlf+4]
    fldpi
        ; posSpeed dword[oldAlf],dword[oldAlf+4]
    fmulp
    mov dword[multTheNumbers],180
    fidiv dword[multTheNumbers] ;; fidiv replaces the st0
        ; posSpeed dword[rad],dword[rad+4]
    fcos
        ; fst qword[temp]
        ; posSpeed dword[temp],dword[temp+4]
    fld qword[oldSpd]
    fmulp
    fld qword[ebx+1]
    faddp ;; add the x to the oldSpeed * cos(alpha) 
        ; fst qword[temp]
        ; posSpeed dword[temp],dword[temp+4]
    calcBounds
    fstp qword[ebx+1]
    
calcY:
    fld qword[rad]
    fsin
    fld qword[oldSpd]
    fmulp
    fld qword[ebx+9]
    faddp        ;; calc the new y position
    calcBounds
    fstp qword[ebx+9]



SaveTheUpdetAlfa:
        ; posSpeed dword[delta_alpha],dword[delta_alpha+4]
        ; posSpeed dword[oldAlf],dword[oldAlf+4]
    fld qword[oldAlf]
    fadd qword[delta_alpha]
    mov dword[clamp],360
    fild dword[clamp]
    fcomi st0, st1
    ja checkAlphaLessthenZero
    fsubp
    fst qword[val87]
    fstp qword[ebx+17]
    jmp changeSpeed
checkAlphaLessthenZero:
    fstp qword[temp];; make st0 = 0

    mov dword[temp],0
    fild dword[temp]
    fcomi st0, st1
    jb dontDoAThing
    fiadd dword[clamp] 
    faddp
    fst qword[val87]
    fstp qword[ebx+17] ;; new alpha
    jmp changeSpeed
dontDoAThing:
    faddp
    fstp qword[ebx+17]

changeSpeed:
    fld qword[speedChanged]
    fadd qword[ebx+31]
    mov dword[clamp],100
    fild dword[clamp]
    fcomi st0, st1
    ja dontCutYet
    fst qword[val87] ;; speed = 100
    fstp qword[ebx+31]
    jmp newPose
dontCutYet:
    fisub dword[clamp]
    fcomi st0, st1
    jb speedChangedy
    fst qword[val87] ;; the speed is Zero
    fstp qword[ebx+31]
        ; posSpeed dword[ebx+31],dword[ebx+35]
    fstp qword[val87] ;; clear the x87 stack
        ; posSpeed dword[val87],dword[val87+4]
    jmp newPose
speedChangedy:
    faddp
    fst qword[val87] ;; save the new speed
        ; posSpeed dword[val87],dword[val87+4]
    fstp qword[ebx+31]
newPose:
    mov esp,ebp
    pop ebp
    ret

; (*) Do forever
mayDead:
        ; debug ebx
    mov ebx,dword[drn]
    call canDestroy
    call randomAlpha
    call speedChange
    mov ebx,dword[drn]
    call newPos
    mov ebx,0
    call nextCor
    jmp mayDead


NotFound:
    push error
    call printf
    add esp,4

    mov eax,0
    mov ebx,1
    int 0x80

canDestroy:
    fld qword[x_target]
    fld qword[ebx+1]
    fsubp ;; x_target - x_drone
    fst st1
    fmulp ;; (x_target - x_drone)^2
    fld qword[y_target]
    fld qword[ebx+9]
    fsubp  ;; y_target - y_drone
    fst qword[temp]
    fld qword[temp]
    fmulp ;; (y_target - y_drone)^2
    fadd
    fsqrt
    fild dword[d]
    jb DontDestroy
    inc byte[ebx+25] 
    mov ebx,2 ;; nextCOr the target co-routine
    call nextCor
    ret
DontDestroy:
    ; debug ebx
   ret