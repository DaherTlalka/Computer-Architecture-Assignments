section .bss
    user_input: resd 100 ;;read the user_input form the user
    message: resb 20
    an: resd 1; to save the hexadic value of the new number
    mystack: resd 1 ;;the stack size that we will change it leter
    number: resd 100 ;;the size of the number the we can get it

section .rodata
    string: db "%s",0 ;debug
    hex_string: db "%X",0x0a,0 ;debug
    printnumform: db "%X",0 ;;to print the number
    newL: db 0x0a,0 
    calc: db "calc: ", 0 ;; to print the word calc to the screen
    error: db "Error: Operand Stack Overflow",0x0a,0
    error2: db "Error: Operand mystack Empty",0x0a,0
    error1: db "Error: Insufficient Number of Arguments on Stack",0x0a,0
    error3: db "Error: Unknown symbol",0x0a,0

section .data
    nextNum: dd 0
    preNum: dd 0 
    length: dd 0
    odd_len: db 0 ;;to cheack if the length of the number is odd or not
    count: db 0
    pointer: dd 0
    pointer1: dd 0
    Stack_Items: dd 0 ;;saves the items in mystack
    maxNumOfNumber: dd 0
    OPcomand: dd 0
    carry: dd 0
    dflag: db 0;;defolt flage
    delet: db 0

section .text
    align 16
    global main
    extern printf
    extern fprintf 
    extern fflush
    extern malloc 
    extern calloc 
    extern free  
    extern getchar 
    extern fgets 
    extern stdin

%macro readstdin 0
    push dword[stdin]            ;fgets need 3 param
    push dword 100                   ;max lengthght
    push dword user_input               ;user_input buffer
    call fgets
    add esp, 12
%endmacro

%macro finishmode 0
    mov eax,1
    mov ebx,0
    int 0x80
%endmacro

%macro AllocateMem 1
    push ebx
    push ecx
    push edx
    push 1
    push %1              ; push amount of bytes malloc should allocatemem    
    call calloc           ; call malloc
    add esp,8
    test eax, eax          ; check if the malloc failed
    jnz   %%success        ; 
    mov dword[message],"fail"
    mov dword[message+4], " all"
    mov dword[message+8], "ocat"
    mov word[message+12],"e"
    mov word[message+14],0x0a
    mov word[message+16],0
    prinffir message
   %%success:
    pop edx
    pop ecx
    pop ebx     
%endmacro

%macro prinffir 1 ;;print the last args
    pushad
    push %1
    push string
    call printf
    add esp, 8
    popad
%endmacro

%macro prinfsec 1 ;;print the second args
    pushad
    push %1
    push hex_string
    call printf
    add esp, 8
    popad
%endmacro

 %macro printPoping 1
    pushad
    push %1
    push printnumform
    call printf
    add esp,8
    mov eax, %1
    popad
 %endmacro

 %macro newLine 0
    pushad
    push newL
    call printf
    add esp,4
    popad
%endmacro

%macro pointer2parms 2 ;; takes the pointer to two params
    mov eax,%1
    mov ecx,%2
    mov dword[eax+1],ecx
%endmacro

%macro freenodes 1 ;; when using give the address of the allocatememd memory
    push %1
    call free
    add esp,4
%endmacro

%macro freeNumber 1
    pushad

    mov eax,%1
%%anothernum:
    mov ebx,dword[eax+1]
    freenodes eax
    mov eax,ebx
    cmp ebx,0
    jne %%anothernum
    popad
%endmacro

%macro Poping 0
    cmp dword[Stack_Items],0
    je %%end
    sub dword[mystack],4
    mov eax,dword[mystack]
    mov ebx,dword[eax]
    mov dword[preNum],ebx
    dec dword[Stack_Items]
   %%end:
%endmacro

%macro freeMystack 0
  %%EmpMystack:
    cmp dword[Stack_Items],0
    je %%mystackF
    Poping
    freeNumber dword[preNum]
    jmp %%EmpMystack
  %%mystackF:
    freenodes dword[mystack]
%endmacro

%macro calculator 0
    push calc
    call printf
    add esp,4
%endmacro

%macro Pushing 1
    inc dword[Stack_Items]
    mov eax,dword[mystack]
    mov ebx,%1
    mov dword[eax],ebx
    add dword[mystack], 4
