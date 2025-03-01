section .data
    ln10 dq 2.302585092994046  ; Pre-calculated value of ln(10)

    n_eno_buff db 'Error: Buffer is too small to store the number.', 0
    msg_len equ $ - n_eno_buff   ; Length of the error message (calculated automatically)



SECTION .bss

write_buffer:
    buffer resb 1024
    buffer_index resb 2
    prime resb 1000


SECTION .text
    global _start


_start:
    push rbp
    mov rbp,rsp
    call init_log10
    mov rdi,123456789
    call print_dec
    call flush
    mov rax, 60         ; Syscall number for sys_exit
    mov rdi, 0          ; Exit code 1 (error)
    syscall             ; Exit the program







; it will use log(10) to calculate number of digit to know where to start (writing in reverse ordre right to left to avoid swaping order)
;if buffer isn's big enough it will flush / if max buffer too small -> print error and exit (need to be done)
; rdi = number
print_dec:
    push rbp
    mov rbp,rsp
    push rbx
    push rax
    call calculate_log10
    add rax,2; +1 for \n and +1 cause log10 return number of digit -1
    cmp rax,1023
    jge not_enough_buffer_error
    movzx rcx,word [buffer_index]
    add rcx,rax
    cmp rcx,1023
    jl no_flush
    call flush
no_flush:
    add rcx,buffer
    mov byte[rcx],10
    dec rcx
    mov rdi, loop_print_dec
    mov rbx,10
    pop rax
loop_print_dec:
    div rbx
    add dl,48
    mov byte[rcx],dl
    dec rcx
    jnz loop_print_dec
    pop rbx
    mov rsp,rbp
    pop rbp
    ret


not_enough_buffer_error:
    ; Syscall to write the error message to stderr (file descriptor 2)
    mov rdi, 2          ; File descriptor 2 (stderr)
    mov rsi, n_eno_buff ; Pointer to the error message
    mov rdx, msg_len    ; Length of the error message
    mov rax, 1          ; Syscall number for sys_write
    syscall             ; Call the syscall

    ; Exit the program with an error code (1)
    mov rax, 60         ; Syscall number for sys_exit
    mov rdi, 1          ; Exit code 1 (error)
    syscall             ; Exit the program
    


; will not respect convention
flush:
    push rax
    mov rdi, 1          ; File descriptor 1 (stdout)
    mov rsi, buffer    ; Pointer to the message
    movzx rdx, word [buffer_index]         ; Length of the message
    mov rax, 1          ; Syscall number for sys_write (1)
    syscall             ; Make the syscall
    pop rcx
    ret


calculate_log10: ; for x > 1000
    sub rsp, 8
    cvtsi2sd xmm0, rdi  ; Convert integer in rdi to double in xmm0
    movq qword [rsp], xmm0
    fld  qword[rsp]; load in FPU stack

    mov rax,1
    cvtsi2sd xmm0,rax  ; Convert integer in rdi to double in xmm0
    movq qword [rsp], xmm0
    fld  qword[rsp]; load in FPU stack
    fyl2x
    fld qword[ln10]
    fdiv st1,st0
    frndint
    fistp qword[rsp]
    cvttsd2si rax,qword[rsp]
    add rsp,8
    ret

init_log10:
    sub rsp, 8
    mov rax,10
    cvtsi2sd xmm0, rax  ; Convert integer in rdi to double in xmm0
    movq qword [rsp], xmm0
    fld  qword[rsp]; load in FPU stack

    mov rax,1
    cvtsi2sd xmm0, rax  ; Convert integer in rdi to double in xmm0
    movq qword [rsp], xmm0
    fld  qword[rsp]; load in FPU stack
    fyl2x ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; NOT WORKING
    fistp qword[rsp]
    cvttsd2si rax,qword[rsp]
    add rsp,8
    ret