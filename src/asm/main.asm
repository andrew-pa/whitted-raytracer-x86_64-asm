%include "src/asm/defines.inc"

default rel

extern parse_scene
extern compute_camera_basis
extern render_rows
extern render_worker
extern write_png_stdout
extern malloc
extern free
extern exit
extern sysconf
extern pthread_create
extern pthread_join

extern image_width
extern image_height

section .text

global main
main:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40

    call parse_scene
    call compute_camera_basis

    mov r13d, dword [image_width]
    mov r14d, dword [image_height]

    ; size = width * height * 3
    mov ecx, r13d
    imul ecx, r14d
    imul ecx, 3

    mov edi, ecx
    call malloc
    test rax, rax
    jz .oom

    mov rbx, rax

    ; thread_count = min(sysconf(_SC_NPROCESSORS_ONLN), height)
    mov edi, SC_NPROCESSORS_ONLN
    call sysconf
    cmp rax, 1
    jge .threads_ok
    mov rax, 1
.threads_ok:
    mov r15d, eax
    cmp r15d, r14d
    jle .threads_cap
    mov r15d, r14d
.threads_cap:

    cmp r15d, 1
    jg .multithread

    ; render_rows(buffer, width, height, 0, height)
    mov rdi, rbx
    mov esi, r13d
    mov edx, r14d
    xor ecx, ecx
    mov r8d, r14d
    call render_rows
    jmp .after_render

.multithread:
    ; rows_per = height / threads, rem = height % threads
    mov eax, r14d
    xor edx, edx
    div r15d
    mov dword [rsp + 16], eax  ; rows_per
    mov dword [rsp + 20], edx  ; remainder
    mov dword [rsp + 32], r15d ; save thread_count

    ; threads_bytes = threads * 8
    mov eax, r15d
    imul eax, 8
    mov dword [rsp + 24], eax

    ; total_bytes = threads_bytes + threads * TASK_SIZE
    mov ecx, r15d
    imul ecx, TASK_SIZE
    add eax, ecx
    mov edi, eax
    call malloc
    test rax, rax
    jz .oom

    mov r12, rax
    mov [rsp + 0], r12         ; threads_ptr
    mov eax, dword [rsp + 24]
    lea rdx, [r12 + rax]
    mov [rsp + 8], rdx         ; tasks_ptr

    xor r11d, r11d             ; i = 0
    xor r8d, r8d               ; start_y = 0
.spawn_loop:
    cmp r11d, dword [rsp + 32]
    jge .join_loop

    mov eax, dword [rsp + 16]  ; rows_per
    mov ecx, eax
    cmp r11d, dword [rsp + 20]
    jge .no_extra
    inc ecx
.no_extra:
    mov edx, r8d               ; start
    add ecx, r8d               ; end
    mov dword [rsp + 28], ecx  ; save end

    ; task_ptr = tasks_ptr + i * TASK_SIZE
    mov rax, r11
    imul rax, TASK_SIZE
    mov rdi, [rsp + 8]
    add rdi, rax
    mov r9, rdi               ; save task_ptr

    mov [rdi + TASK_BUF], rbx
    mov eax, r13d
    mov [rdi + TASK_WIDTH], rax
    mov eax, r14d
    mov [rdi + TASK_HEIGHT], rax
    mov eax, edx
    mov [rdi + TASK_START], rax
    mov eax, ecx
    mov [rdi + TASK_END], rax

    ; pthread_create(&threads[i], NULL, render_worker, task_ptr)
    mov dword [rsp + 36], r11d
    mov rax, r11
    imul rax, 8
    mov rdi, [rsp + 0]
    add rdi, rax              ; &threads[i]
    xor esi, esi
    lea rdx, [rel render_worker]
    mov rcx, r9               ; task_ptr
    call pthread_create
    mov r11d, dword [rsp + 36]

    mov r8d, dword [rsp + 28]  ; start_y = end
    inc r11d
    jmp .spawn_loop

.join_loop:
    xor r11d, r11d
.join_loop_iter:
    cmp r11d, dword [rsp + 32]
    jge .free_threads
    mov rax, r11
    imul rax, 8
    mov rdi, [rsp + 0]
    add rdi, rax
    mov rdi, [rdi]            ; pthread_t value
    xor esi, esi
    call pthread_join
    inc r11d
    jmp .join_loop_iter

.free_threads:
    mov rdi, r12
    call free

.after_render:

    ; write_png_stdout(buffer, width, height)
    mov rdi, rbx
    mov esi, r13d
    mov edx, r14d
    call write_png_stdout

    mov rdi, rbx
    call free

    xor eax, eax
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

.oom:
    mov edi, 1
    call exit
