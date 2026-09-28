ENTRY(_start)

MEMORY
{
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 16K
}

SECTIONS
{
  .text :
  {
    KEEP(*(.text._start))
    *(.text .text.*)
  } > RAM

  .rodata :
  {
    *(.rodata .rodata.*)
  } > RAM

  .data :
  {
    . = ALIGN(4);
    *(.data .data.*)
    *(.sdata .sdata.*)
  } > RAM

  .bss (NOLOAD) :
  {
    . = ALIGN(4);
    __bss_start = .;
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end = .;
  } > RAM

  __stack_top = ORIGIN(RAM) + LENGTH(RAM);
  __stack_bottom = __stack_top - 4K;

  ASSERT(__bss_end <= __stack_bottom, "Program sections overlap the stack")
}