%endmacro

%macro print 2
    pushad
    push %2
    push %1
    call printf
    add esp, 8
    popad
%endmacro

%macro Peeking 0
    mov eax,dword[mystack]
    sub eax, 4
    mov ebx,dword[eax]
    mov dword[pointer],ebx
%endmacro

main:
    
    mov dword[length],5
    mov ecx,[esp+4]
    cmp ecx,2
    jl defa
    cmp ecx,3
    je debugflag
    cmp ecx,2
    je debugflag2
    mov ecx,[esp+8]
    mov ecx,dword[ecx+4]
    
makeNumber:
    mov dword[length],0
HEXADIC:
    cmp byte[ecx],0
    je defa ;; allocate memory the stack and start the program
    mov eax,dword[length]
    mov ebx,0x10
    mul ebx
    mov dword[length],eax
    cmp byte[ecx],65
    jge hex
    mov edx,0
    mov dl,byte[ecx]
    sub dl,48
    add dword[length],edx
    inc ecx
    jmp HEXADIC
hex:
    mov edx,0
    mov dl,byte[ecx]
    sub dl,65
    add dl,10
    add dword[length],edx
    inc ecx
    jmp HEXADIC

defa:
 
    mov eax,dword[length]
    mov ebx,4
    mul ebx
    AllocateMem eax
    mov dword[mystack],eax
    mov eax,dword[length] ;;the lenght that we can put on th stack
    mov dword[maxNumOfNumber],eax   ;; to init
    mov dword[Stack_Items],0           ;;to init
    
followingReadFromUser:   
    mov byte[delet],0
    calculator
    readstdin ;; change to check user_input species
    cmp byte[user_input],0x0a ;;we finsh read (/n)
    je followingReadFromUser
    cmp byte[user_input],'q'
    je finishprogram
    cmp byte[user_input],'p'
    je Pcomand
    cmp byte[user_input],'&'
    je BITWISEANDCOMAND
     cmp byte[user_input],'d'
    je dupcomand
    cmp byte[user_input],'n'
    je NumOfHexDigitComand
    cmp byte[user_input],'|'
    je BITWISEORCOMAND
    cmp byte[user_input],'*' 
    je mulComand
    cmp byte[user_input],'+' 
    je plusComand
    mov ecx,dword[maxNumOfNumber]
    cmp dword[Stack_Items],ecx   ;;full mystack
    jz OverElemntInStack
    cmp byte[dflag],1
    je macr
    jmp to_hex
macr:
    prinffir user_input
    jmp to_hex

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; quit ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
finishprogram:
    freeMystack
    prinfsec dword[OPcomand]
    finishmode
    nop

debugflag:
    mov ecx,[esp+8] ;;the first argc
    mov ecx,dword[ecx+4] ;;the second argc
    cmp byte[ecx],45
    je dcase1
    mov ecx,[esp+8]
    mov ecx,dword[ecx+8]
    cmp byte[ecx],45
    je dcase2
    jmp makeNumber
dcase1:
    mov byte[dflag],1
    mov ecx,[esp+8]
    mov ecx,dword[ecx+8]
    jmp makeNumber
dcase2:
    mov byte[dflag],1
    mov ecx,[esp+8]
    mov ecx,dword[ecx+4]
    jmp makeNumber

debugflag2:
    mov ecx,[esp+8]
    mov ecx,dword[ecx+4]
    cmp byte[ecx],45
    jne makeNumber
    mov byte[dflag],1
    jmp makeNumber
PushInto:
    mov ecx,dword[maxNumOfNumber]
    cmp dword[Stack_Items],ecx   ;;the stack is full
    jz OverElemntInStack
    cmp dword[Stack_Items],0     ;;the stack is empty
    jz PUSHPRENUM
    Pushing dword[preNum]
    cmp byte[dflag],1
    je dpushmode
    jmp followingReadFromUser

PUSHPRENUM:
    Pushing dword[preNum]
    cmp byte[dflag],1
    je dpushmode
    jmp followingReadFromUser

dpushmode:
    mov byte[delet],1
    jmp printNum

OverElemntInStack:
    prinffir error
    jmp followingReadFromUser

