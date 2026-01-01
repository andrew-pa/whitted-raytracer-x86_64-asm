%include "src/asm/defines.inc"

default rel

extern memset
extern png_image_write_to_stdio
extern png_image_free
extern stdout

%define PNG_IMAGE_SIZE 104
%define PNG_IMAGE_OPAQUE 0
%define PNG_IMAGE_VERSION_OFF 8
%define PNG_IMAGE_WIDTH_OFF 12
%define PNG_IMAGE_HEIGHT_OFF 16
%define PNG_IMAGE_FORMAT_OFF 20

section .text

global write_png_stdout
write_png_stdout:
    ; rdi = buffer, rsi = width, rdx = height
    push rbp
    mov rbp, rsp
    sub rsp, 128

    mov r8, rdi
    mov r9d, esi
    mov r10d, edx

    ; zero png_image struct
    lea rdi, [rsp]
    xor esi, esi
    mov edx, PNG_IMAGE_SIZE
    call memset

    ; fill header
    mov dword [rsp + PNG_IMAGE_VERSION_OFF], PNG_IMAGE_VERSION
    mov dword [rsp + PNG_IMAGE_WIDTH_OFF], r9d
    mov dword [rsp + PNG_IMAGE_HEIGHT_OFF], r10d
    mov dword [rsp + PNG_IMAGE_FORMAT_OFF], PNG_FORMAT_RGB

    ; row_stride = width * 3
    mov eax, r9d
    imul eax, 3

    ; png_image_write_to_stdio(&image, stdout, 0, buffer, row_stride, NULL)
    lea rdi, [rsp]
    mov rsi, [rel stdout]
    xor edx, edx
    mov rcx, r8
    mov r8d, eax
    xor r9d, r9d
    call png_image_write_to_stdio

    ; free any internal png_image state
    lea rdi, [rsp]
    call png_image_free

    leave
    ret
