%include "src/asm/defines.inc"

default rel

extern render_rows

section .text

global render_worker
render_worker:
    ; rdi = task*
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 8

    mov rbx, rdi

    mov rdi, [rbx + TASK_BUF]
    mov esi, dword [rbx + TASK_WIDTH]
    mov edx, dword [rbx + TASK_HEIGHT]
    mov ecx, dword [rbx + TASK_START]
    mov r8d, dword [rbx + TASK_END]
    call render_rows

    xor eax, eax
    add rsp, 8
    pop rbx
    leave
    ret
