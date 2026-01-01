%include "src/asm/defines.inc"

default rel

extern fscanf
extern fgets
extern stdin
extern strcmp

extern materials
extern material_count
extern objects
extern object_count
extern lights
extern light_count
extern camera_pos
extern camera_lookat
extern camera_up
extern camera_fov
extern image_width
extern image_height
extern max_depth
extern ambient_color
extern background_color

section .rodata
fmt_token:     db "%63s", 0
fmt_int:       db "%d", 0
fmt_double:    db "%lf", 0
fmt_color3:    db "%lf %lf %lf", 0

kw_image:      db "image", 0
kw_camera:     db "camera", 0
kw_ambient:    db "ambient", 0
kw_background: db "background", 0
kw_maxdepth:   db "maxdepth", 0
kw_material:   db "material", 0
kw_sphere:     db "sphere", 0
kw_cube:       db "cube", 0
kw_light:      db "light", 0

kw_tex_solid:   db "solid", 0
kw_tex_checker: db "checker", 0
kw_tex_stripe:  db "stripe", 0

section .bss
align 16
line_buf: resb 256
_token_buf: resb 64
_tex_buf: resb 64

section .text

global init_scene
init_scene:
    ; Defaults for a usable scene
    mov dword [image_width], 320
    mov dword [image_height], 240
    mov dword [max_depth], 3

    mov qword [camera_pos + VEC3_X], __float64__(0.0)
    mov qword [camera_pos + VEC3_Y], __float64__(1.0)
    mov qword [camera_pos + VEC3_Z], __float64__(-5.0)

    mov qword [camera_lookat + VEC3_X], __float64__(0.0)
    mov qword [camera_lookat + VEC3_Y], __float64__(0.0)
    mov qword [camera_lookat + VEC3_Z], __float64__(0.0)

    mov qword [camera_up + VEC3_X], __float64__(0.0)
    mov qword [camera_up + VEC3_Y], __float64__(1.0)
    mov qword [camera_up + VEC3_Z], __float64__(0.0)

    mov qword [camera_fov], __float64__(60.0)

    mov qword [ambient_color + VEC3_X], __float64__(0.05)
    mov qword [ambient_color + VEC3_Y], __float64__(0.05)
    mov qword [ambient_color + VEC3_Z], __float64__(0.05)

    mov qword [background_color + VEC3_X], __float64__(0.0)
    mov qword [background_color + VEC3_Y], __float64__(0.0)
    mov qword [background_color + VEC3_Z], __float64__(0.0)

    mov dword [material_count], 0
    mov dword [object_count], 0
    mov dword [light_count], 0
    ret

global parse_scene
parse_scene:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    call init_scene

.read_loop:
    ; Read next token
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_token]
    lea rdx, [rel _token_buf]
    xor eax, eax
    call fscanf
    cmp eax, 1
    jne .done

    ; Skip comments starting with '#'
    mov al, byte [_token_buf]
    cmp al, '#'
    jne .dispatch
    lea rdi, [rel line_buf]
    mov esi, 256
    lea rdx, [rel stdin]
    mov rdx, [rdx]
    call fgets
    jmp .read_loop

.dispatch:
    lea rdi, [rel _token_buf]
    lea rsi, [rel kw_image]
    call strcmp
    test eax, eax
    jne .check_camera
    call parse_image
    jmp .read_loop

.check_camera:
    lea rdi, [rel _token_buf]
    lea rsi, [rel kw_camera]
    call strcmp
    test eax, eax
    jne .check_ambient
    call parse_camera
    jmp .read_loop

.check_ambient:
    lea rdi, [rel _token_buf]
    lea rsi, [rel kw_ambient]
    call strcmp
    test eax, eax
    jne .check_background
    call parse_ambient
    jmp .read_loop

.check_background:
    lea rdi, [rel _token_buf]
    lea rsi, [rel kw_background]
    call strcmp
    test eax, eax
    jne .check_maxdepth
    call parse_background
    jmp .read_loop

.check_maxdepth:
    lea rdi, [rel _token_buf]
    lea rsi, [rel kw_maxdepth]
    call strcmp
    test eax, eax
    jne .check_material
    call parse_maxdepth
    jmp .read_loop

.check_material:
    lea rdi, [rel _token_buf]
    lea rsi, [rel kw_material]
    call strcmp
    test eax, eax
    jne .check_sphere
    call parse_material
    jmp .read_loop

.check_sphere:
    lea rdi, [rel _token_buf]
    lea rsi, [rel kw_sphere]
    call strcmp
    test eax, eax
    jne .check_cube
    call parse_sphere
    jmp .read_loop

.check_cube:
    lea rdi, [rel _token_buf]
    lea rsi, [rel kw_cube]
    call strcmp
    test eax, eax
    jne .check_light
    call parse_cube
    jmp .read_loop

