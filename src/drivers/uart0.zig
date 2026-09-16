const build_config = @import("build_config");
const std = @import("std");

const BASE_PERIPHERAL = build_config.peripheral_base;
const GPIO = BASE_PERIPHERAL + 0x200000;
const UART0 = BASE_PERIPHERAL + 0x201000;

// NOTE: The following was written by Claude Sonnet 5 High, on 14.09.2026
// All offsets are from peripheral_base (0xFE000000 on your pi4, 0x3F000000 on pi3).
//
// --- GPIO block: peripheral_base + 0x200000 ---
const GPFSEL1 = 0x04; // function select for pins 10-19, 3 bits/pin — controls 14 & 15
const GPPUD = 0x94; // pi3-only (BCM2835/36/37). Stages a pull value: 00=off,01=down,10=up
const GPPUDCLK0 = 0x98; // pi3-only. Write pin bitmask here to *latch* the staged GPPUD value
const GPIO_PUP_PDN_CNTRL_REG0 = 0xE4; // pi4-only (BCM2711). Direct write, no latch step, covers pins 0-15
// --- PL011 UART0 block: peripheral_base + 0x201000 ---
const UART_DR = 0x00; // data register — write = TX byte, read = RX byte
const UART_FR = 0x18; // flag register — bit 5 = TXFF (TX FIFO full), bit 3 = BUSY, bit 4 = RXFE
const UART_IBRD = 0x24; // integer part of baud divisor
const UART_FBRD = 0x28; // fractional part of baud divisor (6-bit field)
const UART_LCRH = 0x2C; // line control — bit 4 = FIFO enable, bits [6:5] = word length (11 = 8-bit)
const UART_CR = 0x30; // control — bit 0 = UART enable, bit 8 = TX enable, bit 9 = RX enable
const UART_IMSC = 0x38; // interrupt mask — write 0 to mask everything for now
const UART_ICR = 0x44; // interrupt clear — write 0x7FF to clear any pending
//---------------------------------------------------------------------------------------------------------------------------

pub fn init() void {
    var gpioptr: *volatile u32 = undefined;
    var mask: u32 = undefined;

    gpioptr = @ptrFromInt(GPIO + GPIO_PUP_PDN_CNTRL_REG0);
    mask = (0b11 << 28) | (0b11 << 30);
    gpioptr.* = gpioptr.* & ~mask;

    gpioptr = @ptrFromInt(GPIO + GPFSEL1);
    mask = (0b111 << 12) | (0b111 << 15);
    gpioptr.* = (gpioptr.* & ~mask) | ((0b100 << 12) | (0b100 << 15));

    gpioptr = @ptrFromInt(UART0 + UART_CR);
    gpioptr.* = 0;

    gpioptr = @ptrFromInt(UART0 + UART_ICR);
    gpioptr.* = 0x7FF;

    gpioptr = @ptrFromInt(UART0 + UART_IMSC);
    gpioptr.* = 0x0;

    gpioptr = @ptrFromInt(UART0 + UART_IBRD);
    gpioptr.* = 0x1A;
    //
    gpioptr = @ptrFromInt(UART0 + UART_FBRD);
    gpioptr.* = 0x3;

    gpioptr = @ptrFromInt(UART0 + UART_LCRH);
    mask = 0b111 << 4;
    gpioptr.* = (gpioptr.* & ~mask) | (0b111 << 4);

    gpioptr = @ptrFromInt(UART0 + UART_CR);
    mask = (0b1 << 0) | (0b11 << 8);
    gpioptr.* = (gpioptr.* & ~mask) | ((0b1) | (0b11 << 8));
}

/// Writes ASCII bytes to UART0. Invalid characters are replaced by '�'
pub fn write(msg: []const u8) void {
    const frptr: *volatile u32 = @ptrFromInt(UART0 + UART_FR);
    const drptr: *volatile u32 = @ptrFromInt(UART0 + UART_DR);
    for (msg) |c| {
        while (((frptr.* >> 5) & 1) != 0) {}
        if (std.ascii.isAscii(c)) {
            drptr.* = c;
        } else {
            drptr.* = '�';
        }
    }
}