Pcomand:
    cmp dword[Stack_Items],0
    je EmptyErr  ;; Empty mystack
    inc dword[OPcomand]
    Poping
    jmp printNum

EmptyErr:
    prinffir error1
    jmp followingReadFromUser
NotEnough:
    prinffir error2
    jmp followingReadFromUser

printNum:
    mov ebx,dword[preNum]
    mov dword[pointer],ebx
    mov dword[length],0
    .nextNum:
        mov edx,0
        mov ecx,dword[pointer]
        mov dl, byte[ecx]
        cmp dword[ecx+1], 0
        je .StorNumAndPrint
        jmp .adding
    .nextLink:
        mov eax,dword[ecx+1]
        mov dword[pointer],eax
        jmp .nextNum

    .adding:
        mov ebx,dword[length]
        mov byte[number+ebx],dl
        inc dword[length]
        jmp .nextLink
    .StorNumAndPrint:
        mov ebx,dword[length]
        mov byte[number+ebx],dl
        mov dx,0
        inc dword[length]
        mov ax,word[length]
        mov bl,4
        div bl
        mov ebx,0
        mov bl,al
        mov byte[length],bl ;; now length stores the number of bytes of the number that we need to print
        cmp dword[length],0
        je .caseZero
    .printing:
        cmp dword[number+4*ebx],0
        je .popingzeroes
        cmp dword[number+4*ebx],0x10
        jl .Ten
        cmp dword[number+4*ebx],0x100
        jl .Hundred
        cmp dword[number+4*ebx],0x1000
        jl .thousand
        cmp dword[number+4*ebx],0x10000
        jl .TenThousand
        cmp dword[number+4*ebx],0x100000
        jl .HundredThousand
        cmp dword[number+4*ebx],0x1000000
        jl .Milion
        cmp dword[number+4*ebx],0x10000000
        jl .TenMilion
    .caseZero:
        printPoping dword[number+4*ebx]
    .caseZero2:
        dec ebx
        cmp ebx,0
        jge .printing
        newLine
        mov ebx,0
        mov bl,byte[length]

    .zero:
        mov dword[number+4*ebx],0
        dec ebx
        cmp ebx,0
        jge .zero
        cmp byte[delet],1
        je followingReadFromUser
        freeNumber dword[preNum]
        jmp followingReadFromUser
        
    .popingzeroes:
        cmp ebx,0
        jl .caseZero2
        jmp .caseZero2
    .OneZero:
        cmp dword[length],0
        je .caseZero
        cmp ebx,1
        je .caseZero
    .TowZero:
        cmp dword[length],0
        je .caseZero
        cmp ebx,1
        je .caseZero
    .ThreeZero:
        cmp dword[length],0
        je .caseZero
        cmp ebx,1
        je .caseZero
    .FourZero:
        cmp dword[length],0
        je .caseZero
        cmp ebx,1
        je .caseZero
    .FiveZero:
        cmp dword[length],0
        je .caseZero
        cmp ebx,1
        je .caseZero
    .SixZero:
        cmp dword[length],0
        je .caseZero
        cmp ebx,1
        je .caseZero
    .SevenZero:
        cmp dword[length],0
        je .caseZero
        cmp ebx,1
        je .caseZero
        cmp dword[number+4*ebx],0
        je .caseZero2
        jmp .caseZero
    .Ten:;; one zero
        cmp ebx,0
        jl .caseZero2
        jmp .OneZero
    .Hundred:;; tow zero 
        cmp ebx,0
        jl .caseZero2
        jmp .TowZero
    .thousand:;; three zero ...... until 7 zero
        cmp ebx,0
        jl .caseZero2
        jmp .ThreeZero
    .TenThousand:
        cmp ebx,0
        jl .caseZero2
        jmp .FourZero
    .HundredThousand:
        cmp ebx,0
        jl .caseZero2
        jmp .FiveZero
    .Milion:
        cmp ebx,0
        jl .caseZero2
        jmp .SixZero
    .TenMilion:
        cmp ebx,0
        jl .caseZero2
        jmp .SevenZero

        

faildInptUser:
    prinffir error3 ;;delete memory
    jmp followingReadFromUser

user_inputLen:
    cmp byte[ebx],0
    jz FinishInput
    inc eax
    inc ebx
    jmp user_inputLen

