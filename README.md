# asmtest
Example for Writing Proper AMD64 Assembly Code for Windows

Goal of this small project is to grab all information available on x64 assembly from Microsoft, Intel Developer Zone,
Codemachine and McDermott Cypersecurity on x64 assembly, and put it together in one assembly file such that everyone can easily look or understand how to properly interface with the Windows 64-bit ABI.

Core elements include how to properly handle stack-based data.


Conclusion:

- Inside of each call, IMMEDIATELY after a call instruction has been executed, each CALLEE is guaranteed to receive a stack pointer "rsp" = 0x???????????????8. It does not matter if the call is API-internal or in a user's program.

- There exist 2 types of functions, "LEAF FUNCTIONS and "FRAME FUNCTIONS".

- A LEAF function does not call any other functions (--> it is a leaf on a tree of functions) or issue any Intel 0F 05 syscalls. After a possible function PROLOGUE the stack pointer is NOT required to be 16-bit aligned.

- A leaf function is NOT required to have a function prologue.

- Using local variables within a leaf function requires you to write a "sub rsp, XYZ" function.
- XYZ is given by: THE SUM OF ALL VARIABLE SIZES, ROUNDED UP TO AN 8 BYTE ALIGNED VALUE.
- Before exiting the function you must write an "add rsp, XYZ" instruction.

- In a leaf function THE FIRST VARIABLE is found at "rsp + 0". Subsequent ones at "rsp + sizeOfFirstVariable".

- Existence of a function PROLOGUE requires always a corresponding EPILOGUE:
- --> Each previous "sub rsp, XYZ" must now be matched with a "add rsp, XYZ", where "XYZ" must be the VERY SAME value.
- --> Each previous "push r??" must now be matched with a "pop r??", where "r??" must be the VERY SAME register.
- --> "push R??" before "sub rsp, XYZ" and "add rsp, XYZ" before "pop R??".
Example:

someFunction PROC

    push rsi    ;Prologue
    push rdi
    sub rsp, 18h
    nop     ;Actual calculations
    add rsp, 18h    ;Epilogue
    pop rdi
    pop rsi
    ret

someFunction ENDP

- A FRAME function calls other functions or issues syscall instructions, and MUST employ a function prologue. After execution of the prologue, the stack pointer MUST be 16-bit aligned, say, it must look like 0x???????????????0!

- 
- A function PROLOGUE of a leaf function can be completely missing.
- at minimum look like:

someSmallSub PROC

    xor eax, eax
    ret
    
someSmallSub ENDP

and at maximum like (following function allocates space on the stack for 3 8 byte local variables):

someBigSub PROC

    mov [rsp+8], rcx
    mov [rsp+10h], rdx
    mov [rsp+18h], r8
    mov [rsp+20h], r9
    push rbx
    push rbp
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 18h
    mov qword ptr [rsp], 1
    mov qword ptr [rsp+8], 2
    mov qword ptr [rsp+10h], 3
    mov eax, 12345678h
    add rsp, 18h
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbp
    pop rbx
    ret
  
someBigSub ENDP



  looks like
- After a function PROLOG 
