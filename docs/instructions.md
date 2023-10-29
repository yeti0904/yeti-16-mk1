# Instructions

## Instruction format
Opcode is a byte (8-bit), and then parameters after are either bytes for data or
registers, words (16-bit) for data, and 24-bit values for addresses

### Instructions
- `NOP` (0x00) - does nothing
- `SET (reg) (word)` (0x01) - sets the given register to the given word
- `XCHG (reg) (reg)` (0x02) - swaps the values of the given registers
- `WRB (reg pair) (reg)` (0x03) - writes the low byte of the given register to the
                                  given memory address (reg pair)
- `RDB (reg pair)` (0x04) - reads a byte from the given address (reg pair) into the
                            accumulator
- `WRW (reg pair) (reg)` (0x05) - writes the given register to the given address (reg pair)
- `RDW (reg pair)` (0x06) - reads a word from the given address (reg pair) into the
                            accumulator
- `ADD (reg) (reg)` (0x07) - Adds the given registers to each other and stores the
                             result in the accumulator
- `SUB (reg) (reg)` (0x08) - Same as the last instruction, but with subtraction
- `MUL (reg) (reg)` (0x09) - Same as the last instruction, but with multiplication
- `DIV (reg) (reg)` (0x0A) - Same as the last instruction, but with division
- `MOD (reg) (reg)` (0x0B) - Same as the last instruction, but with modulo
- `INC (reg)` (0x0C) - Increments the given register's value
- `DEC (reg)` (0x0D) - Decrements the given register's value
- `CMP (reg) (reg)` (0x0E) - Sets the accumulator to 0xFFFF if the 2 registers are equal,
                             and 0 if they are not equal
- `NOT (reg)` (0x0F) - Performs a bitwise NOT operation on the given register
- `AND (reg) (reg)` (0x10) - Performs a bitwise AND operation on the given registers and
                             stores the result in the accumulator
- `OR (reg) (reg)` (0x11) - Same as the last instruction, but with bitwise OR
- `XOR (reg) (reg)` (0x11) - Same as the last instruction, but with bitwise XOR
- `JNZ (addr)` (0x12) - Jumps to the given address if the accumulator is not 0
- `JMP (addr)` (0x13) - Jumps to the given address
- `OUT (byte) (reg)` (0x14) - Writes the given register to the given device (byte)
- `IN (byte)` (0x13) - Reads from the given register and stores the result in the
                       accumulator
- `HLT` (0xFF) - Stops execution
