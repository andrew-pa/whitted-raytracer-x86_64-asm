%include "src/asm/defines.inc"

default rel

extern parse_scene
extern render_image
extern write_png_stdout
extern malloc
extern free
extern exit

extern image_width
extern image_height

section .text

global main
main:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 24

    call parse_scene

    mov eax, dword [image_width]
    mov ebx, dword [image_height]

    ; size = width * height * 3
    mov ecx, eax
    imul ecx, ebx
    imul ecx, 3

    mov edi, ecx
    call malloc
    test rax, rax
    jz .oom

    mov rbx, rax

    ; render_image(buffer, width, height)
    mov rdi, rbx
    mov esi, dword [image_width]
    mov edx, dword [image_height]
    call render_image

    ; write_png_stdout(buffer, width, height)
    mov rdi, rbx
    mov esi, dword [image_width]
    mov edx, dword [image_height]
    call write_png_stdout

    mov rdi, rbx
    call free

    xor eax, eax
    add rsp, 24
    pop rbx
    leave
    ret

.oom:
    mov edi, 1
    call exit
