const constants = @import("../constants.zig");

pub fn write(reg: u32, val: u32) void {
    const ptr: *volatile u32 = @ptrFromInt(@as(usize, reg));
    ptr.* = val;
}

pub fn read(reg: u32) u32 {
    const ptr: *volatile u32 = @ptrFromInt(@as(usize, reg));
    return ptr.*;
}

pub fn call(
    pin_number: u32,
    value: u32,
    base: u32,
    field_size: u32,
    field_max: u32,
) !void {
    if (pin_number > field_max) return error.PinNumberTooBig;

    const field_mask: u32 = (@as(u32, 1) << @intCast(field_size)) - 1;

    if (value > field_mask) return error.ValueTooBig;

    const num_fields: u32 = 32 / field_size;
    const reg = base + ((pin_number / num_fields) * 4);
    const shift: u32 = (pin_number % num_fields) * field_size;

    var curval = read(reg);
    curval &= ~(field_mask << shift);
    curval |= value << shift;
    write(reg, curval);
}

pub fn set(pin_number: u32, val: u32) !void {
    return call(pin_number, val, constants.GPIO.GPSET0, 1, constants.GPIO.MAX_PIN);
}

pub fn clear(pin_number: u32, val: u32) !void {
    return call(pin_number, val, constants.GPIO.GPCLR0, 1, constants.GPIO.MAX_PIN);
}

pub fn pull(pin_number: u32, val: u32) !void {
    return call(pin_number, val, constants.GPIO.PUP_PDN_CNTRL_REG0, 2, constants.GPIO.MAX_PIN);
}

pub fn function(pin_number: u32, val: u32) !void {
    return call(pin_number, val, constants.GPIO.GPSEL0, 3, constants.GPIO.MAX_PIN);
}

pub fn use_as_alt3(pin_number: u32) void {
    pull(pin_number, constants.GPIOMode.PullNone) catch unreachable;
    function(pin_number, constants.GPIO.FUNCTION_ALT3) catch unreachable;
}

pub fn use_as_alt5(pin_number: u32) void {
    pull(pin_number, constants.GPIOMode.PullNone) catch unreachable;
    function(pin_number, constants.GPIO.FUNCTION_ALT5) catch unreachable;
}

pub fn init_output_pin_with_pull_none(pin_number: u32) void {
    pull(pin_number, constants.GPIOMode.PullNone) catch unreachable;
    function(pin_number, constants.GPIO.FUNCTION_OUT) catch unreachable;
}

pub fn set_pin_output_bool(pin_number: u32, on_or_off: u32) void {
    if (on_or_off != 0) {
        set(pin_number, 1) catch unreachable;
    } else {
        clear(pin_number, 1) catch unreachable;
    }
}
