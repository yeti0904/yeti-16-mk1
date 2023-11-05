# Devices
YETI-16 has a few devices that you can control with the IO instructions (`IN`, `OUT`, `CHK`, `ACTV`)

## Common protocol
Devices operate by the program sending opcodes and operands through `OUT`

All devices have 1 opcode in common, which is 81 (or 0x51, or 'Q')

This opcode returns 51, and then a null terminated string containing the device's name

## Devices
### 0x00 - YETI-16 Debug Device
This device is for basic debug/testing, it can print to the console

#### Opcodes
- `P`/80/0x50 - Prints the operand to the console

### 0x01 - YETI-16 Keyboard
This device receives keyboard events and sends them to the console

It sends keyboard events through input in this format:
- Event type ('D' for key down)
- Key (ASCII)

You can also send commands to it to see what commands are currently pressed, in this format
- ASCII character `S`
- ASCII key you want to check
and then it returns data in this format
- ASCII character `S`
- 0xFFFF if the key is pressed, 0 if it isn't

### 0x02 YETI-16 Graphics Controller
This is a device for loading default palettes and fonts

The default palette can be loaded by sending the ASCII character `P`
