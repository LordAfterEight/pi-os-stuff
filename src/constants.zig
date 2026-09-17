const build_config = @import("build_config");

pub const BASE_PERIPHERAL = build_config.peripheral_base;

// All addresses below are absolute (peripheral_base + block offset + register offset).
pub const GPIO = struct {
    pub const BASE: u32 = BASE_PERIPHERAL + 0x200000;
    pub const GPFSEL1: u32 = BASE + 0x04;
    pub const GPSET0: u32 = BASE + 0x1C;
    pub const GPSEL0: u32 = BASE;
    pub const GPCLR0: u32 = BASE + 0x28;
    pub const GPPUD: u32 = BASE + 0x94;
    pub const GPPUDCLK0: u32 = BASE + 0x98;
    pub const PUP_PDN_CNTRL_REG0: u32 = BASE + 0xE4;

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
    pub const MAX_QUEUE: usize = 16 * 1024;
};

pub const VidCore = struct {
    pub const VIDEOCORE_MBOX: u32 = BASE_PERIPHERAL + 0xB880;
    pub const MBOX_READ: u32 = VIDEOCORE_MBOX;
    pub const MBOX_POLL: u32 = VIDEOCORE_MBOX + 0x10;
    pub const MBOX_SENDER: u32 = VIDEOCORE_MBOX + 0x14;
    pub const MBOX_STATUS: u32 = VIDEOCORE_MBOX + 0x18;
    pub const MBOX_CONFIG: u32 = VIDEOCORE_MBOX + 0x1C;
    pub const MBOX_WRITE: u32 = VIDEOCORE_MBOX + 0x20;

    pub const MBOX_REQUEST: u32 = 0x00000000;
    pub const MBOX_RESPONSE: u32 = 0x80000000;
    pub const MBOX_FULL: u32 = 0x80000000;
    pub const MBOX_EMPTY: u32 = 0x40000000;
    pub const MBOX_CH_PROP: u8 = 8;

    pub const MBOX_TAG_SETPHYWH: u32 = 0x00048003;
    pub const MBOX_TAG_SETVIRTWH: u32 = 0x00048004;
    pub const MBOX_TAG_SETVIRTOFF: u32 = 0x00048009;
    pub const MBOX_TAG_SETDEPTH: u32 = 0x00048005;
    pub const MBOX_TAG_SETPXLORDR: u32 = 0x00048006;
    pub const MBOX_TAG_GETFB: u32 = 0x00040001;
    pub const MBOX_TAG_GETPITCH: u32 = 0x00040008;
    pub const MBOX_TAG_LAST: u32 = 0x00000000;
};
