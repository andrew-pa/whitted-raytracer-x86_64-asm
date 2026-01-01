%include "src/asm/defines.inc"

default rel

section .rodata
align 16
const_zero: dq 0.0
const_one: dq 1.0
const_two: dq 2.0

section .text

global vec3_set
vec3_set:
    ; Store xmm0..xmm2 into dest vector
    movsd [rdi + VEC3_X], xmm0
    movsd [rdi + VEC3_Y], xmm1
    movsd [rdi + VEC3_Z], xmm2
    ret

global vec3_copy
vec3_copy:
    ; Copy vector src -> dest
    movsd xmm0, [rsi + VEC3_X]
    movsd xmm1, [rsi + VEC3_Y]
    movsd xmm2, [rsi + VEC3_Z]
    movsd [rdi + VEC3_X], xmm0
    movsd [rdi + VEC3_Y], xmm1
    movsd [rdi + VEC3_Z], xmm2
    ret

global vec3_add
vec3_add:
    ; dest = a + b
    movsd xmm0, [rsi + VEC3_X]
    addsd xmm0, [rdx + VEC3_X]
    movsd [rdi + VEC3_X], xmm0

    movsd xmm1, [rsi + VEC3_Y]
    addsd xmm1, [rdx + VEC3_Y]
    movsd [rdi + VEC3_Y], xmm1

    movsd xmm2, [rsi + VEC3_Z]
    addsd xmm2, [rdx + VEC3_Z]
    movsd [rdi + VEC3_Z], xmm2
    ret

global vec3_sub
vec3_sub:
    ; dest = a - b
    movsd xmm0, [rsi + VEC3_X]
    subsd xmm0, [rdx + VEC3_X]
    movsd [rdi + VEC3_X], xmm0

    movsd xmm1, [rsi + VEC3_Y]
    subsd xmm1, [rdx + VEC3_Y]
    movsd [rdi + VEC3_Y], xmm1

    movsd xmm2, [rsi + VEC3_Z]
    subsd xmm2, [rdx + VEC3_Z]
    movsd [rdi + VEC3_Z], xmm2
    ret

global vec3_scale
vec3_scale:
    ; dest = a * scale
    movsd xmm1, [rsi + VEC3_X]
    mulsd xmm1, xmm0
    movsd [rdi + VEC3_X], xmm1

    movsd xmm1, [rsi + VEC3_Y]
    mulsd xmm1, xmm0
    movsd [rdi + VEC3_Y], xmm1

    movsd xmm1, [rsi + VEC3_Z]
    mulsd xmm1, xmm0
    movsd [rdi + VEC3_Z], xmm1
    ret

global vec3_mul
vec3_mul:
    ; dest = a * b (component-wise)
    movsd xmm0, [rsi + VEC3_X]
    mulsd xmm0, [rdx + VEC3_X]
    movsd [rdi + VEC3_X], xmm0

    movsd xmm1, [rsi + VEC3_Y]
    mulsd xmm1, [rdx + VEC3_Y]
    movsd [rdi + VEC3_Y], xmm1

    movsd xmm2, [rsi + VEC3_Z]
    mulsd xmm2, [rdx + VEC3_Z]
    movsd [rdi + VEC3_Z], xmm2
    ret

global vec3_dot
vec3_dot:
    ; dot = a.x*b.x + a.y*b.y + a.z*b.z
    movsd xmm0, [rdi + VEC3_X]
    mulsd xmm0, [rsi + VEC3_X]

    movsd xmm1, [rdi + VEC3_Y]
    mulsd xmm1, [rsi + VEC3_Y]
    addsd xmm0, xmm1

    movsd xmm1, [rdi + VEC3_Z]
    mulsd xmm1, [rsi + VEC3_Z]
    addsd xmm0, xmm1
    ret

global vec3_length
vec3_length:
    ; length = sqrt(dot(a,a))
    mov rsi, rdi
    call vec3_dot
    sqrtsd xmm0, xmm0
    ret

global vec3_normalize
vec3_normalize:
    ; dest = normalize(src), returns length in xmm0
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 24

    mov rax, rdi
    mov rbx, rsi
    mov rdi, rbx
    mov rsi, rbx
    call vec3_length
    movsd [rsp], xmm0

    movsd xmm1, [rsp]
    xorpd xmm2, xmm2
    ucomisd xmm1, xmm2
    jbe .zero

    movsd xmm0, [const_one]
    divsd xmm0, xmm1
    mov rdi, rax
    mov rsi, rbx
    call vec3_scale
    movsd xmm0, [rsp]
    add rsp, 24
    pop rbx
    leave
    ret

