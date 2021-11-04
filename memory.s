struc Allocation, -(8*3)
    .size: resq 1
    .next: resq 1
    .previous: resq 1
endstruc

extern printf
extern exit

global memory_initialize
global memory_allocate
global memory_reallocate
global memory_copy
global memory_free

%define MEMORY_GUARD 1
%define MEMORY_DEBUG 0

; linux syscall constants
%define PROT_READ   0x1
%define PROT_WRITE  0x2

%define MAP_ANONYMOUS   0x0020
%define MAP_SHARED      0x01

%define MEMORY_SIZE (4096 * 1024) * 24 ;; 4 MB

section .text

out_of_bounds_error:
    ; inline rdi, String.static "Memory Operation Out of Bounds!"
    mov rdi, out_of_bounds_msg
    xor rax, rax

    call printf

    mov rdi, 1
    call exit

; void memory_initialize()
memory_initialize:
    ; Create 4MB of memory
    mov rdi, 0
    mov rsi, MEMORY_SIZE
    mov rdx, PROT_WRITE | PROT_READ
    mov r10, MAP_ANONYMOUS | MAP_SHARED
    mov r8, 0
    mov r9, 0
    mov rax, 9
    syscall

    add rax, Allocation_size
    mov [memory.location], rax

    mov qword [rax+Allocation.size], 0

    mov rsi, MEMORY_SIZE
    add rsi, rax
    mov [rax+Allocation.next], rsi

    mov [memory.end], rsi

    %if MEMORY_DEBUG
        saveall
        inline rdi, db "memory ends at ", 0x1b, "[0;32m%lx", 0x1b, "[0;37m", 10, 0
        xor rax, rax
        call printf
        restoreall
    %endif

    mov qword [rax+Allocation.previous], 0

    ret

; void* memory.allocate(size_t size)
memory_allocate:
    mov rcx, [memory.location]

    .find_available:
        mov rsi, [rcx+Allocation.next]
        sub rsi, rcx
        sub rsi, [rcx+Allocation.size]
        sub rsi, Allocation_size
        sub rsi, 8*3 ; Might be a magic number IDK

        cmp rsi, rdi
        jg .create_block

        mov rcx, [rcx+Allocation.next]
        jmp .find_available

    .create_block:
        mov rax, rcx
        add rax, [rcx+Allocation.size]
        add rax, Allocation_size

        mov [rax+Allocation.size], rdi
        mov rdx, [rcx+Allocation.next]
        mov [rax+Allocation.next], rdx
        mov [rax+Allocation.previous], rcx

        mov [rcx+Allocation.next], rax
        mov [rdx+Allocation.previous], rax

    ret

; void memory.free(void*)
memory_free:
    %if MEMORY_GUARD
        cmp rdi, [memory.location]
        jl out_of_bounds_error
    %endif

    mov rsi, [rdi+Allocation.previous]
    mov rdx, [rdi+Allocation.next]

    mov [rsi+Allocation.next], rdx ; set previous' next pointer to next pointer of freed block
    mov [rdx+Allocation.previous], rsi

    ret

; void* memory.copy(void* dest, void* src, size_t size)
; Copy's memory from dest to src for size bytes
memory_copy:
    push rdi
    test rdx, rdx
    jz .end ; bypass copying if copying zero bytes
    mov rcx, rdx

    .loop:
        mov al, [rsi]
        stosb
        inc rsi
        loop .loop

    .end:
        pop rax
        ret

; void* memory.reallocate(void* src, size_t size)
memory_reallocate:
    push rbp
    mov rbp, rsp
    sub rsp, 8*2

    mov [rbp-8], rdi
    mov [rbp-8*2], rsi

    cmp rdi, [memory.location]
    jl .skip_free

    mov rdi, [rbp-8]
    call memory_free

    .skip_free:

    mov rdi, [rbp-8*2]
    call memory_allocate
    push rax

    ; if the region is the same don't copy
    mov rdi, [rbp-8]
    cmp rdi, [memory.location]
    jl .skip_check

    cmp rdi, rax
    je .end

    .skip_check:

    mov rdi, rax
    mov rsi, [rbp-8]
    mov rdx, [rbp-8*2]
    call memory_copy

    .end:
        pop rax

        mov rsp, rbp
        pop rbp
        ret

section .data
    memory.action: dq 0
    out_of_bounds_msg: db "Memory Operation Out of Bounds!", 10, 0

section .bss
    memory.location: resq 1
    memory.end: resq 1
