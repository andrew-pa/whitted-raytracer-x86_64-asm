%include "src/asm/defines.inc"

default rel

extern vec3_sub
extern vec3_add
extern vec3_scale
extern vec3_normalize
extern vec3_cross
extern vec3_copy
extern vec3_clamp01
extern vec3_tonemap_reinhard
extern trace_ray
extern tan

extern camera_pos
extern camera_lookat
extern camera_up
extern camera_fov
extern cam_forward
extern cam_right
extern cam_true_up
extern exposure

section .rodata
const_one: dq 1.0
const_half: dq 0.5
const_two: dq 2.0
const_255: dq 255.0
const_deg2rad: dq 0.017453292519943295

section .text

global compute_camera_basis
compute_camera_basis:
    ; Build orthonormal camera basis vectors
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; forward = normalize(lookat - pos)
    lea rdi, [rsp + 0]
    lea rsi, [rel camera_lookat]
    lea rdx, [rel camera_pos]
    call vec3_sub
    lea rdi, [rel cam_forward]
    lea rsi, [rsp + 0]
    call vec3_normalize

    ; right = normalize(cross(forward, up))
    lea rdi, [rsp + 24]
    lea rsi, [rel cam_forward]
    lea rdx, [rel camera_up]
    call vec3_cross
    lea rdi, [rel cam_right]
    lea rsi, [rsp + 24]
    call vec3_normalize

    ; true_up = cross(right, forward)
    lea rdi, [rel cam_true_up]
    lea rsi, [rel cam_right]
    lea rdx, [rel cam_forward]
    call vec3_cross

    leave
    ret


global render_image
render_image:
    ; rdi = buffer, rsi = width, rdx = height
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 328

    mov r12, rdi
    mov r13d, esi
    mov r14d, edx

    call compute_camera_basis

    ; scale = tan(fov * 0.5 * deg2rad)
    movsd xmm0, [rel camera_fov]
    mulsd xmm0, [const_deg2rad]
    mulsd xmm0, [const_half]
    call tan
    movsd [rsp + 0], xmm0

    ; width/height as doubles
    cvtsi2sd xmm0, r13d
    movsd [rsp + 16], xmm0
    cvtsi2sd xmm1, r14d
    movsd [rsp + 24], xmm1

    ; aspect = width / height
    movsd xmm0, [rsp + 16]
    divsd xmm0, [rsp + 24]
    movsd [rsp + 8], xmm0

    ; inv_w and inv_h
    movsd xmm0, [const_one]
    divsd xmm0, [rsp + 16]
    movsd [rsp + 32], xmm0
    movsd xmm0, [const_one]
    divsd xmm0, [rsp + 24]
    movsd [rsp + 40], xmm0

    ; bytes per row = width * 3
    mov r11d, r13d
    imul r11d, 3
    mov dword [rsp + 64], r11d

    xor r15d, r15d ; y = 0
.y_loop:
    cmp r15d, r14d
    jge .done

    ; row_base = buffer + y * row_stride
    mov eax, r15d
    imul eax, dword [rsp + 64]
    mov rbx, r12
    add rbx, rax

    xor r10d, r10d ; x = 0
.x_loop:
    cmp r10d, r13d
    jge .next_row

    ; u = ((x + 0.5) * inv_w * 2 - 1) * aspect * scale
    cvtsi2sd xmm0, r10d
    addsd xmm0, [const_half]
    mulsd xmm0, [rsp + 32]
    mulsd xmm0, [const_two]
    subsd xmm0, [const_one]
    mulsd xmm0, [rsp + 8]
    mulsd xmm0, [rsp + 0]
    movsd [rsp + 48], xmm0

    ; v = (1 - (y + 0.5) * inv_h * 2) * scale
    cvtsi2sd xmm1, r15d
    addsd xmm1, [const_half]
    mulsd xmm1, [rsp + 40]
    mulsd xmm1, [const_two]
    movsd xmm2, [const_one]
    subsd xmm2, xmm1
    mulsd xmm2, [rsp + 0]
    movsd [rsp + 56], xmm2

    ; temp1 = right * u
    lea rdi, [rsp + 176]
    lea rsi, [rel cam_right]
    movsd xmm0, [rsp + 48]
    call vec3_scale

    ; temp2 = up * v
    lea rdi, [rsp + 200]
    lea rsi, [rel cam_true_up]
    movsd xmm0, [rsp + 56]
    call vec3_scale

    ; dir = forward + temp1
    lea rdi, [rsp + 224]
    lea rsi, [rel cam_forward]
    lea rdx, [rsp + 176]
    call vec3_add

    ; dir = dir + temp2
    lea rdi, [rsp + 224]
    lea rsi, [rsp + 224]
    lea rdx, [rsp + 200]
    call vec3_add

    ; normalize dir into ray.dir
    lea rdi, [rsp + 96 + RAY_DIR]
    lea rsi, [rsp + 224]
    call vec3_normalize

    ; ray.origin = camera_pos
    lea rdi, [rsp + 96 + RAY_ORIGIN]
    lea rsi, [rel camera_pos]
    call vec3_copy

    ; trace ray (save x since r10 is caller-saved)
    mov dword [rsp + 72], r10d
    lea rdi, [rsp + 96]
    xor esi, esi
    lea rdx, [rsp + 144]
    call trace_ray

    ; tone map then clamp to [0,1]
    lea rdi, [rsp + 144]
    lea rsi, [rsp + 144]
    movsd xmm0, [rel exposure]
    call vec3_tonemap_reinhard

    lea rdi, [rsp + 144]
    lea rsi, [rsp + 144]
    call vec3_clamp01
    mov r10d, dword [rsp + 72]

    ; pixel_ptr = row_base + x*3
    mov eax, r10d
    imul eax, 3
    lea r9, [rbx + rax]

    ; write RGB bytes
    movsd xmm0, [rsp + 144 + VEC3_X]
    mulsd xmm0, [const_255]
    addsd xmm0, [const_half]
    cvttsd2si eax, xmm0
    mov byte [r9], al

    movsd xmm0, [rsp + 144 + VEC3_Y]
    mulsd xmm0, [const_255]
    addsd xmm0, [const_half]
    cvttsd2si eax, xmm0
    mov byte [r9 + 1], al

    movsd xmm0, [rsp + 144 + VEC3_Z]
    mulsd xmm0, [const_255]
    addsd xmm0, [const_half]
    cvttsd2si eax, xmm0
    mov byte [r9 + 2], al

    inc r10d
    jmp .x_loop

.next_row:
    inc r15d
    jmp .y_loop

.done:
    add rsp, 328
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
