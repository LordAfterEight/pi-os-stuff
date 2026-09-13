.section ".text.boot"
.global _start

_start:
    // Park every core except core 0 — we bring the others up later once
    // there's a scheduler; for now a spinning WFE loop is the whole SMP
    // story.
    mrs x0, mpidr_el1
    and x0, x0, #0xFF
    cbz x0, primary_core
park:
    wfe
    b park

primary_core:
    // Stack grows down from our own load address; nothing above us is ours.
    ldr x0, =_start
    mov sp, x0

    // Zero .bss — Zig assumes it starts zeroed; nothing does that for us.
    ldr x0, =__bss_start
    ldr x1, =__bss_end
zero_bss:
    cmp x0, x1
    b.ge call_kernel
    str xzr, [x0], #8
    b zero_bss

call_kernel:
    bl kernel_main
hang:
    wfe
    b hang