ZeroLoop:
    cmp byte[ebx],48
    jnz continuComands
    cmp byte[ebx],48
    jl faildInptUser
    cmp byte[ebx],70
    jg faildInptUser
    inc ebx
    jmp ZeroLoop
to_hex:
    mov ebx,user_input
    mov eax,0
    jmp user_inputLen
FinishInput:
    mov ebx,user_input;; first of alll we need to know the lengthgth of the user_input
    cmp eax,2
    jle continuComands
    jmp ZeroLoop
continuComands:
    mov esi,ebx
    cmp byte[ebx],0x0a
    je finishprogram
    mov dword[length],0
OddLoop:
    cmp byte[ebx],0x0a
    je Oddnum
    inc ebx
    inc dword[length]
    jmp OddLoop
    
Oddnum:
    mov edx,0 ;; for safe division
    mov eax,dword[length]
    mov ecx,2
    DIV ecx
    mov byte[odd_len],dl;;tells if the lengthgth of the numebr is odd or not

    mov ebx,esi
    cmp byte[odd_len],1
    je convertOneOP
    jmp convertMulOp
SAL:
    mov byte[count],0
    mov al,0
ConverNode: ;; every new node value is saved in al
    cmp byte[count],2
    je JoinNode
    cmp byte[ebx],0x0a;;new line
    je PushInto  ;;temp jmp--> check first if al==0
    mov dh,16
    mul dh
    cmp byte[ebx],65
    jge ConvertAplus
    cmp byte[ebx],57
    jg faildInptUser
    mov dl,byte[ebx]
    sub dl,48
    add al,dl
    inc ebx
    inc byte[count]
    ;;multiply by 16
    jmp ConverNode
ConvertAplus:
    cmp byte[ebx],70
    jg faildInptUser
    mov dl,byte[ebx]
    sub dl,65
    add dl,10
    add al,dl
    inc ebx
    inc byte[count]
    jmp ConverNode

convertMulOp:;;this is hard coded, we can optimize
        mov byte[count],0
        mov ah,0
        mov al,0;;primary number
    .first:
        cmp byte[count],2
        je CreatFirDig
        mov dh,16
        mul dh
        cmp byte[ebx],65
        jge .hexa
        mov dl,byte[ebx]
        sub dl,48
        add al,dl
        add ebx,1
        inc byte[count]
        jmp .first
    .hexa:
        mov dl,byte[ebx]
        sub dl,65
        add dl,10
        add al,dl
        add ebx,1
        inc byte[count]
        jmp .first

convertOneOP:
    mov al,byte[ebx]
    inc ebx
    cmp al,65
    jge Hexfir
    sub al,48
    jmp CreatFirDig
Hexfir:
    sub al,65
    add al,10
    jmp CreatFirDig

CreatFirDig:
    mov byte[an],al

    AllocateMem 5
    mov dword[preNum],eax ;;give the adress to prenum
    mov dl,byte[an]
    mov byte[eax],dl
    mov dword[eax+1],0;; null pointer
    jmp SAL;;change to SAL
