.code
mymain PROC    
	mov rsp, qword ptr gs:[8]	;ENTRY POINT, reset stackpointer to pTeb->StackBase.
	int 3
	call mymain2				;Test function #1
	call mymain3				;Test function #2
	ret
mymain2:						;Both test functions receive properly aligned stack pointer rsp = StackBase-??8.
	push rbx					;save rbx for lol
								;Reserve space for
	;sub rsp, 20h 				;	- rcx, rdx, r8, r9 Homing area (shadow space)
	;sub rsp, 18h				;	- Parameter space for 3 params of callee
	;//sub rsp, 10h				;	- Space for 1 or 2 8 byte locals
	;sub rsp, 8h					;	- Stack alignment --> after executing sub instruction (--> prolog finished) rsp must be aligned to 16 bytes!
								;!!!return address + saved registers + shadow space + callee arguments + locals + alignment = n*16!!!
								;--> 8 + 8 + 20h + 18h + 8h = 50h = 5*16!
								;If stack alignment necessary, always SUB rsp, 8, otherwise, last saved register will be overwritten!
	;================================================================================================================================
	sub rsp, 40h
								;Locals starting @ &"Last calling param" + 8 if "frame function"
	mov dword ptr [rsp+38h], 12345678h		;ULONG var1 = 0x12345678
	mov dword ptr [rsp+3Ch], 90ABCDEFh		;ULONG var2 = 0x90ABCDEF
	xor rbx, rsp
	;mov [rsp+40h], rbx						;ULONGLONG var3 = someComputedValue
	or rcx, -1
	mov rdx, rcx
	dec rdx
	mov r8, rdx
	dec r8
	mov r9, r8
	dec r9
								;5th and more arguments always starting @ rsp+20h!
	mov [rsp+20h], r9
	mov [rsp+28h], r9
	mov [rsp+30h], r9
	dec qword ptr [rsp+20h]
	sub qword ptr [rsp+28h], 2
	sub qword ptr [rsp+30h], 3
	call somefirstproc
	mov rcx, [rsp+38h]			;Make first local visible in Windbg register view
	;mov rdx, [rsp+40h]			;Make second local visible in Windbg register view
	xor [rsp+38h], rbx
	;and [rsp+40h], rax
	call someproc
	mov rdx, [rsp+38h]			;Make them visible again
	;mov rcx, [rsp+40h]
	add rsp, 40h
	pop rbx
	ret
mymain3:
								;Reserve space for
	sub rsp, 20h				;	- Homing area
	sub rsp, 18h				;	- 3 callee arguments
								;!!!return address + saved registers + shadow space + callee arguments + locals + alignment = n*16!!!
								;--> 8 + 0 + 20h + 18h + 0h = 40h = 4*16!
								;No stack alignment necessary, last (4+n)th param @ return address - 8.
	sub rsp, 10h				;2 8 byte locals (we cannot allocate just one due to stack alignment reasons)
	mov dword ptr [rsp+38h], 99999999h
	mov byte ptr [rsp+3Fh], 23h 
	or rcx, -1
	mov rdx, rcx
	dec rdx
	mov r8, rdx
	dec r8
	mov r9, r8
	dec r9
	mov [rsp+20h], r9
	mov [rsp+28h], r9
	mov [rsp+30h], r9
	dec qword ptr [rsp+20h]
	sub qword ptr [rsp+28h], 2
	sub qword ptr [rsp+30h], 3
	call somefirstproc
	call someproc
	mov rcx, [rsp+38h]
	add rsp, 48h
	ret
mymain ENDP

;AFTER execution of ENTIRE prolog:
;Homing params @ rsp + sizeof(64bit_returnaddress) + "push count" * sizeof(ULONGLONG) + rsp subtracted value
; = rsp + 8 + "push count" * 8 + rsp subtracted value = rsp + 8 * ("push count" + 1) + rsp subtracted value
; = rsp + 8 * (2 + 1) + 38h = rsp + 18h + 38h = rsp + 50h
;
;(5+n)th calling argument @ &"Homing params" + "Shadow space" + n * 8
;--> 5th calling argument @ rsp + 8 * ("push count" + 1) + rsp subtracted value + 4 * 8
; = rsp + 8 * ("push count" + 5) + rsp subtracted value
; = rsp + 8 * (2 + 5) + 38h = rsp + 8 * 7 + 38h
; = rsp + 16 * 3 + 1 * 8 + 38h = rsp + 38h + 38h = rsp + 70h
somefirstproc PROC
	mov     rax, rsp
	mov     qword ptr [rax+8],rcx
	mov     qword ptr [rax+10h],rdx
	mov     qword ptr [rax+18h],r8
	mov     qword ptr [rax+20h],r9
	push    rbx
	push    rsi
	sub     rsp,38h
	mov rax, [rsp+70h]
	mov rbx, [rsp+78h]
	add rsp, 38h
	pop rsi
	pop rbx
	ret
somefirstproc ENDP

;(5+n)th calling argument @ &"Homing params" + "Shadow space" + n * 8
;--> 5th calling argument @ rsp + 8 * ("push count" + 5) + rsp subtracted value
; = rsp + 8 * 13 + 38h
; = rsp + 16 * 6 + 1 * 8 + 38h = rsp + 68h + 38h = rsp + 0A0h
;Homing params @ rsp + 80h
someproc PROC
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
	sub rsp, 38h
	mov rbx, [rsp+0A0h]
	mov rsi, [rsp+0A8h]
	mov rdi, [rsp+0B0h]
	and rcx, 1
	mov rdx, rcx
	inc rdx
	mov r8, rdx
	inc r8
	mov r9, r8
	inc r9
	mov [rsp+20h], rbx
	mov [rsp+28h], rsi
	mov [rsp+30h], rdi
	call somedeeperproc
	add rsp, 38h
	pop r15
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbp
	pop rbx
	ret
someproc ENDP

;--> 5th calling argument @ rsp + 8 * ("push count" + 5) + rsp subtracted value
; = rsp + 8 * 13 + 8
; = rsp + 16 * 6 + 1 * 8 + 8 = rsp + 70h
;Homing params @ rsp + 48h
somedeeperproc PROC
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
	sub rsp, 8h				;ULONGLONG var1;	
							;rsp MAYBE not aligned here since no further function call occurs.
							;rsp in this case only aligned due to 8 byte locals allocation!
	mov rbx, [rsp+70h]
	mov r12, [rsp+78h]
	mov r15, [rsp+80h]
						;In case of no further function call locals start @ rsp+0!
	mov [rsp], r12		;var1 = anotherComputedValue
	mov r13d, ebx
	mov eax, r13d
	movzx rbx, ax
	mov rax, rbx
	add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbp
	pop rbx
	ret
somedeeperproc ENDP
END