.check_light:
    lea rdi, [rel _token_buf]
    lea rsi, [rel kw_light]
    call strcmp
    test eax, eax
    jne .read_loop
    call parse_light
    jmp .read_loop

.done:
    leave
    ret

; --- Parse helpers ----------------------------------------------------------

global parse_image
parse_image:
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_int]
    lea rdx, [rel image_width]
    xor eax, eax
    call fscanf

    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_int]
    lea rdx, [rel image_height]
    xor eax, eax
    call fscanf
    ret

global parse_camera
parse_camera:
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rel camera_pos + VEC3_X]
    lea rcx, [rel camera_pos + VEC3_Y]
    lea r8,  [rel camera_pos + VEC3_Z]
    xor eax, eax
    call fscanf

    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rel camera_lookat + VEC3_X]
    lea rcx, [rel camera_lookat + VEC3_Y]
    lea r8,  [rel camera_lookat + VEC3_Z]
    xor eax, eax
    call fscanf

    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rel camera_up + VEC3_X]
    lea rcx, [rel camera_up + VEC3_Y]
    lea r8,  [rel camera_up + VEC3_Z]
    xor eax, eax
    call fscanf

    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_double]
    lea rdx, [rel camera_fov]
    xor eax, eax
    call fscanf
    ret

global parse_ambient
parse_ambient:
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rel ambient_color + VEC3_X]
    lea rcx, [rel ambient_color + VEC3_Y]
    lea r8,  [rel ambient_color + VEC3_Z]
    xor eax, eax
    call fscanf
    ret

global parse_background
parse_background:
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rel background_color + VEC3_X]
    lea rcx, [rel background_color + VEC3_Y]
    lea r8,  [rel background_color + VEC3_Z]
    xor eax, eax
    call fscanf
    ret

global parse_maxdepth
parse_maxdepth:
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_int]
    lea rdx, [rel max_depth]
    xor eax, eax
    call fscanf
    ret

global parse_material
parse_material:
    push rbp
    mov rbp, rsp
    sub rsp, 80

    ; Read material id
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_int]
    lea rdx, [rsp + 0]
    xor eax, eax
    call fscanf

    mov eax, dword [rsp + 0]
    cmp eax, MAX_MATERIALS
    jae .done

    mov ecx, eax
    imul ecx, MAT_SIZE
    lea rbx, [rel materials]
    lea rbx, [rbx + rcx]

    ; Diffuse color
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rbx + MAT_DIFFUSE + VEC3_X]
    lea rcx, [rbx + MAT_DIFFUSE + VEC3_Y]
    lea r8,  [rbx + MAT_DIFFUSE + VEC3_Z]
    xor eax, eax
    call fscanf

    ; Specular color
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rbx + MAT_SPEC + VEC3_X]
    lea rcx, [rbx + MAT_SPEC + VEC3_Y]
    lea r8,  [rbx + MAT_SPEC + VEC3_Z]
    xor eax, eax
    call fscanf

    ; Shininess
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_double]
    lea rdx, [rbx + MAT_SHININESS]
    xor eax, eax
    call fscanf

    ; Reflectivity
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_double]
    lea rdx, [rbx + MAT_REFLECT]
    xor eax, eax
    call fscanf

    ; Texture type string
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_token]
    lea rdx, [rel _tex_buf]
    xor eax, eax
    call fscanf

    lea rdi, [rel _tex_buf]
    lea rsi, [rel kw_tex_solid]
    call strcmp
    test eax, eax
    jne .check_checker

    mov dword [rbx + MAT_TEX_TYPE], TEX_SOLID
    mov qword [rbx + MAT_TEX_SCALE], __float64__(1.0)
    ; Use diffuse as both texture colors
    movsd xmm0, [rbx + MAT_DIFFUSE + VEC3_X]
    movsd [rbx + MAT_TEX_COLOR1 + VEC3_X], xmm0
    movsd xmm0, [rbx + MAT_DIFFUSE + VEC3_Y]
    movsd [rbx + MAT_TEX_COLOR1 + VEC3_Y], xmm0
    movsd xmm0, [rbx + MAT_DIFFUSE + VEC3_Z]
    movsd [rbx + MAT_TEX_COLOR1 + VEC3_Z], xmm0

    movsd xmm0, [rbx + MAT_DIFFUSE + VEC3_X]
    movsd [rbx + MAT_TEX_COLOR2 + VEC3_X], xmm0
    movsd xmm0, [rbx + MAT_DIFFUSE + VEC3_Y]
    movsd [rbx + MAT_TEX_COLOR2 + VEC3_Y], xmm0
    movsd xmm0, [rbx + MAT_DIFFUSE + VEC3_Z]
    movsd [rbx + MAT_TEX_COLOR2 + VEC3_Z], xmm0
    jmp .update_count

