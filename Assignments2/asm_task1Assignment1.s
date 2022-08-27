section.data	
      	fmtd: db "%d",10,0 ;; format string to print
section.text
                global  assFunc
                extern c_checkValidity
                extern printf
                                    
assFunc:
 push ebp
 mov ebp, esp	
 pushad

			                                    
 mov ebx, dword [ebp+8]	  ;; get the function argument, "+8" that because we pushed edp and the main already push the argument and both of them are int 4 bite so we should add 8 to pointer edp 

 push ebx	                 ;; push the arguments
 call  c_checkValidity     ;; call the function and the return value saved in eax
 add esp, 4 ;; free allocated space in the stack when we pushed ebx // loop
 cmp eax, 0
 je positive
 shl ebx, 2
 mov eax, ebx
 jmp end
                                   
                           
positive:
   shl ebx, 3
   mov eax, ebx
end:
    push eax    
    push fmtd	; pointer to format string
    call printf; popad overflow command	
    add esp,8	
    mov esp, ebp	
    pop ebp
    ret