JoinNode: 
    mov byte[an],al
    AllocateMem 5
    mov dword[nextNum],eax ;;give the adress to nextNum
    pointer2parms dword[nextNum],dword[preNum]
    mov ecx,dword[nextNum]
    mov dword[preNum],ecx    ;;change the head
    mov dl,byte[an]
    mov byte[ecx],dl
    mov dword[pointer],ecx
    jmp SAL
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;&&&&&&&&&&&&&&&&;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BITWISEANDCOMAND:
    inc dword[OPcomand]
    cmp dword[Stack_Items],2
    jl NotEnough
    Poping
    mov eax,dword[preNum]
    mov dword[nextNum],eax    ;;first link
    push eax         ;;dump variable to free memory
    Poping                       ;;second link
    mov eax,dword[preNum]
    push eax        ;;dump variable to free memory
    AllocateMem 5
    mov dword[an],eax;;push this
    mov dword[pointer],eax      ;; toAdd link

    .AndOperator:
        mov ecx,0
        mov ebx,dword[preNum]
        mov cl,byte[ebx]
        mov ebx,dword[nextNum]
        and cl,byte[ebx]
        mov ebx,dword[pointer]
        mov byte[ebx],cl
        mov ebx,dword[preNum]
        cmp dword[ebx+1],0
        je .Finish_Comparing
        mov ebx,dword[nextNum]
        cmp dword[ebx+1],0
        je .Finish_Comparing
        AllocateMem 5
        mov ebx,dword[pointer]
        mov dword[ebx+1],eax
        mov dword[pointer],eax
        mov ebx,dword[nextNum]
        mov ecx,dword[ebx+1]
        mov dword[nextNum],ecx
        mov ebx,dword[preNum]
        mov ecx,dword[ebx+1]
        mov dword[preNum],ecx
        jmp .AndOperator
    .Finish_Comparing:
        mov eax,dword[pointer]
        mov dword[eax+1],0
        mov eax,dword[an]
        mov dword[preNum],eax
        pop eax       ;;before we leaving we free the memory
        freeNumber eax 
        pop eax       ;;before we leaving we free the memory
        freeNumber eax
        jmp PushInto   

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; duplicate command;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dupcomand:
    inc dword[OPcomand]
    cmp dword[Stack_Items],0
    je EmptyErr  ;; Empty mystack
    mov ecx,dword[maxNumOfNumber]
    cmp dword[Stack_Items],ecx   ;;full mystack
    jz OverElemntInStack
    Peeking      ;; pointer points to the top of the mystack
    AllocateMem 5
    mov dword[preNum],eax ;; the new duplicated number
    mov dword[nextNum],eax
    .duplicate:       ;; inffinte loop
        mov eax,0
        mov ebx,dword[pointer]
        mov al,byte[ebx]
        mov ebx,dword[nextNum]
        mov byte[ebx],al
        mov eax,dword[pointer]
        cmp dword[eax+1],0
        je .finishduplicate
        AllocateMem 5
        mov ebx,dword[nextNum]
        mov dword[ebx+1],eax
        mov dword[nextNum],eax
        mov eax,dword[pointer]
        mov ebx,dword[eax+1]
        mov dword[pointer],ebx
        jmp .duplicate
    .finishduplicate:
        mov eax,dword[nextNum]
        mov dword[eax+1],0
        jmp PushInto     ;;final step => push the duplicated number 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; num command ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;n operand
