%include "src/asm/defines.inc"

default rel

extern hit_sphere
extern hit_cube
extern vec3_sub
extern vec3_add
extern vec3_add_scaled
extern vec3_scale
extern vec3_dot
extern vec3_length
extern vec3_mul
extern vec3_reflect
extern vec3_copy
extern vec3_normalize
extern texture_sample
extern pow

extern objects
extern object_count
extern materials
extern lights
extern light_count
extern ambient_color
extern background_color
extern max_depth

section .rodata
const_zero: dq 0.0
const_one: dq 1.0
const_neg_one: dq -1.0
const_eps: dq 0.0001
const_big: dq 1.0e30

section .text

global scene_intersect
scene_intersect:
    ; rdi = ray*, xmm0 = t_min, xmm1 = t_max, rsi = hitrec*
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 176

    mov r8, rdi
    mov r9, rsi

    movsd [rsp + 0], xmm0   ; t_min
    movsd [rsp + 8], xmm1   ; best_t

    xor ebx, ebx            ; hit_any = 0
    xor ecx, ecx            ; i = 0

.loop_objects:
    mov eax, dword [object_count]
    cmp ecx, eax
    jge .done

    mov edx, ecx
    imul edx, OBJ_SIZE
    lea rsi, [rel objects]
    lea r12, [rsi + rdx]

    mov eax, dword [r12 + OBJ_TYPE]
    cmp eax, OBJ_SPHERE
    jne .check_cube

    ; call hit_sphere(ray, obj, t_min, best_t, temp_hit)
    lea rdx, [rsp + 32]
    mov rdi, r8
    mov rsi, r12
    movsd xmm0, [rsp + 0]
    movsd xmm1, [rsp + 8]
    call hit_sphere
    test eax, eax
    jz .next
    jmp .record_hit

.check_cube:
    cmp eax, OBJ_CUBE
    jne .next

    lea rdx, [rsp + 32]
    mov rdi, r8
    mov rsi, r12
    movsd xmm0, [rsp + 0]
    movsd xmm1, [rsp + 8]
    call hit_cube
    test eax, eax
    jz .next

.record_hit:
    ; best_t = temp_hit.t
    movsd xmm0, [rsp + 32 + HIT_T]
    movsd [rsp + 8], xmm0

    ; copy hit record
    mov [rsp + 16], ecx
    mov rax, r9
    lea rsi, [rsp + 32]
    mov rcx, HIT_SIZE / 8
.copy_loop:
    mov rdx, [rsi]
    mov [rax], rdx
    add rsi, 8
    add rax, 8
    loop .copy_loop
    mov ecx, [rsp + 16]

    ; store material index and object type
    mov eax, dword [r12 + OBJ_MAT_INDEX]
    mov [r9 + HIT_MAT_INDEX], eax
    mov eax, dword [r12 + OBJ_TYPE]
    mov [r9 + HIT_OBJ_TYPE], eax

    mov ebx, 1

.next:
    inc ecx
    jmp .loop_objects

.done:
    mov eax, ebx
    add rsp, 176
    pop r12
    pop rbx
    leave
    ret

%define OFF_HIT 0
%define OFF_BASE 64
%define OFF_ACCUM 88
%define OFF_TO_LIGHT 112
%define OFF_LIGHT_DIR 136
%define OFF_TMP 160
%define OFF_VIEW 184
%define OFF_REFLECT_DIR 208
%define OFF_SHADOW_RAY 232
%define OFF_REFLECT_RAY 280
%define OFF_REFLECT_COLOR 328
%define OFF_DIST 352
%define OFF_DIFF_SCALE 360
%define OFF_SPEC_SCALE 368


