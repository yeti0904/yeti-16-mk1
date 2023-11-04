module yeti16.computer;

import std.file;
import std.stdio;
import std.format;
import std.random;
import std.datetime.stopwatch;
import core.bitop;
import core.thread;
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
	CALL = 0x1C,
	RET  = 0x1D,
	INT  = 0x1E,
	WRA  = 0x1F,
	RDA  = 0x20,
	CPR  = 0x21,
	CPP  = 0x22,
	JMPB = 0x23,
	JNZB = 0x24,
	HLT  = 0xFF
}

enum Register {
	A = 0,
	B = 1,
	C = 2,
	D = 3,
	E = 4,
	F = 5
}

enum RegPair {
	AB = 0,
	CD = 1,
	EF = 2,
	DS = 3,
	SR = 4,
	BS = 5
}

class ComputerException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

class Computer {
	static const uint   ramSize = 16777216; // 16 MiB
	static const double speed   = 8; // MHz

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
	uint   bs;

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
			case Register.A:  a = value; break;
			case Register.B:  b = value; break;
			case Register.C:  c = value; break;
			case Register.D:  d = value; break;
			case Register.E:  e = value; break;
			case Register.F:  f = value; break;
			default: throw new ComputerException(format("Invalid register %X", reg));
		}
	}

	ushort ReadReg(ubyte reg) {
		switch (reg) {
			case Register.A:  return a;
			case Register.B:  return b;
			case Register.C:  return c;
			case Register.D:  return d;
			case Register.E:  return e;
			case Register.F:  return f;
			default: throw new ComputerException(format("Invalid register %X", reg));
		}
	}

	void WriteRegPair(ubyte reg, uint value) {
		switch (reg) {
			case RegPair.AB: {
				a = cast(ushort) ((value & 0xFF0000) >> 16);
				b = cast(ushort) (value & 0xFFFF);
				break;
			}
			case RegPair.CD: {
				c = cast(ushort) ((value & 0xFF0000) >> 16);
				d = cast(ushort) (value & 0xFFFF);
				break;
			}
			case RegPair.EF: {
				e = cast(ushort) ((value & 0xFF0000) >> 16);
				f = cast(ushort) (value & 0xFFFF);
				break;
			}
			case RegPair.DS: ds = value; break;
			case RegPair.SR: sr = value; break;
			case RegPair.BS: bs = value; break;
			default: throw new ComputerException(format("Invalid register %X", reg));
		}
	}

	uint ReadRegPair(ubyte reg) {
		switch (reg) {
			case RegPair.AB: return cast(ubyte) ((a << 16) | b);
			case RegPair.CD: return cast(ubyte) ((c << 16) | d);
			case RegPair.EF: return cast(ubyte) ((e << 16) | f);
			case RegPair.DS: return ds;
			case RegPair.SR: return sr;
			case RegPair.BS: return bs;
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
		ram[addr + 1] = cast(ubyte) ((value & 0xFF00) >> 8);
	}

	uint ReadAddr(uint addr) {
		uint ret = ram[addr];
		ret |= ram[addr + 1] << 8;
		ret |= ram[addr + 2] << 16;
		return ret;
	}

	void WriteAddr(uint addr, uint value) {
		ram[addr]     = cast(ubyte) (value & 0xFF);
		ram[addr + 1] = cast(ubyte) ((value & 0xFF00) >> 8);
		ram[addr + 2] = cast(ubyte) ((value & 0xFF0000) >> 16);
	}

	bool InterruptEnabled(ubyte interrupt) {
		return ram[4 + (interrupt * 4)] == 0? false : true;
	}

	void CallInterrupt(ubyte interrupt) {
		uint interruptAddr = 4 + (interrupt * 4);

		if (ram[interruptAddr] == 0) {
			throw new ComputerException(format("Called disabled register %X", interrupt));
		}

		WriteAddr(sp, ip);
		sp += 3;
		ip  = ReadAddr(interruptAddr + 1);
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
			case Opcode.CALL: {
				auto addr = NextAddr();

				WriteAddr(sp, ip);
				sp += 3;
				ip  = addr;
				break;
			}
			case Opcode.RET: {
				sp -= 3;
				ip  = ReadAddr(sp);
				break;
			}
			case Opcode.INT: {
				auto interrupt = NextByte();
				CallInterrupt(interrupt);
				break;
			}
			case Opcode.WRA: {
				auto addr  = ReadRegPair(NextByte());
				auto value = ReadRegPair(NextByte());

				WriteAddr(addr, value);
				break;
			}
			case Opcode.RDA: {
				auto addr = ReadRegPair(NextByte());

				WriteRegPair(RegPair.AB, ReadAddr(addr));
				break;
			}
			case Opcode.CPR: {
				auto reg1 = NextByte();
				auto reg2 = NextByte();
				WriteReg(reg1, ReadReg(reg2));
				break;
			}
			case Opcode.CPP: {
				auto reg1 = NextByte();
				auto reg2 = NextByte();
				WriteRegPair(reg1, ReadRegPair(reg2));
				break;
			}
			case Opcode.JMPB: {
				auto addr = NextAddr();
				ip        = bs + addr;
				break;
			}
			case Opcode.JNZB: {
				auto addr = NextAddr();

				if (a != 0) {
					ip = bs + addr;
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

	ulong  ticks;
	double frameTimeGoal = 1000 / 60;
	uint   instPerFrame  = cast(uint) ((Computer.speed * 1000000) / 60);

	writefln("Running %d instructions per frame", instPerFrame);

	double[60] times;
	
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

		auto sw = StopWatch(AutoStart.yes);

		foreach (i ; 0 .. instPerFrame) {
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
		}
		display.Render();

		sw.stop();

		double frameTime = sw.peek.total!("msecs");
		if (frameTimeGoal > frameTime) {
			Thread.sleep(dur!("msecs")(cast(long) (frameTimeGoal - frameTime)));
		}
		
		++ ticks;
		if (ticks >= 60) ticks = 0;
	}

	return 0;
}
