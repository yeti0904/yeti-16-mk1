module yeti16.computer;

import std.file;
import std.stdio;
import std.format;
import std.random;
import std.datetime.stopwatch;
import core.bitop;
import core.stdc.stdlib;
import bindbc.sdl;
import yeti16.util;
import yeti16.display;
import yeti16.palette;

enum Opcode {
	NOP  = 0x00,
	SET  = 0x01,
	XCHG = 0x02,
	WRB  = 0x03,
	RDB  = 0x04,
	WRW  = 0x05,
	RDW  = 0x06,
	ADD  = 0x07,
	SUB  = 0x08,
	MUL  = 0x09,
	DIV  = 0x0A,
	MOD  = 0x0B,
	INC  = 0x0C,
	DEC  = 0x0D,
	CMP  = 0x0E,
	NOT  = 0x0F,
	AND  = 0x10,
	OR   = 0x11,
	XOR  = 0x12,
	JNZ  = 0x13,
	JMP  = 0x14,
	OUT  = 0x15,
	IN   = 0x16,
	LDA  = 0x17,
	INCP = 0x18,
	DECP = 0x19,
	SETL = 0x1A,
	CPL  = 0x1B,
	HLT  = 0xFF
}

class ComputerException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

class Computer {
	static const uint  ramSize = 16777216; // 16 MiB
	static const float speed   = 1; // MHz

	ubyte[] ram;
	bool    halted;

	// registers
	ushort a;
	ushort b;
	ushort c;
	ushort d;
	ushort e;
	ushort f;
	uint   ds;
	uint   sr;
	uint   ip;
	uint   sp;

	this() {
		ram    = new ubyte[](Computer.ramSize);
		halted = false;

		ubyte[256] chunk;

		for (size_t i = 0; i < chunk.length; ++ i) {
			chunk[i] = cast(ubyte) uniform(0, 256);
		}

		foreach (i, ref b ; ram) {
			b = (cast(ubyte) chunk[i % 256]).rol(i % 8);
		}

		// initialise display stuff
		ram[0x000404] = 0x10; // 320x200 8bpp
		for (uint i = 0; i < cast(uint) palette.length; ++ i) {
			ram[0x00FE05 + i] = palette[i];
		}
	}

	ubyte NextByte() {
		auto ret = ram[ip];
		++ ip;
		return ret;
	}

	ushort NextWord() {
		ushort ret = ram[ip];
		++ ip;
		ret |= ram[ip] << 8;
		++ ip;
		return ret;
	}

	uint NextAddr() {
		uint ret = ram[ip];
		++ ip;
		ret |= ram[ip] << 8;
		++ ip;
		ret |= ram[ip] << 16;
		++ ip;
		return ret;
	}

	void WriteReg(ubyte reg, ushort value) {
		switch (reg) {
			case 0:  a = value; break;
			case 1:  b = value; break;
			case 2:  c = value; break;
			case 3:  d = value; break;
			case 4:  e = value; break;
			case 5:  f = value; break;
			default: throw new ComputerException(format("Invalid register %X", reg));
		}
	}

	ushort ReadReg(ubyte reg) {
		switch (reg) {
			case 0:  return a;
			case 1:  return b;
			case 2:  return c;
			case 3:  return d;
			case 4:  return e;
			case 5:  return f;
			default: throw new ComputerException(format("Invalid register %X", reg));
		}
	}

	void WriteRegPair(ubyte reg, uint value) {
		switch (reg) {
			case 0: {
				a = cast(ushort) ((value & 0xFF0000) >> 16);
				b = cast(ushort) (value & 0xFFFF);
				break;
			}
			case 1: {
				c = cast(ushort) ((value & 0xFF0000) >> 16);
				d = cast(ushort) (value & 0xFFFF);
				break;
			}
			case 2: {
				e = cast(ushort) ((value & 0xFF0000) >> 16);
				f = cast(ushort) (value & 0xFFFF);
				break;
			}
			case 3: ds = value; break;
			case 4: sr = value; break;
			default: throw new ComputerException(format("Invalid register %X", reg));
		}
	}

	uint ReadRegPair(ubyte reg) {
		switch (reg) {
			case 0:  return cast(ubyte) ((a << 16) | b);
			case 1:  return cast(ubyte) ((c << 16) | d);
			case 2:  return cast(ubyte) ((e << 16) | f);
			case 3:  return ds;
			case 4:  return sr;
			default: throw new ComputerException(format("Invalid register %X", reg));
		}
	}

	ushort ReadWord(uint addr) {
		ushort ret = ram[addr];
		ret |= ram[addr + 1] << 8;
		return ret;
	}

	void WriteWord(uint addr, ushort value) {
		ram[addr]     = cast(ubyte) (value & 0xFF);
		ram[addr + 1] = cast(ubyte) (value & 0xFF00);
	}