global trace_ray
trace_ray:
    ; rdi = ray*, esi = depth, rdx = out_color*
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 392

    mov r12, rdi
    mov r13, rdx
    mov r14d, esi

    mov eax, dword [max_depth]
    cmp r14d, eax
    jge .background

    ; find closest hit
    lea rsi, [rsp + OFF_HIT]
    mov rdi, r12
    movsd xmm0, [const_eps]
    movsd xmm1, [const_big]
    call scene_intersect
    test eax, eax
    jz .background

    ; material pointer
    mov eax, dword [rsp + OFF_HIT + HIT_MAT_INDEX]
    imul eax, MAT_SIZE
    lea rbx, [rel materials]
    add rbx, rax

    ; base_color = texture(material, hit.point)
    lea rdi, [rbx]
    lea rsi, [rsp + OFF_HIT + HIT_POINT]
    lea rdx, [rsp + OFF_BASE]
    call texture_sample

    ; accum = ambient * base_color
    lea rdi, [rsp + OFF_ACCUM]
    lea rsi, [rel ambient_color]
    lea rdx, [rsp + OFF_BASE]
    call vec3_mul

    ; loop lights
    xor r15d, r15d
.light_loop:
    mov eax, dword [light_count]
    cmp r15d, eax
    jge .reflection

    mov ecx, r15d
    imul ecx, LIGHT_SIZE
    lea r11, [rel lights]
    add r11, rcx

    ; to_light = light.pos - hit.point
    lea rdi, [rsp + OFF_TO_LIGHT]
    lea rsi, [r11 + LIGHT_POS]
    lea rdx, [rsp + OFF_HIT + HIT_POINT]
    call vec3_sub

    ; dist = length(to_light)
    lea rdi, [rsp + OFF_TO_LIGHT]
    call vec3_length
    movsd [rsp + OFF_DIST], xmm0

    ; light_dir = to_light / dist
    movsd xmm1, [const_one]
    divsd xmm1, [rsp + OFF_DIST]
    lea rdi, [rsp + OFF_LIGHT_DIR]
    lea rsi, [rsp + OFF_TO_LIGHT]
    movsd xmm0, xmm1
    call vec3_scale

    ; shadow ray origin = hit.point + normal * eps
    lea rdi, [rsp + OFF_SHADOW_RAY + RAY_ORIGIN]
    lea rsi, [rsp + OFF_HIT + HIT_POINT]
    lea rdx, [rsp + OFF_HIT + HIT_NORMAL]
    movsd xmm0, [const_eps]
    call vec3_add_scaled

    ; shadow ray dir = light_dir
    lea rdi, [rsp + OFF_SHADOW_RAY + RAY_DIR]
    lea rsi, [rsp + OFF_LIGHT_DIR]
    call vec3_copy

    ; shadow test
    lea rsi, [rsp + OFF_REFLECT_COLOR]
    lea rdi, [rsp + OFF_SHADOW_RAY]
    movsd xmm0, [const_eps]
    movsd xmm1, [rsp + OFF_DIST]
    subsd xmm1, [const_eps]
    call scene_intersect
    test eax, eax
    jnz .next_light

    ; diffuse term
    lea rdi, [rsp + OFF_HIT + HIT_NORMAL]
    lea rsi, [rsp + OFF_LIGHT_DIR]
    call vec3_dot
    movsd xmm1, [const_zero]
    ucomisd xmm0, xmm1
    jbe .next_light

    ; scale = intensity * diff
    movsd xmm1, [r11 + LIGHT_INTENSITY]
    mulsd xmm0, xmm1
    movsd [rsp + OFF_DIFF_SCALE], xmm0

    ; tmp = base_color * light.color
    lea rdi, [rsp + OFF_TMP]
    lea rsi, [rsp + OFF_BASE]
    lea rdx, [r11 + LIGHT_COLOR]
    call vec3_mul

    ; tmp *= scale
    lea rdi, [rsp + OFF_TMP]
    lea rsi, [rsp + OFF_TMP]
    movsd xmm0, [rsp + OFF_DIFF_SCALE]
    call vec3_scale

    ; accum += tmp
    lea rdi, [rsp + OFF_ACCUM]
    lea rsi, [rsp + OFF_ACCUM]
    lea rdx, [rsp + OFF_TMP]
    call vec3_add

    ; specular term
    ; view_dir = -ray.dir
    lea rdi, [rsp + OFF_VIEW]
    lea rsi, [r12 + RAY_DIR]
    movsd xmm0, [const_neg_one]
    call vec3_scale

    ; neg_light = -light_dir (reuse tmp)
    lea rdi, [rsp + OFF_TMP]
    lea rsi, [rsp + OFF_LIGHT_DIR]
    movsd xmm0, [const_neg_one]
    call vec3_scale

    ; reflect_dir = reflect(neg_light, normal)
    lea rdi, [rsp + OFF_REFLECT_DIR]
    lea rsi, [rsp + OFF_TMP]
    lea rdx, [rsp + OFF_HIT + HIT_NORMAL]
    call vec3_reflect

    ; spec_angle = max(dot(reflect_dir, view_dir), 0)
    lea rdi, [rsp + OFF_REFLECT_DIR]
    lea rsi, [rsp + OFF_VIEW]
    call vec3_dot
    movsd xmm1, [const_zero]
    ucomisd xmm0, xmm1
    jbe .next_light

    ; spec = pow(spec_angle, shininess) * intensity
    movsd xmm1, [rbx + MAT_SHININESS]
    call pow
    mulsd xmm0, [r11 + LIGHT_INTENSITY]
    movsd [rsp + OFF_SPEC_SCALE], xmm0

    ; spec_color = material.spec * light.color
    lea rdi, [rsp + OFF_TMP]
    lea rsi, [rbx + MAT_SPEC]
    lea rdx, [r11 + LIGHT_COLOR]
    call vec3_mul

    ; spec_color *= spec
    lea rdi, [rsp + OFF_TMP]
    lea rsi, [rsp + OFF_TMP]
    movsd xmm0, [rsp + OFF_SPEC_SCALE]
    call vec3_scale

    ; accum += spec_color
    lea rdi, [rsp + OFF_ACCUM]
    lea rsi, [rsp + OFF_ACCUM]
    lea rdx, [rsp + OFF_TMP]
    call vec3_add

