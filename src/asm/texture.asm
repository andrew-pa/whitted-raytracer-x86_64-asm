%include "src/asm/defines.inc"

default rel

extern floor

section .text

global texture_sample
texture_sample:
    ; rdi = material*, rsi = point*, rdx = out_color*
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov r8, rdx

    mov eax, dword [rdi + MAT_TEX_TYPE]
    cmp eax, TEX_CHECKER
    je .checker
    cmp eax, TEX_STRIPE
    je .stripe

.solid:
    movsd xmm0, [rdi + MAT_TEX_COLOR1 + VEC3_X]
    movsd [r8 + VEC3_X], xmm0
    movsd xmm0, [rdi + MAT_TEX_COLOR1 + VEC3_Y]
    movsd [r8 + VEC3_Y], xmm0
    movsd xmm0, [rdi + MAT_TEX_COLOR1 + VEC3_Z]
    movsd [r8 + VEC3_Z], xmm0
    leave
    ret

.checker:
    movsd xmm3, [rdi + MAT_TEX_SCALE]
    movsd [rsp], xmm3

    movsd xmm0, [rsi + VEC3_X]
    mulsd xmm0, [rsp]
    call floor
    cvttsd2si rax, xmm0

    movsd xmm0, [rsi + VEC3_Y]
    mulsd xmm0, [rsp]
    call floor
    cvttsd2si rcx, xmm0

    movsd xmm0, [rsi + VEC3_Z]
    mulsd xmm0, [rsp]
    call floor
    cvttsd2si rdx, xmm0

    add rax, rcx
    add rax, rdx
    and rax, 1
    cmp rax, 0
    je .use_color1
    jmp .use_color2

.stripe:
    movsd xmm3, [rdi + MAT_TEX_SCALE]
    movsd [rsp], xmm3

    movsd xmm0, [rsi + VEC3_X]
    mulsd xmm0, [rsp]
    call floor
    cvttsd2si rax, xmm0
    and rax, 1
    cmp rax, 0
    je .use_color1
    jmp .use_color2

.use_color1:
    movsd xmm0, [rdi + MAT_TEX_COLOR1 + VEC3_X]
    movsd [r8 + VEC3_X], xmm0
    movsd xmm0, [rdi + MAT_TEX_COLOR1 + VEC3_Y]
    movsd [r8 + VEC3_Y], xmm0
    movsd xmm0, [rdi + MAT_TEX_COLOR1 + VEC3_Z]
    movsd [r8 + VEC3_Z], xmm0
    leave
    ret

.use_color2:
    movsd xmm0, [rdi + MAT_TEX_COLOR2 + VEC3_X]
    movsd [r8 + VEC3_X], xmm0
    movsd xmm0, [rdi + MAT_TEX_COLOR2 + VEC3_Y]
    movsd [r8 + VEC3_Y], xmm0
    movsd xmm0, [rdi + MAT_TEX_COLOR2 + VEC3_Z]
    movsd [r8 + VEC3_Z], xmm0
    leave
    ret
