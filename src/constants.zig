const build_config = @import("build_config");

pub const BASE_PERIPHERAL = build_config.peripheral_base;

// NOTE: This file was rewritten by GPT-5.6 Luna, on 17.09.2026

// All addresses below are absolute (peripheral_base + block offset + register offset),
// so each one can be used directly as a u32 — no separate base-add step at the call site.
//
// --- GPIO block: peripheral_base + 0x200000 ---
pub const GPIO = struct {
    pub const BASE: u32 = BASE_PERIPHERAL + 0x200000;
    pub const GPFSEL1: u32 = BASE + 0x04; // function select for pins 10-19, 3 bits/pin — controls 14 & 15
    pub const GPSET0: u32 = BASE + 0x1C;
    pub const GPSEL0: u32 = BASE;
    pub const GPCLR0: u32 = BASE + 0x28;
    pub const GPPUD: u32 = BASE + 0x94; // pi3-only
    pub const GPPUDCLK0: u32 = BASE + 0x98; // pi3-only
    pub const PUP_PDN_CNTRL_REG0: u32 = BASE + 0xE4; // pi4-only

    pub const MAX_PIN: u32 = 58;
    pub const FUNCTION_OUT: u32 = 1;
    pub const FUNCTION_ALT5: u32 = 2;
    pub const FUNCTION_ALT3: u32 = 7;
};

pub const GPIOMode = enum {
    pub const PullNone: u32 = 0;
    pub const PullDown: u32 = 2;
    pub const PullUp: u32 = 1;
};

pub const UART0 = struct {
    pub const BASE: u32 = BASE_PERIPHERAL + 0x201000;
    pub const DR: u32 = BASE + 0x00;
    pub const FR: u32 = BASE + 0x18;
    pub const IBRD: u32 = BASE + 0x24;
    pub const FBRD: u32 = BASE + 0x28;
    pub const LCRH: u32 = BASE + 0x2C;
    pub const CR: u32 = BASE + 0x30;
    pub const IMSC: u32 = BASE + 0x38;
    pub const ICR: u32 = BASE + 0x44;
};

pub const UART1 = struct {
    pub const BASE: u32 = BASE_PERIPHERAL + 0x215000;
    pub const AUX_IRQ: u32 = BASE;
    pub const AUX_ENABLES: u32 = BASE + 4;
    pub const MU_IO: u32 = BASE + 64;
    pub const MU_IER: u32 = BASE + 68;
    pub const MU_IIR: u32 = BASE + 72;
    pub const MU_LCR: u32 = BASE + 76;
    pub const MU_MCR: u32 = BASE + 80;
    pub const MU_LSR: u32 = BASE + 84;
    pub const MU_MSR: u32 = BASE + 88;
    pub const MU_SCRATCH: u32 = BASE + 92;
    pub const MU_CNTL: u32 = BASE + 96;
    pub const MU_STAT: u32 = BASE + 100;
    pub const MU_BAUD: u32 = BASE + 104;
    pub const CLOCK: u32 = 500000000;
    pub const MAX_QUEUE: u32 = 16 * 1024;
};