.next_light:
    inc r15d
    jmp .light_loop

.reflection:
    ; handle reflections
    movsd xmm0, [rbx + MAT_REFLECT]
    movsd xmm1, [const_zero]
    ucomisd xmm0, xmm1
    jbe .store_color

    mov eax, dword [max_depth]
    cmp r14d, eax
    jge .store_color

    ; reflect_dir = reflect(ray.dir, normal)
    lea rdi, [rsp + OFF_REFLECT_DIR]
    lea rsi, [r12 + RAY_DIR]
    lea rdx, [rsp + OFF_HIT + HIT_NORMAL]
    call vec3_reflect

    ; reflect ray origin = hit.point + normal * eps
    lea rdi, [rsp + OFF_REFLECT_RAY + RAY_ORIGIN]
    lea rsi, [rsp + OFF_HIT + HIT_POINT]
    lea rdx, [rsp + OFF_HIT + HIT_NORMAL]
    movsd xmm0, [const_eps]
    call vec3_add_scaled

    ; reflect ray dir
    lea rdi, [rsp + OFF_REFLECT_RAY + RAY_DIR]
    lea rsi, [rsp + OFF_REFLECT_DIR]
    call vec3_copy

    ; trace reflection
    lea rdi, [rsp + OFF_REFLECT_RAY]
    mov esi, r14d
    inc esi
    lea rdx, [rsp + OFF_REFLECT_COLOR]
    call trace_ray

    ; refl_color *= reflectivity
    lea rdi, [rsp + OFF_REFLECT_COLOR]
    lea rsi, [rsp + OFF_REFLECT_COLOR]
    movsd xmm0, [rbx + MAT_REFLECT]
    call vec3_scale

    ; accum += refl_color
    lea rdi, [rsp + OFF_ACCUM]
    lea rsi, [rsp + OFF_ACCUM]
    lea rdx, [rsp + OFF_REFLECT_COLOR]
    call vec3_add

.store_color:
    lea rdi, [r13]
    lea rsi, [rsp + OFF_ACCUM]
    call vec3_copy
    jmp .done

.background:
    lea rdi, [r13]
    lea rsi, [rel background_color]
    call vec3_copy

.done:
    add rsp, 392
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
