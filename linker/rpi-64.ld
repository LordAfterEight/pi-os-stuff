ENTRY(_start)

SECTIONS
{
    /* Firmware hands off to us here on all current 64-bit Pi boards. */
    . = 0x80000;

    .text : {
        KEEP(*(.text.boot))
        *(.text*)
    }

    .rodata : { *(.rodata*) }
    .data   : { *(.data*) }

    .bss : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    }

    . = ALIGN(16);
    __stack_bottom = .;
    . += 0x100000;
    __stack_top = .;

    /DISCARD/ : { *(.comment) *(.note*) }
}
