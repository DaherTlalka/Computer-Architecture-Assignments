section	.rodata			; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	; format string

section .bss			; we define (global) uninitialized variables in .bss section
	an: resb 12		; enough to store integer in [-2,147,483,648 (-2^31) : 2,147,483,647 (2^31-1)]

section .text
	global convertor
	extern printf

convertor:
	push ebp
	mov ebp, esp	
	pushad			

	mov ecx, dword [ebp+8]	; get function argument (pointer to string)
	mov eax, an
	mov bl, 0

fisrtLoop:  
    mov dl, 3        
	cmp byte [ecx], 55           ; compare if ecx < 8
	jle toconvert  
	jmp endOF

toconvert:			; 0 <= number <= 7
	cmp byte [ecx], 48             ; compare if ecx < 0
	je iszero 
	cmp byte [ecx], 48             ; compare if ecx < 0
	jl endOF  
	sub dword [ecx], 48
	shl byte [ecx], 5
	jmp Begin_Loop

Begin_Loop:	
	cmp dl,0    ; compare if dl < 1
	je nextoctal
	shl byte [ecx],1
	jc one
	sub dl, 1			;it is 0
    cmp bl, 0
	je Begin_Loop
	mov byte [eax], 48
	inc eax
	jmp Begin_Loop

one:
	sub dl, 1
	mov bl, 1
	mov byte [eax], 49
	inc eax
	jmp Begin_Loop

iszero:
    sub dl, 1
	mov byte [eax], 48
	inc eax
	jmp Begin_Loop


nextoctal:
	inc ecx
	cmp byte [ecx], 0
	jne fisrtLoop


endOF:
    mov byte [eax], 0
	push an			; call printf with 2 arguments -  
	push format_string	; pointer to str and pointer to format string
	call printf
	add esp, 8		; clean up stack after call

	popad			
	mov esp, ebp	
	pop ebp
	ret