NumOfHexDigitComand:
    inc dword[OPcomand]
    Poping
    mov eax,dword[preNum]
    push eax      ;;dump variable to free memory
    mov dword[an],0         ;; dword should be enough for a Number Length = 0xFFFFFFFF = 4294967295

    .CountDigit:
        mov eax,dword[preNum]
        cmp dword[eax+1],0
        je .ReviewLastAN
        add dword[an],2
        mov ebx,dword[eax+1]
        mov dword[preNum],ebx
        jmp .CountDigit

    .ReviewLastAN: 
        cmp byte[eax],0x10
        jb .one ;; jb = jump if below to perform unsigned comparison
        inc dword[an]

    .one:       
        inc dword[an]
        AllocateMem 5
        mov dword[nextNum],eax
        mov ebx,eax
        mov eax,dword[an]
        jmp .LengthFir

    .internalLen:
        AllocateMem 5
        mov dword[ebx+1],eax
        mov ebx,eax
        mov eax,dword[an]

    .LengthFir:
        mov byte[ebx],al
        mov edx,0
        mov ecx,0x100
        div ecx
        mov dword[an],eax
        cmp eax,0
        jne .internalLen
        mov dword[ebx+1],0
        mov eax,dword[nextNum]
        mov dword[preNum],eax
        pop eax
        freeNumber eax       ;;free memory before leaving
        jmp PushInto
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;||||||||||||||;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BITWISEORCOMAND:
    inc dword[OPcomand]
    cmp dword[Stack_Items],2
    jl NotEnough
    Poping
    mov eax,dword[preNum]
    mov dword[nextNum],eax
    push eax        ;;dump variable to free memory
    Poping
    mov eax,dword[preNum]
    push eax          ;;dump variable to free memory
    AllocateMem 5
    mov dword[an],eax;;push this
    mov dword[pointer],eax
    mov dword[carry],"here"

    .Or_Operand:
        mov ecx,0
        mov ebx,dword[preNum]
        mov al,byte[ebx]
        mov ebx,dword[nextNum]
        or  al,byte[ebx]
        mov ebx,dword[pointer]
        mov byte[ebx],al
        mov ebx,dword[preNum]
        cmp dword[ebx+1],0
        je .CompareNext
        mov ebx,dword[nextNum]
        cmp dword[ebx+1],0
        je .ComparePre
        AllocateMem 5
        mov ebx,dword[pointer]
        mov dword[ebx+1],eax
        mov dword[pointer],eax
        mov ebx,dword[nextNum]
        mov ecx,dword[ebx+1]
        mov dword[nextNum],ecx
        mov ebx,dword[preNum]
        mov ecx,dword[ebx+1]
        mov dword[preNum],ecx
        jmp .Or_Operand
    .CompareNext:
        mov ebx,dword[nextNum]
        cmp dword[ebx+1],0
        je .Finish_Comparing
        AllocateMem 5
        mov ebx,dword[pointer]
        mov dword[ebx],eax
        mov dword[pointer],eax
        mov ebx,dword[nextNum]
        mov cl,byte[ebx]
        mov byte[pointer],cl
        jmp .CompareNext
    .ComparePre:
        mov ebx,dword[preNum]
        cmp dword[ebx+1],0
        je .Finish_Comparing
        AllocateMem 5
        mov ebx,dword[pointer]
        mov dword[ebx],eax
        mov dword[pointer],eax
        mov ebx,dword[preNum]
        mov cl,byte[ebx]
        mov byte[pointer],cl
        jmp .ComparePre
    .Finish_Comparing:
        mov eax,dword[pointer]
        mov dword[eax+1],0
        mov eax,dword[an]
        mov dword[preNum],eax
        pop ebx       ;;free before leaving
        freeNumber ebx ;;poped all the reg in the stack
        pop ebx       ;;free before leaving
        freeNumber ebx
        jmp PushInto


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; optinal op ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mulComand:
    inc dword[OPcomand]
    cmp dword[Stack_Items],1
    jle EmptyErr 
    Poping;;pointer
    mov eax,dword[preNum]
    mov dword[pointer],eax;; ref
    mov dword[pointer1],eax
    Poping;; preNum
    push dword[preNum] ;; dump variable to memory free
    push dword[pointer]
    AllocateMem 5
    mov dword[nextNum],eax
    mov dword[eax+1],0
    Pushing dword[nextNum]
    mov ebx,dword[nextNum]
    mov dword[length],ebx ;;ref
    mov dword[ebx+1],0
    mov byte[ebx],0
    mov dword[carry],0
    jmp testNum;; if one of them is ZERO

MutFirByte:;; pointer1 is the running variable
    mov eax,0
    mov ecx,dword[pointer1]
    mov al,byte[ecx]
    mov ecx,dword[preNum]
    mov cl,byte[ecx]
    mul cl
    mov cl,ah
    mov ah,0
    mov ebx,dword[nextNum];; the mul result
    add al,byte[ebx]
    add ax,word[carry]
    mov byte[ebx],al
    mov byte[carry],cl;;the mul carry
    add byte[carry],ah;; the last add carry
    mov ecx,dword[pointer1]
    cmp dword[ecx+1],0
    je EndMoodLine;;move to the next node in preNum
    mov ecx,dword[ecx+1];;go to the next node
    mov dword[pointer1],ecx
    cmp dword[ebx+1],0
    je newOne
    mov ebx,dword[ebx+1]
    mov dword[nextNum],ebx;;next result node
    jmp MutFirByte

newOne:
    AllocateMem 5
    mov dword[ebx+1],eax
    mov dword[eax+1],0
    mov ebx,dword[ebx+1]
    mov dword[nextNum],ebx;;next result node
    jmp MutFirByte

EndMoodLine:;;reached the end of pointer1
    ;;last preNum
    mov ecx,dword[preNum]
    cmp dword[ecx+1],0
    jne NotFinshComparingP2
carryF:
    
    cmp byte[carry],0
    je TheEnd
    
    mov ebx,dword[nextNum]
    
    cmp dword[ebx+1],0
    jne OneDigit
    AllocateMem 5
    mov dword[ebx+1],eax
    mov dword[eax+1],0
    mov bl,byte[carry]
    mov byte[eax],bl
    jmp TheEnd
