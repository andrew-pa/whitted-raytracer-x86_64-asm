%include "src/asm/defines.inc"

default rel

extern vec3_sub
extern vec3_dot
extern vec3_add_scaled
extern vec3_scale

section .rodata
const_zero: dq 0.0
const_one: dq 1.0
const_eps: dq 0.0001
abs_mask: dq 0x7fffffffffffffff, 0x7fffffffffffffff

section .text

global hit_sphere
hit_sphere:
    ; rdi = ray*, rsi = object*, xmm0 = t_min, xmm1 = t_max, rdx = hitrec*
    push rbp
    mov rbp, rsp
    sub rsp, 160

    mov r8, rdi
    mov r9, rsi
    mov r10, rdx

    movsd [rsp + 120], xmm0
    movsd [rsp + 128], xmm1

    ; oc = ray.origin - center
    lea rdi, [rsp + 0]
    lea rsi, [r8 + RAY_ORIGIN]
    lea rdx, [r9 + OBJ_SPH_CENTER]
    call vec3_sub

    ; a = dot(dir, dir)
    lea rdi, [r8 + RAY_DIR]
    lea rsi, [r8 + RAY_DIR]
    call vec3_dot
    movsd [rsp + 136], xmm0

    ; half_b = dot(oc, dir)
    lea rdi, [rsp + 0]
    lea rsi, [r8 + RAY_DIR]
    call vec3_dot
    movsd [rsp + 144], xmm0

    ; c = dot(oc, oc) - r^2
    lea rdi, [rsp + 0]
    lea rsi, [rsp + 0]
    call vec3_dot
    movsd xmm1, [r9 + OBJ_SPH_RADIUS]
    mulsd xmm1, xmm1
    subsd xmm0, xmm1
    movsd [rsp + 152], xmm0

    ; discriminant = half_b^2 - a*c
    movsd xmm0, [rsp + 144]
    mulsd xmm0, xmm0
    movsd xmm1, [rsp + 136]
    mulsd xmm1, [rsp + 152]
    subsd xmm0, xmm1
    xorpd xmm2, xmm2
    ucomisd xmm0, xmm2
    jb .no_hit

    sqrtsd xmm3, xmm0

    ; t = (-half_b - sqrt_disc) / a
    movsd xmm0, [rsp + 144]
    xorpd xmm1, xmm1
    subsd xmm1, xmm0
    subsd xmm1, xmm3
    divsd xmm1, [rsp + 136]
    movsd [rsp + 112], xmm1

    movsd xmm0, [rsp + 112]
    movsd xmm1, [rsp + 120]
    ucomisd xmm0, xmm1
    jb .try_second
    movsd xmm1, [rsp + 128]
    ucomisd xmm0, xmm1
    ja .try_second
    jmp .hit

.try_second:
    ; t = (-half_b + sqrt_disc) / a
    movsd xmm0, [rsp + 144]
    xorpd xmm1, xmm1
    subsd xmm1, xmm0
    addsd xmm1, xmm3
    divsd xmm1, [rsp + 136]
    movsd [rsp + 112], xmm1

    movsd xmm0, [rsp + 112]
    movsd xmm1, [rsp + 120]
    ucomisd xmm0, xmm1
    jb .no_hit
    movsd xmm1, [rsp + 128]
    ucomisd xmm0, xmm1
    ja .no_hit

.hit:
    movsd xmm0, [rsp + 112]
    movsd [r10 + HIT_T], xmm0

    ; point = origin + dir * t
    lea rdi, [r10 + HIT_POINT]
    lea rsi, [r8 + RAY_ORIGIN]
    lea rdx, [r8 + RAY_DIR]
    movsd xmm0, [rsp + 112]
    call vec3_add_scaled

    ; normal = (point - center) / radius
    lea rdi, [r10 + HIT_NORMAL]
    lea rsi, [r10 + HIT_POINT]
    lea rdx, [r9 + OBJ_SPH_CENTER]
    call vec3_sub
    movsd xmm0, [const_one]
    divsd xmm0, [r9 + OBJ_SPH_RADIUS]
    lea rdi, [r10 + HIT_NORMAL]
    lea rsi, [r10 + HIT_NORMAL]
    call vec3_scale

    mov eax, 1
    leave
    ret

