# Memory

Yeti-16 has a 24-bit address bus, so it has 16 MiB of RAM

## Memory layout
```
0x000000 - 0x000004        : Unused
0x000004 - 0x000404        : Interrupt table
0x000404                   : Current video mode
0x000405 - (variable size) : Video memory
0x0F0000                   : Start of stack and usable memory
```
