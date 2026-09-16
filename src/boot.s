// NOTE: This file was written by Claude Sonnet 5 High on 16.09.2026

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
    ldr x0, =__stack_top
    mov sp, x0

    ldr x0, =__bss_start
    ldr x1, =__bss_end
zero_bss:
    cmp x0, x1
    b.ge call_kernel
    str xzr, [x0], #8
    b zero_bss

.section ".bss"
.align 12                  // table base must be 4KB-aligned — this is
l1_table:                  // what TTBR0_EL2 requires for a single-level
    .skip 4096              // (512-entry, 8-byte-descriptor) table

.section ".text.boot"
// ... _start, park, primary_core, zero_bss stay as they are ...

setup_mmu:
    // MAIR_EL2: two attribute slots.
    //   index 0 = Device-nGnRnE (0x00) -> peripherals
    //   index 1 = Normal, Write-Back RW-Allocate (0xFF) -> RAM
    mov  x0, #0xFF00
    msr  mair_el2, x0

    // TCR_EL2 (this is the HCR_EL2.E2H==0 "short" layout, since we're
    // not using VHE):
    //   T0SZ=25    -> 39-bit input address space. For a 4KB granule
    //                 that means the walk starts at level 1, so each
    //                 of our table's 512 entries is a 1 GiB block —
    //                 no intermediate tables needed at all.
    //   IRGN0/ORGN0=01, SH0=11 -> cacheable, inner-shareable table walks
    //   TG0=00     -> 4KB granule
    //   PS left at 0 (32-bit / 4GB physical space) — our map tops out
    //   at 0xFFFFFFFF anyway, so the default covers it.
    //   Bits 23 and 31 are RES1 in this register layout — not a design
    //   choice, the architecture requires them set.
    mov  x0, #25
    orr  x0, x0, #(0b01 << 8)
    orr  x0, x0, #(0b01 << 10)
    orr  x0, x0, #(0b11 << 12)
    orr  x0, x0, #(1 << 23)
    orr  x0, x0, #(1 << 31)
    msr  tcr_el2, x0

    // Populate the L1 table. Only entries 0, 1, 3 are written — every
    // other entry stays zero (= invalid descriptor), so touching
    // unmapped space faults cleanly instead of succeeding silently.
    ldr  x1, =l1_table

    // Entry 0: 0x00000000-0x3FFFFFFF — RAM, Normal memory
    mov  x0, xzr
    orr  x0, x0, #1              // valid=1, block (bit1=0, not table)
    orr  x0, x0, #(1 << 2)       // AttrIndx=1 (Normal)
    orr  x0, x0, #(0b11 << 8)    // SH=Inner Shareable
    orr  x0, x0, #(1 << 10)      // AF — must be set; we haven't wired
                                  //  up access-flag fault handling
    str  x0, [x1, #(0 * 8)]

    // Entry 1: 0x40000000-0x7FFFFFFF — RAM, Normal memory
    mov  x0, #0x40000000
    orr  x0, x0, #1
    orr  x0, x0, #(1 << 2)
    orr  x0, x0, #(0b11 << 8)
    orr  x0, x0, #(1 << 10)
    str  x0, [x1, #(1 * 8)]

    // Entry 2 (0x80000000-0xBFFFFFFF): deliberately left zero.
    // Nothing lives there on this board.

    // Entry 3: 0xC0000000-0xFFFFFFFF — peripherals (incl. UART at
    // 0xFE000000), Device-nGnRnE. AttrIndx stays 0, so no bits to OR.
    mov  x0, #0xC0000000
    orr  x0, x0, #1
    orr  x0, x0, #(1 << 10)       // AF
    orr  x0, x0, #(1 << 54)       // XN — never execute peripheral space
                                    // (EL2 regime: single combined XN
                                    //  bit, not split UXN/PXN like EL1&0)
    str  x0, [x1, #(3 * 8)]

    msr  ttbr0_el2, x1

    // TLB contents after reset are architecturally UNKNOWN, not
    // guaranteed empty — invalidate before trusting them.
    tlbi alle2
    dsb  sy
    isb

    mrs  x0, sctlr_el2
    orr  x0, x0, #(1 << 0)    // M — enable the MMU
    orr  x0, x0, #(1 << 2)    // C — enable data cache
    orr  x0, x0, #(1 << 12)   // I — enable instruction cache
    msr  sctlr_el2, x0
    isb

    ret

call_kernel:
    bl setup_mmu
    bl kernel_main
hang:
    wfe
    b hang