.no_hit:
    xor eax, eax
    leave
    ret


global hit_cube
hit_cube:
    ; rdi = ray*, rsi = object*, xmm0 = t_min, xmm1 = t_max, rdx = hitrec*
    push rbp
    mov rbp, rsp
    sub rsp, 160

    mov r8, rdi
    mov r9, rsi
    mov r10, rdx

    movsd [rsp + 120], xmm0
    movsd [rsp + 128], xmm1

    ; X axis slabs
    movsd xmm0, [r9 + OBJ_BOX_MIN + VEC3_X]
    subsd xmm0, [r8 + RAY_ORIGIN + VEC3_X]
    divsd xmm0, [r8 + RAY_DIR + VEC3_X]
    movsd xmm1, [r9 + OBJ_BOX_MAX + VEC3_X]
    subsd xmm1, [r8 + RAY_ORIGIN + VEC3_X]
    divsd xmm1, [r8 + RAY_DIR + VEC3_X]

    movsd xmm4, [r8 + RAY_DIR + VEC3_X]
    xorpd xmm5, xmm5
    ucomisd xmm4, xmm5
    jae .x_noswap
    movapd xmm6, xmm0
    movapd xmm0, xmm1
    movapd xmm1, xmm6
.x_noswap:
    movapd xmm2, xmm0 ; tmin
    movapd xmm3, xmm1 ; tmax

    ; Y axis slabs
    movsd xmm0, [r9 + OBJ_BOX_MIN + VEC3_Y]
    subsd xmm0, [r8 + RAY_ORIGIN + VEC3_Y]
    divsd xmm0, [r8 + RAY_DIR + VEC3_Y]
    movsd xmm1, [r9 + OBJ_BOX_MAX + VEC3_Y]
    subsd xmm1, [r8 + RAY_ORIGIN + VEC3_Y]
    divsd xmm1, [r8 + RAY_DIR + VEC3_Y]

    movsd xmm4, [r8 + RAY_DIR + VEC3_Y]
    xorpd xmm5, xmm5
    ucomisd xmm4, xmm5
    jae .y_noswap
    movapd xmm6, xmm0
    movapd xmm0, xmm1
    movapd xmm1, xmm6
.y_noswap:
    maxsd xmm2, xmm0
    minsd xmm3, xmm1

    ; Z axis slabs
    movsd xmm0, [r9 + OBJ_BOX_MIN + VEC3_Z]
    subsd xmm0, [r8 + RAY_ORIGIN + VEC3_Z]
    divsd xmm0, [r8 + RAY_DIR + VEC3_Z]
    movsd xmm1, [r9 + OBJ_BOX_MAX + VEC3_Z]
    subsd xmm1, [r8 + RAY_ORIGIN + VEC3_Z]
    divsd xmm1, [r8 + RAY_DIR + VEC3_Z]

    movsd xmm4, [r8 + RAY_DIR + VEC3_Z]
    xorpd xmm5, xmm5
    ucomisd xmm4, xmm5
    jae .z_noswap
    movapd xmm6, xmm0
    movapd xmm0, xmm1
    movapd xmm1, xmm6
.z_noswap:
    maxsd xmm2, xmm0
    minsd xmm3, xmm1

    ; if tmax < tmin -> no hit
    ucomisd xmm3, xmm2
    jb .no_hit_cube

    ; choose t
    movsd xmm0, xmm2
    movsd xmm1, [rsp + 120]
    ucomisd xmm0, xmm1
    jae .t_ok
    movsd xmm0, xmm3