.zero:
    xorpd xmm0, xmm0
    movsd [rax + VEC3_X], xmm0
    movsd [rax + VEC3_Y], xmm0
    movsd [rax + VEC3_Z], xmm0
    movsd xmm0, [rsp]
    add rsp, 24
    pop rbx
    leave
    ret

global vec3_add_scaled
vec3_add_scaled:
    ; dest = a + b * scale
    movsd xmm1, [rdx + VEC3_X]
    mulsd xmm1, xmm0
    addsd xmm1, [rsi + VEC3_X]
    movsd [rdi + VEC3_X], xmm1

    movsd xmm1, [rdx + VEC3_Y]
    mulsd xmm1, xmm0
    addsd xmm1, [rsi + VEC3_Y]
    movsd [rdi + VEC3_Y], xmm1

    movsd xmm1, [rdx + VEC3_Z]
    mulsd xmm1, xmm0
    addsd xmm1, [rsi + VEC3_Z]
    movsd [rdi + VEC3_Z], xmm1
    ret

global vec3_reflect
vec3_reflect:
    ; dest = dir - 2*dot(dir, normal)*normal
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 24

    mov rax, rdi
    mov rbx, rsi
    mov rcx, rdx
    mov rdi, rbx
    mov rsi, rcx
    call vec3_dot
    mulsd xmm0, [const_two]
    xorpd xmm1, xmm1
    subsd xmm1, xmm0
    movsd xmm0, xmm1
    mov rdi, rax
    mov rsi, rbx
    mov rdx, rcx
    call vec3_add_scaled

    add rsp, 24
    pop rbx
    leave
    ret

global clamp01
clamp01:
    ; Clamp xmm0 to [0,1]
    maxsd xmm0, [const_zero]
    minsd xmm0, [const_one]
    ret

global vec3_clamp01
vec3_clamp01:
    ; Clamp all components to [0,1]
    movsd xmm0, [rsi + VEC3_X]
    call clamp01
    movsd [rdi + VEC3_X], xmm0

    movsd xmm0, [rsi + VEC3_Y]
    call clamp01
    movsd [rdi + VEC3_Y], xmm0

    movsd xmm0, [rsi + VEC3_Z]
    call clamp01
    movsd [rdi + VEC3_Z], xmm0
    ret

global vec3_cross
vec3_cross:
    ; dest = a x b
    movsd xmm0, [rsi + VEC3_Y]
    mulsd xmm0, [rdx + VEC3_Z]
    movsd xmm1, [rsi + VEC3_Z]
    mulsd xmm1, [rdx + VEC3_Y]
    subsd xmm0, xmm1
    movsd [rdi + VEC3_X], xmm0

    movsd xmm0, [rsi + VEC3_Z]
    mulsd xmm0, [rdx + VEC3_X]
    movsd xmm1, [rsi + VEC3_X]
    mulsd xmm1, [rdx + VEC3_Z]
    subsd xmm0, xmm1
    movsd [rdi + VEC3_Y], xmm0

    movsd xmm0, [rsi + VEC3_X]
    mulsd xmm0, [rdx + VEC3_Y]
    movsd xmm1, [rsi + VEC3_Y]
    mulsd xmm1, [rdx + VEC3_X]
    subsd xmm0, xmm1
    movsd [rdi + VEC3_Z], xmm0
    ret

global vec3_tonemap_reinhard
vec3_tonemap_reinhard:
    ; dest = (src * exposure) / (1 + src * exposure)
    movsd xmm2, [rsi + VEC3_X]
    mulsd xmm2, xmm0
    movsd xmm3, [const_one]
    addsd xmm3, xmm2
    divsd xmm2, xmm3
    movsd [rdi + VEC3_X], xmm2

    movsd xmm2, [rsi + VEC3_Y]
    mulsd xmm2, xmm0
    movsd xmm3, [const_one]
    addsd xmm3, xmm2
    divsd xmm2, xmm3
    movsd [rdi + VEC3_Y], xmm2

    movsd xmm2, [rsi + VEC3_Z]
    mulsd xmm2, xmm0
    movsd xmm3, [const_one]
    addsd xmm3, xmm2
    divsd xmm2, xmm3
    movsd [rdi + VEC3_Z], xmm2
    ret
