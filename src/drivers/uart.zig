const os = @import("../root.zig");

pub fn init() void {
    var gpioptr: *volatile u32 = undefined;
    var mask: u32 = undefined;

    gpioptr = @ptrFromInt(os.constants.gpio.GPFSEL1);
    mask = (0b111 << 12) | (0b111 << 15);
    gpioptr.* = (gpioptr.* & ~mask) |
        ((os.constants.gpio.FUNCTION_ALT5 << 12) |
            (os.constants.gpio.FUNCTION_ALT5 << 15));

    gpioptr = @ptrFromInt(os.constants.gpio.PUP_PDN_CNTRL_REG0);
    mask = (0b11 << 28) | (0b11 << 30);
    gpioptr.* = gpioptr.* & ~mask;

    gpioptr = @ptrFromInt(os.constants.uart1.AUX_ENABLES);
    gpioptr.* |= 0x1;

    gpioptr = @ptrFromInt(os.constants.uart1.MU_CNTL);
    gpioptr.* = 0;

    gpioptr = @ptrFromInt(os.constants.uart1.MU_IER);
    gpioptr.* = 0;

    gpioptr = @ptrFromInt(os.constants.uart1.MU_LCR);
    gpioptr.* = 0b11;

    gpioptr = @ptrFromInt(os.constants.uart1.MU_MCR);
    gpioptr.* = 0;

    gpioptr = @ptrFromInt(os.constants.uart1.MU_IIR);
    gpioptr.* = 0xC6;

    gpioptr = @ptrFromInt(os.constants.uart1.MU_BAUD);
    gpioptr.* = baud(115200);

    gpioptr = @ptrFromInt(os.constants.uart1.MU_CNTL);
    gpioptr.* = 0b11;
}

const queue_len = os.constants.uart1.MAX_QUEUE;

var output_queue: [queue_len]u8 = undefined;
var output_queue_read: u32 = 0;
var output_queue_write: u32 = 0;

fn is_output_queue_empty() bool {
    return output_queue_read == output_queue_write;
}

fn is_read_byte_ready() bool {
    const lsrptr: *volatile u32 = @ptrFromInt(os.constants.uart1.MU_LSR);
    return (lsrptr.* & 0x01) != 0;
}

fn is_write_byte_ready() bool {
    const lsrptr: *volatile u32 = @ptrFromInt(os.constants.uart1.MU_LSR);
    return (lsrptr.* & 0x20) != 0;
}

fn read_byte() u8 {
    while (!is_read_byte_ready()) {}

    const ioptr: *volatile u32 = @ptrFromInt(os.constants.uart1.MU_IO);
    return @truncate(ioptr.*);
}

fn write_byte_blocking_actual(ch: u8) void {
    while (!is_write_byte_ready()) {}

    const ioptr: *volatile u32 = @ptrFromInt(os.constants.uart1.MU_IO);
    ioptr.* = ch;
}

fn load_output_fifo() void {
    while (!is_output_queue_empty() and is_write_byte_ready()) {
        write_byte_blocking_actual(output_queue[output_queue_read]);
        output_queue_read = (output_queue_read + 1) & (queue_len - 1);
    }
}

fn write_byte_blocking(ch: u8) void {
    const next = (output_queue_write + 1) & (queue_len - 1);

    while (next == output_queue_read) {
        load_output_fifo();
    }

    output_queue[output_queue_write] = ch;
    output_queue_write = next;
}

pub fn write_text(buffer: []const u8) void {
    for (buffer) |ch| {
        if (ch == '\n') {
            write_byte_blocking('\r');
        }

        write_byte_blocking(ch);
    }
}

pub fn drain_output_queue() void {
    while (!is_output_queue_empty()) {
        load_output_fifo();
    }
}

pub fn update() void {
    load_output_fifo();

    if (is_read_byte_ready()) {
        const ch = read_byte();
        write_byte_blocking(ch);
    }
}

pub fn baud(rate: u32) u32 {
    return (os.constants.uart1.CLOCK / (rate * 8)) - 1;
}