.t_ok:
    movsd xmm1, [rsp + 120]
    ucomisd xmm0, xmm1
    jb .no_hit_cube
    movsd xmm1, [rsp + 128]
    ucomisd xmm0, xmm1
    ja .no_hit_cube

    movsd [r10 + HIT_T], xmm0

    ; point = origin + dir * t
    lea rdi, [r10 + HIT_POINT]
    lea rsi, [r8 + RAY_ORIGIN]
    lea rdx, [r8 + RAY_DIR]
    movsd xmm0, [r10 + HIT_T]
    call vec3_add_scaled

    ; default normal = 0
    xorpd xmm0, xmm0
    movsd [r10 + HIT_NORMAL + VEC3_X], xmm0
    movsd [r10 + HIT_NORMAL + VEC3_Y], xmm0
    movsd [r10 + HIT_NORMAL + VEC3_Z], xmm0

    ; Determine normal by face proximity
    movsd xmm0, [r10 + HIT_POINT + VEC3_X]
    subsd xmm0, [r9 + OBJ_BOX_MIN + VEC3_X]
    andpd xmm0, [abs_mask]
    ucomisd xmm0, [const_eps]
    jae .check_xmax
    movsd xmm0, [const_one]
    xorpd xmm1, xmm1
    subsd xmm1, xmm0
    movsd [r10 + HIT_NORMAL + VEC3_X], xmm1
    jmp .normal_done

.check_xmax:
    movsd xmm0, [r10 + HIT_POINT + VEC3_X]
    subsd xmm0, [r9 + OBJ_BOX_MAX + VEC3_X]
    andpd xmm0, [abs_mask]
    ucomisd xmm0, [const_eps]
    jae .check_ymin
    movsd xmm0, [const_one]
    movsd [r10 + HIT_NORMAL + VEC3_X], xmm0
    jmp .normal_done

.check_ymin:
    movsd xmm0, [r10 + HIT_POINT + VEC3_Y]
    subsd xmm0, [r9 + OBJ_BOX_MIN + VEC3_Y]
    andpd xmm0, [abs_mask]
    ucomisd xmm0, [const_eps]
    jae .check_ymax
    movsd xmm0, [const_one]
    xorpd xmm1, xmm1
    subsd xmm1, xmm0
    movsd [r10 + HIT_NORMAL + VEC3_Y], xmm1
    jmp .normal_done

.check_ymax:
    movsd xmm0, [r10 + HIT_POINT + VEC3_Y]
    subsd xmm0, [r9 + OBJ_BOX_MAX + VEC3_Y]
    andpd xmm0, [abs_mask]
    ucomisd xmm0, [const_eps]
    jae .check_zmin
    movsd xmm0, [const_one]
    movsd [r10 + HIT_NORMAL + VEC3_Y], xmm0
    jmp .normal_done

.check_zmin:
    movsd xmm0, [r10 + HIT_POINT + VEC3_Z]
    subsd xmm0, [r9 + OBJ_BOX_MIN + VEC3_Z]
    andpd xmm0, [abs_mask]
    ucomisd xmm0, [const_eps]
    jae .check_zmax
    movsd xmm0, [const_one]
    xorpd xmm1, xmm1
    subsd xmm1, xmm0
    movsd [r10 + HIT_NORMAL + VEC3_Z], xmm1
    jmp .normal_done

.check_zmax:
    movsd xmm0, [r10 + HIT_POINT + VEC3_Z]
    subsd xmm0, [r9 + OBJ_BOX_MAX + VEC3_Z]
    andpd xmm0, [abs_mask]
    ucomisd xmm0, [const_eps]
    jae .normal_done
    movsd xmm0, [const_one]
    movsd [r10 + HIT_NORMAL + VEC3_Z], xmm0

.normal_done:
    mov eax, 1
    leave
    ret

.no_hit_cube:
    xor eax, eax
    leave
    ret
