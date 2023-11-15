# Architecture

## Registers
- (0) A  (16-bit) accumulator, general purpose
- (1) B  (16-bit) accumulator, general purpose
- (2) C  (16-bit) general purpose
- (3) D  (16-bit) general purpose
- (4) E  (16-bit) general purpose
- (5) F  (16-bit) general purpose 

## Register pairs
- (0) AB (24-bit) accumulator, general purpose
- (1) CD (24-bit) general purpose
- (2) EF (24-bit) general purpose
- (3) DS (24-bit) destination pointer, general purpose
- (4) SR (24-bit) source pointer, general purpose
- (5) IP (24-bit) instruction pointer
- (6) SP (24-bit) stack pointer (grows upwards)
- (7) BS (24-bit) base pointer (points to start of program)

Note: AB, CD, EF are made out of (A, B), (C, D), (E, F) 16-bit registers

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
                             result in the first given register
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
                             stores the result in the first given register
- `OR (reg) (reg)` (0x11) - Same as the last instruction, but with bitwise OR
- `XOR (reg) (reg)` (0x12) - Same as the last instruction, but with bitwise XOR
- `JNZ (addr)` (0x13) - Jumps to the given address if the accumulator is not 0
- `JMP (addr)` (0x14) - Jumps to the given address
- `OUT (reg) (reg)` (0x15) - Writes the given register (second) to the given device (first)
- `IN (reg)` (0x16) - Reads from the given device (reg) and stores the result in the
                       accumulator
- `LDA (reg pair) (addr)` (0x17) - Loads address into the given register pair
- `INCP (reg pair)` (0x18) - Increments the given register pair
- `DECP (reg pair)` (0x19) - Decrements the given register pair
- `SETL (reg)` (0x1A) - Copies the lowest byte of the given register `C` times starting
                        from the address in `DS`
- `CPL` (0x1B) - Copies the bytes from memory at address `SR` to memory at address `DR`
                 `C` times
- `CALL (addr)` (0x1C) - Pushes IP to the stack and jumps to the given address
- `RET` (0x1D) - Pops from the stack into IP
- `INT (byte)` (0x1E) - Calls the given interrupt from the interrupt table
- `WRA (reg pair) (reg pair)` (0x1F) - Writes the given register pair (second) to the
                                       given address (first)
- `RDA (reg pair)` (0x20) - Reads a 24-bit address from the given register pair in memory
                            and stores the value in AB
- `CPR (reg) (reg)` (0x21) - Copies the value of the second register to the first register
- `CPP (reg pair) (reg pair)` (0x22) - Same as CPR but for register pairs
- `JMPB (addr)` (0x23) - Jumps to the given address added to the value of `BS`
- `JNZB (addr)` (0x24) - Jumps to the given address added to the value of `BS` if
                         the value of `A` isn't 0
- `CHK (reg)` (0x25) - Checks the given device for any incoming data (0xFFFF if any, 0 if not)
- `ACTV (reg)` (0x26) - Checks to see if the given device is active (0xFFFF if active, 0 if not)
- `ADDP (reg pair) (reg)` (0x27) - Adds the contents of reg to the reg pair
- `SUBP (reg pair) (reg)` (0x28) - Subtracts the contents of the reg from the reg pair
- `DIFF (reg pair) (reg pair)` (0x29) - Subtracts the contents of the first reg pair from
                                        the second reg pair and stores the result in
                                        register pair AB
- `PUSH (reg)` (0x2A) - Pushes the given register to the stack
- `POP (reg)` (0x2B) - Pops a value from the stack and stores it in the given register
- `JZ (addr)` (0x2C) - Jumps to the given address if A is 0
- `JZB (addr)` (0x2D)- Jumps to the given address + `BC` if A is 0
- `RDBB (reg pair)` (0x2E) - Reads a byte from `BS` + reg pair and stores it in `A`
- `RDWB (reg pair)` (0x2F) - Reads a 16-bit value from `BS` + reg pair and stores it in `A`
- `RDAB (reg pair)` (0x30) - Reads a 24-bit value from `BS` + reg pair and stores it in `A`
- `WRBB (reg pair) (reg)` (0x31) - Writes the low 8-bits of `reg` to `BS` + reg pair
- `WRWB (reg pair) (reg)` (0x32) - Writes `reg` to `BS` + reg pair
- `WRAB (reg pair) (reg pair)` (0x33) - Writes the second reg pair to `BS` + second reg pair
- `LT (reg) (reg)` (0x34) - Sets `A` to 65535 if the first register is less than the
                            second register, and 0 if it isn't
- `GT (reg) (reg)` (0x35) - Sets `A` to 65535 if the first register is greater than the
                            second register, and 0 if it isn't
- `CMPP (reg pair) (reg pair)` (0x36) - Sets `A` to 65535 if the reg pairs are equal,
                                        and 0 if they aren't
- `LTP (reg pair) (reg pair)` (0x37) - Sets `A` to 65535 if the first reg pair is less
                                       than the second, and 0 if it isn't
- `GTP (reg pair) (reg pair)` (0x38) - Sets `A` to 65535 if the first reg pair is greater
                                       than the second, and 0 if it isn't
- `HLT` (0xFF) - Stops execution