.check_checker:
    lea rdi, [rel _tex_buf]
    lea rsi, [rel kw_tex_checker]
    call strcmp
    test eax, eax
    jne .check_stripe
    mov dword [rbx + MAT_TEX_TYPE], TEX_CHECKER
    jmp .read_tex_extra

.check_stripe:
    lea rdi, [rel _tex_buf]
    lea rsi, [rel kw_tex_stripe]
    call strcmp
    test eax, eax
    jne .update_count
    mov dword [rbx + MAT_TEX_TYPE], TEX_STRIPE

.read_tex_extra:
    ; scale
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_double]
    lea rdx, [rbx + MAT_TEX_SCALE]
    xor eax, eax
    call fscanf

    ; color1
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rbx + MAT_TEX_COLOR1 + VEC3_X]
    lea rcx, [rbx + MAT_TEX_COLOR1 + VEC3_Y]
    lea r8,  [rbx + MAT_TEX_COLOR1 + VEC3_Z]
    xor eax, eax
    call fscanf

    ; color2
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rbx + MAT_TEX_COLOR2 + VEC3_X]
    lea rcx, [rbx + MAT_TEX_COLOR2 + VEC3_Y]
    lea r8,  [rbx + MAT_TEX_COLOR2 + VEC3_Z]
    xor eax, eax
    call fscanf

.update_count:
    mov eax, dword [material_count]
    mov ecx, dword [rsp + 0]
    inc ecx
    cmp ecx, eax
    jle .done
    mov dword [material_count], ecx

.done:
    leave
    ret

global parse_sphere
parse_sphere:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov eax, dword [object_count]
    cmp eax, MAX_OBJECTS
    jae .done

    mov ecx, eax
    imul ecx, OBJ_SIZE
    lea rbx, [rel objects]
    lea rbx, [rbx + rcx]

    mov dword [rbx + OBJ_TYPE], OBJ_SPHERE

    ; center
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rbx + OBJ_SPH_CENTER + VEC3_X]
    lea rcx, [rbx + OBJ_SPH_CENTER + VEC3_Y]
    lea r8,  [rbx + OBJ_SPH_CENTER + VEC3_Z]
    xor eax, eax
    call fscanf

    ; radius
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_double]
    lea rdx, [rbx + OBJ_SPH_RADIUS]
    xor eax, eax
    call fscanf

    ; material index
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_int]
    lea rdx, [rbx + OBJ_MAT_INDEX]
    xor eax, eax
    call fscanf

    mov eax, dword [object_count]
    inc eax
    mov dword [object_count], eax

.done:
    leave
    ret

global parse_cube
parse_cube:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov eax, dword [object_count]
    cmp eax, MAX_OBJECTS
    jae .done

    mov ecx, eax
    imul ecx, OBJ_SIZE
    lea rbx, [rel objects]
    lea rbx, [rbx + rcx]

    mov dword [rbx + OBJ_TYPE], OBJ_CUBE

    ; min corner
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rbx + OBJ_BOX_MIN + VEC3_X]
    lea rcx, [rbx + OBJ_BOX_MIN + VEC3_Y]
    lea r8,  [rbx + OBJ_BOX_MIN + VEC3_Z]
    xor eax, eax
    call fscanf

    ; max corner
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rbx + OBJ_BOX_MAX + VEC3_X]
    lea rcx, [rbx + OBJ_BOX_MAX + VEC3_Y]
    lea r8,  [rbx + OBJ_BOX_MAX + VEC3_Z]
    xor eax, eax
    call fscanf

    ; material index
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_int]
    lea rdx, [rbx + OBJ_MAT_INDEX]
    xor eax, eax
    call fscanf

    mov eax, dword [object_count]
    inc eax
    mov dword [object_count], eax

.done:
    leave
    ret

global parse_light
parse_light:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov eax, dword [light_count]
    cmp eax, MAX_LIGHTS
    jae .done

    mov ecx, eax
    imul ecx, LIGHT_SIZE
    lea rbx, [rel lights]
    lea rbx, [rbx + rcx]

    ; position
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rbx + LIGHT_POS + VEC3_X]
    lea rcx, [rbx + LIGHT_POS + VEC3_Y]
    lea r8,  [rbx + LIGHT_POS + VEC3_Z]
    xor eax, eax
    call fscanf

    ; color
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_color3]
    lea rdx, [rbx + LIGHT_COLOR + VEC3_X]
    lea rcx, [rbx + LIGHT_COLOR + VEC3_Y]
    lea r8,  [rbx + LIGHT_COLOR + VEC3_Z]
    xor eax, eax
    call fscanf

    ; intensity
    lea rdi, [rel stdin]
    mov rdi, [rdi]
    lea rsi, [rel fmt_double]
    lea rdx, [rbx + LIGHT_INTENSITY]
    xor eax, eax
    call fscanf

    mov eax, dword [light_count]
    inc eax
    mov dword [light_count], eax

.done:
    leave
    ret
