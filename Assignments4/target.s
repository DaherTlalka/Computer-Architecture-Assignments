extern nextCor
extern changeTheTarget
extern printf
extern droneCor

global createTarget

section .data
    dfor: dd "%d",10,0

section .text

createTarget:
    
    call changeTheTarget
    mov ebx,[droneCor]
    call nextCor
    jmp createTarget