	void RunInstruction() {
		if (halted) return;

		ubyte inst = NextByte();

		switch (inst) {
			case Opcode.NOP: break;
			case Opcode.SET: {
				auto reg   = NextByte();
				auto value = NextWord();

				WriteReg(reg, value);
				break;
			}
			case Opcode.XCHG: {
				auto reg1 = NextByte();
				auto reg2 = NextByte();
				auto val1 = ReadReg(reg1);
				auto val2 = ReadReg(reg2);
				WriteReg(reg1, val2);
				WriteReg(reg2, val1);
				break;
			}
			case Opcode.WRB: {
				auto addr  = ReadRegPair(NextByte());
				auto value = ReadReg(NextByte());
				ram[addr]  = cast(ubyte) (value & 0xFF);
				break;
			}
			case Opcode.RDB: {
				auto addr = ReadRegPair(NextByte());
				a         = ram[addr];
				break;
			}
			case Opcode.WRW: {
				WriteWord(ReadRegPair(NextByte()), ReadReg(NextByte()));
				break;
			}
			case Opcode.RDW: {
				a = ReadWord(ReadRegPair(NextByte()));
				break;
			}
			case Opcode.ADD:
			case Opcode.SUB:
			case Opcode.MUL:
			case Opcode.DIV:
			case Opcode.MOD: {
				auto   r1 = NextByte();
				auto   r2 = NextByte();
				ushort v1 = ReadReg(r1);
				ushort v2 = ReadReg(r2);

				final switch (inst) {
					case Opcode.ADD: WriteReg(r1, cast(ushort) (v1 + v2)); break;
					case Opcode.SUB: WriteReg(r1, cast(ushort) (v1 - v2)); break;
					case Opcode.MUL: WriteReg(r1, cast(ushort) (v1 * v2)); break;
					case Opcode.DIV: WriteReg(r1, cast(ushort) (v1 / v2)); break;
					case Opcode.MOD: WriteReg(r1, cast(ushort) (v1 % v2)); break;
				}
				break;
			}
			case Opcode.INC: {
				auto reg = NextByte();
				
				WriteReg(reg, cast(ushort) (ReadReg(reg) + 1));
				break;
			}
			case Opcode.DEC: {
				auto reg = NextByte();
				WriteReg(reg, cast(ushort) (ReadReg(reg) - 1));
				break;
			}
			case Opcode.CMP: {
				auto val1 = ReadReg(NextByte());
				auto val2 = ReadReg(NextByte());
				a         = val1 == val2? 0xFFFF : 0;
				break;
			}
			case Opcode.NOT: {
				auto reg = NextByte();
				WriteReg(reg, cast(ushort) (~ReadReg(reg)));
				break;
			}
			case Opcode.AND:
			case Opcode.OR:
			case Opcode.XOR: {
				auto   r1 = NextByte();
				auto   r2 = NextByte();
				ushort v1 = ReadReg(r1);
				ushort v2 = ReadReg(r2);

				final switch (inst) {
					case Opcode.AND: WriteReg(r1, v1 & v2); break;
					case Opcode.OR:  WriteReg(r1, v1 | v2); break;
					case Opcode.XOR: WriteReg(r1, v1 ^ v2); break;
				}
				break;
			}
			case Opcode.JNZ: {
				auto addr = NextAddr();

				if (a != 0) {
					ip = addr;
				}
				break;
			}
			case Opcode.JMP: {
				ip = NextAddr();
				break;
			}
			case Opcode.OUT: {
				auto dev = NextByte();
				auto val = ReadReg(NextByte());

				switch (dev) {
					default: throw new ComputerException(format("Invalid device %X", dev));
				}
			}
			case Opcode.IN: {
				auto dev = NextByte();

				switch (dev) {
					default: throw new ComputerException(format("Invalid device %X", dev));
				}
			}
			case Opcode.LDA: {
				auto reg  = NextByte();
				auto addr = NextAddr();
				WriteRegPair(reg, addr);
				break;
			}
			case Opcode.INCP: {
				auto reg = NextByte();
				WriteRegPair(reg, ReadRegPair(reg) + 1);
				break;
			}
			case Opcode.DECP: {
				auto reg = NextByte();
				WriteRegPair(reg, ReadRegPair(reg) - 1);
				break;
			}
			case Opcode.SETL: {
				auto value = cast(ubyte) (ReadReg(NextByte()) & 0xFF);

				while (c > 0) {
					ram[ds] = value;

					++ ds;

					if (ds > 0xFFFFFF) ds = 0;
					-- c;
				}
				break;
			}
			case Opcode.CPL: {
				while (c > 0) {
					ram[ds] = ram[sr];

					++ ds;
					++ sr;

					if (ds > 0xFFFFFF) ds = 0;
					if (sr > 0xFFFFFF) sr = 0;

					-- c;
				}
				break;
			}
			case Opcode.HLT: {
				halted = true;
				break;
			}
			default: throw new ComputerException(format("Invalid instruction %X", inst));
		}
	}
}

int ComputerCLI(string[] args) {
	auto computer = new Computer();
	auto display  = new Display();
	display.Init();
	display.computer = computer;

	ubyte[] program = [0x14, 0x00, 0x00, 0x05];

	for (size_t i = 0; i < args.length; ++ i) {
		if (args[i][0] == '-') {
			switch (args[i]) {
				default: {
					stderr.writefln("Unknown flag '%s'", args[i]);
					return 1;
				}
			}
		}
		else {
			program = cast(ubyte[]) read(args[i]);
		}
	}

	foreach (i, ref b ; program) {
		computer.ram[0x50000 + i] = b;
	}
	computer.ip = 0x50000;

	ulong ticks;
	while (!computer.halted) {
		SDL_Event e;
		while (SDL_PollEvent(&e)) {
			switch (e.type) {
				case SDL_QUIT: {
					exit(0);
				}
				default: break;
			}
		}

		try {
			computer.RunInstruction();
		}
		catch (Exception e) {
			stderr.writeln("EMULATOR CRASH!");
			stderr.writeln("===============");
			stderr.writefln(
				"A: %X\nB: %X\nC: %X\nD: %X\nE: %X\nF: %X\nDS: %X\nSR: %X\n" ~
				"IP: %X\nSP: %X",
				computer.a, computer.b, computer.c, computer.d, computer.e, computer.f,
				computer.ds, computer.sr, computer.ip, computer.sp
			);
			writeln(e);
			return 1;
		}
		display.Render();
	}

	return 0;
}