OneDigit:
    mov ebx,[ebx+1]
    mov ax,0
    mov al,byte[ebx]
    add ax,word[carry]
    mov byte[ebx],al
    mov byte[carry],ah
    jmp carryF

TheEnd:
    pop eax
    freeNumber eax
    pop eax
    freeNumber eax 
    jmp followingReadFromUser

NotFinshComparingP2:;; in case the preNum did not Finish_Comparing but the pointer 2 finished
    mov ecx,dword[preNum]
    mov ecx,[ecx+1]
    mov dword[preNum],ecx
    mov ecx,dword[pointer]
    mov dword[pointer1],ecx
    mov ecx,dword[length];;moving the result one byte
    cmp dword[ecx+1],0
    je NewDig
DoneDig:
    mov ecx,dword[ecx+1]
    mov dword[length],ecx
    mov dword[nextNum],ecx
    mov dword[carry],0
    jmp MutFirByte

NewDig:
    AllocateMem 5
    mov dword[ecx+1],eax
    mov dword[eax+1],0
    jmp DoneDig



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+++++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
plusComand:
    inc dword[OPcomand]
    cmp dword[Stack_Items],1
    jle EmptyErr 
    Poping;;preNum
    Peeking;; pointer
    mov eax, dword[preNum]
    mov dword[length],eax        ;;dump variable to free memory
    mov word[carry],0
    .Adding:
        mov eax,dword[preNum]
        cmp dword[eax+1],0
        je .comparing
        mov ebx,dword[pointer]
        cmp dword[ebx+1],0
        je .comparing
        mov cx,0
        mov dx,0
        mov cl,byte[eax]
        mov dl,byte[ebx]
        add cx,dx
        add cx,word[carry]
        mov byte[ebx],cl
        mov byte[carry],ch
        mov ebx,dword[ebx+1];; move next
        mov dword[pointer],ebx
        mov eax,dword[eax+1];;move next
        mov dword[preNum],eax
        jmp .Adding

    .comparing:
        mov eax,dword[pointer]
        mov ebx,0
        mov ecx,0
        mov bl,byte[eax]
        mov eax,dword[preNum]
        mov cl,byte[eax]
        add bx,cx
        add bx,word[carry]
        mov eax,dword[pointer]
        mov byte[eax],bl
        mov byte[carry],bh
        mov ecx,dword[preNum]
        cmp dword[ecx+1],0 ;; next!=null
        jnz .comparPre
        mov eax,dword[pointer]
        cmp dword[eax+1],0
        je .ContRe
        mov eax,dword[eax+1]

    .seequence_links:
        cmp dword[eax+1],0
        je .LastP
        mov ebx,0
        mov bl,byte[eax]
        add bx,word[carry]
        mov byte[eax],bl
        mov byte[carry],bh
        mov eax,dword[eax+1]    ;; move to the next link
        jmp .seequence_links

    .LastP:
        mov bx,0
        mov bl,byte[eax]
        add bx,word[carry]
        mov byte[eax],bl
        mov byte[carry],bh
    .ContRe:
        cmp byte[carry],0
        je followingReadFromUser
        mov ebx,eax
        AllocateMem 5
        mov dword[ebx+1],eax
        mov cl,byte[carry]
        mov byte[eax],cl
        mov dword[eax+1],0
        freeNumber dword[length]
        jmp followingReadFromUser

    .comparPre:
        mov eax,dword[preNum]
        mov ebx,dword[pointer]
        mov ecx,dword[eax+1]
        mov dword[ebx+1],ecx
        mov dword[eax+1],0
        mov eax,dword[ebx+1]
        jmp .seequence_links

testNum:
    mov eax,dword[pointer]
    cmp dword[eax+1],0
    je ZeroTest
Sectest:
    mov eax,dword[preNum]
    cmp dword[eax+1],0
    je ZeroTest2
    jmp MutFirByte

ZeroTest:
    cmp byte[eax],0
    je zeros
    jmp Sectest
ZeroTest2:
    cmp byte[eax],0
    je zeros
    jmp MutFirByte
zeros:
    mov eax,dword[nextNum]
    mov byte[eax],0
    mov dword[eax+1],0
    push eax
    freeNumber eax
    push eax
    freeNumber eax
    jmp followingReadFromUser
    
