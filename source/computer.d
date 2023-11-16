module yeti16.computer;

import std.file;
import std.math;
import std.stdio;
import std.format;
import std.random;
import std.algorithm;
import std.datetime.stopwatch;
import core.bitop;
import core.thread;
import core.stdc.stdlib;
import bindbc.sdl;
import yeti16.util;
import yeti16.display;
import yeti16.palette;
import yeti16.deviceBase;
import yeti16.devices.disk;

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
	CHK  = 0x25,
	ACTV = 0x26,
	ADDP = 0x27,
	SUBP = 0x28,
	DIFF = 0x29,
	PUSH = 0x2A,
	POP  = 0x2B,
	JZ   = 0x2C,
	JZB  = 0x2D,
	RDBB = 0x2E,
	RDWB = 0x2F,
	RDAB = 0x30,
	WRBB = 0x31,
	WRWB = 0x32,
	WRAB = 0x33,
	LT   = 0x34,
	GT   = 0x35,
	CMPP = 0x36,
	LTP  = 0x37,
	GTP  = 0x38,
	HLT  = 0xFF
}

enum Register {
	A = 0,
	B = 1,
	C = 2,
	D = 3,
	E = 4,
	F = 5,
	H = 6,
	I = 7
}

enum RegPair {
	AB = 0,
	CD = 1,
	EF = 2,
	DS = 3,
	SR = 4,
	BS = 5,
	IP = 6,
	SP = 7,
	HI = 8
}

enum ErrorInterrupt {
	Null               = 0,
	DivZero            = 1,
	BadParam           = 2,
	DisabledInterrupt  = 3,
	InvalidDevice      = 4,
	InvalidInstruction = 5,
	StackUnderflow     = 6,
	StackOverflow      = 7, // fuck this website
	NothingToRead      = 8
}

class ComputerException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

class CancelInstruction : Exception {
	this(string file = __FILE__, size_t line = __LINE__) {
		super("", file, line);
	}
}

class Computer {
	static const uint   ramSize = 16777216; // 16 MiB
	static const double speed   = 8; // MHz

	ubyte[]     ram;
	bool        halted;
	Device[256] devices;
	Display     display;

	// registers
	ushort a;
	ushort b;
	ushort c;
	ushort d;
	ushort e;
	ushort f;
	ushort h;
	ushort i;
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

		// initialise interrupt table
		for (uint i = 0x000004; i < 0x000404; ++ i) {
			ram[i] = 0;
		}

		// initialise devices
		import yeti16.devices.debugDevice;
		import yeti16.devices.keyboard;
		import yeti16.devices.graphicsController;
		devices[0] = new Debug();
		devices[1] = new Keyboard();
		devices[2] = new GraphicsController();

		foreach (ref dev ; devices) {
			if (dev is null) continue;

			dev.computer = this;
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
			case Register.A: a = value; break;
			case Register.B: b = value; break;
			case Register.C: c = value; break;
			case Register.D: d = value; break;
			case Register.E: e = value; break;
			case Register.F: f = value; break;
			case Register.H: h = value; break;
			case Register.I: i = value; break;
			default:         Error(ErrorInterrupt.BadParam);
		}
	}

	ushort ReadReg(ubyte reg) {
		switch (reg) {
			case Register.A: return a;
			case Register.B: return b;
			case Register.C: return c;
			case Register.D: return d;
			case Register.E: return e;
			case Register.F: return f;
			case Register.H: return h;
			case Register.I: return i;
			default: {
				Error(ErrorInterrupt.BadParam);
				return 0;
			}
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
			case RegPair.IP: ip = value; break;
			case RegPair.SP: sp = value; break;
			case RegPair.HI: {
				h = cast(ushort) ((value & 0xFF0000) >> 16);
				i = cast(ushort) (value & 0xFFFF);
				break;
			}
			default:         Error(ErrorInterrupt.BadParam);
		}
	}

	uint ReadRegPair(ubyte reg) {
		switch (reg) {
			case RegPair.AB: return (cast(uint) (a) << 16) | b;
			case RegPair.CD: return (cast(uint) (c) << 16) | d;
			case RegPair.EF: return (cast(uint) (e) << 16) | f;
			case RegPair.DS: return ds;
			case RegPair.SR: return sr;
			case RegPair.BS: return bs;
			case RegPair.IP: return ip;
			case RegPair.SP: return sp;
			case RegPair.HI: return (cast(uint) (h) << 16) | i;
			default: {
				Error(ErrorInterrupt.BadParam);
				return 0;
			}
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
			Error(ErrorInterrupt.DisabledInterrupt);
		}

		WriteAddr(sp, ip);
		sp += 3;
		ip  = ReadAddr(interruptAddr + 1);
	}

	void Error(ErrorInterrupt error) {
		if (InterruptEnabled(cast(ubyte) error)) {
			CallInterrupt(cast(ubyte) error);
			throw new CancelInstruction();
		}
		else {
			final switch (error) {
				case ErrorInterrupt.Null: {
					throw new ComputerException("Wrote to NULL");
				}
				case ErrorInterrupt.DivZero: {
					throw new ComputerException("Divided by 0");
				}
				case ErrorInterrupt.BadParam: {
					throw new ComputerException("Bad parameter");
				}
				case ErrorInterrupt.DisabledInterrupt: {
					throw new ComputerException("Called disabled interrupt");
				}
				case ErrorInterrupt.InvalidDevice: {
					throw new ComputerException("Using invalid device");
				}
				case ErrorInterrupt.InvalidInstruction: {
					throw new ComputerException("Invalid instruction");
				}
				case ErrorInterrupt.StackUnderflow: {
					throw new ComputerException("Stack underflow");
				}
				case ErrorInterrupt.StackOverflow: {
					throw new ComputerException("Stack overflow");
				}
				case ErrorInterrupt.NothingToRead: {
					throw new ComputerException("Nothing to read");
				}
			}
		}
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
				auto dev = ReadReg(NextByte()) & 0xFF;
				auto val = ReadReg(NextByte());

				auto device = devices[dev];

				if (device is null) {
					Error(ErrorInterrupt.InvalidDevice);
				}

				device.Out(val);
				break;
			}
			case Opcode.IN: {
				auto dev    = ReadReg(NextByte()) & 0xFF;
				auto device = devices[dev];

				if (device is null) {
					Error(ErrorInterrupt.InvalidDevice);
				}

				if (device.data.length == 0) {
					Error(ErrorInterrupt.NothingToRead);
				}

				a           = device.data[0];
				device.data = device.data.remove(0);
				break;
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
			case Opcode.CHK: {
				auto dev = ReadReg(NextByte()) & 0xFF;

				auto device = devices[dev];

				if (device is null) {
					Error(ErrorInterrupt.InvalidDevice);
				}

				a = device.data.length == 0? 0 : 0xFFFF;
				break;
			}
			case Opcode.ACTV: {
				auto dev = ReadReg(NextByte()) & 0xFF;

				a = devices[dev] is null? 0 : 0xFFFF;
				break;
			}
			case Opcode.ADDP: {
				auto r1 = NextByte();
				auto r2 = NextByte();
				auto v1 = ReadRegPair(r1);
				auto v2 = ReadReg(r2);

				WriteRegPair(r1, v1 + cast(uint) v2);
				break;
			}
			case Opcode.SUBP: {
				auto r1 = NextByte();
				auto r2 = NextByte();
				auto v1 = ReadRegPair(r1);
				auto v2 = ReadReg(r2);

				WriteRegPair(r1, v1 - cast(uint) v2);
				break;
			}
			case Opcode.DIFF: {
				auto v1 = cast(long) ReadRegPair(NextByte());
				auto v2 = cast(long) ReadRegPair(NextByte());

				WriteRegPair(RegPair.AB, cast(uint) abs(v1 - v2));
				break;
			}
			case Opcode.PUSH: {
				auto val = ReadReg(NextByte());
				WriteWord(sp, val);
				sp += 2;
				break;
			}
			case Opcode.POP: {
				auto reg = NextByte();
				sp -= 2;
				WriteReg(reg, ReadWord(sp));
				break;
			}
			case Opcode.JZ: {
				auto addr = NextAddr();

				if (a == 0) {
					ip = addr;
				}
				break;
			}
			case Opcode.JZB: {
				auto addr = NextAddr();

				if (a == 0) {
					ip = bs + addr;
				}
				break;
			}
			case Opcode.RDBB: {
				auto addr = ReadRegPair(NextByte());
				a = ram[bs + addr];
				break;
			}
			case Opcode.RDWB: {
				auto addr = ReadRegPair(NextByte());
				a = ReadWord(bs + addr);
				break;
			}
			case Opcode.RDAB: {
				auto addr = ReadRegPair(NextByte());
				WriteRegPair(RegPair.AB, ReadAddr(bs + addr));
				break;
			}
			case Opcode.WRBB: {
				auto addr      = ReadRegPair(NextByte());
				auto value     = ReadReg(NextByte());
				ram[bs + addr] = cast(ubyte) value;
				break;
			}
			case Opcode.WRWB: {
				auto addr  = ReadRegPair(NextByte());
				auto value = ReadReg(NextByte());
				WriteWord(bs + addr, value);
				break;
			}
			case Opcode.WRAB: {
				auto addr = ReadRegPair(NextByte());
				auto value = ReadRegPair(NextByte());
				WriteAddr(bs + addr, value);
				break;
			}
			case Opcode.LT: {
				auto v1 = ReadReg(NextByte());
				auto v2 = ReadReg(NextByte());
				a       = v1 < v2? 0xFFFF : 0;
				break;
			}
			case Opcode.GT: {
				auto v1 = ReadReg(NextByte());
				auto v2 = ReadReg(NextByte());
				a       = v1 > v2? 0xFFFF : 0;
				break;
			}
			case Opcode.CMPP: {
				auto v1 = ReadRegPair(NextByte());
				auto v2 = ReadRegPair(NextByte());
				a       = v1 == v2? 0xFFFF : 0;
				break;
			}
			case Opcode.LTP: {
				auto v1 = ReadRegPair(NextByte());
				auto v2 = ReadRegPair(NextByte());
				a       = v1 < v2? 0xFFFF : 0;
				break;
			}
			case Opcode.GTP: {
				auto v1 = ReadRegPair(NextByte());
				auto v2 = ReadRegPair(NextByte());
				a       = v1 > v2? 0xFFFF : 0;
				break;
			}
			case Opcode.HLT: {
				halted = true;
				break;
			}
			default: Error(ErrorInterrupt.InvalidInstruction);
		}
	}
}

int ComputerCLI(string[] args) {
	auto display  = new Display();
	display.Init();
	writeln("Initialised display");
	
	auto computer = new Computer();
	display.computer = computer;
	computer.display = display;

	ubyte[] program = [0x14, 0x00, 0x00, 0x05];

	ubyte deviceTop = 0x16;

	for (size_t i = 0; i < args.length; ++ i) {
		if (args[i][0] == '-') {
			switch (args[i]) {
				case "-d":
				case "--disk": {
					++ i;
					Disk disk;

					try {
						disk = new Disk(args[i]);
					}
					catch (DiskException e) {
						stderr.writeln(e.msg);
						return 1;
					}

					computer.devices[deviceTop] = disk;
					++ deviceTop;
					break;
				}
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
		computer.ram[0x050000 + i] = b;
	}
	computer.ip = 0x050000;
	computer.bs = 0x050000;
	computer.sp = 0x0F0000;

	ulong  ticks;
	double frameTimeGoal = 1000 / 60;
	uint   instPerFrame  = cast(uint) ((Computer.speed * 1000000) / 60);

	writefln("Running %d instructions per frame", instPerFrame);

	writeln("Connected devices:");

	foreach (i, ref dev ; computer.devices) {
		if (dev is null) continue;
	
		writefln(" - (%X) %s", i, dev.name);
	}

	ubyte rtxID = 255;

	foreach_reverse (ref dev ; computer.devices) {
		if (dev is null) {
			-- rtxID;
		}
		else {
			break;
		}
	}

	++ rtxID;

	writefln(" - (%X) Nvidia RTX 4090 Ti", rtxID); // hee hee

	double[60] times;
	
	while (!computer.halted) {
		SDL_Event e;
		while (SDL_PollEvent(&e)) {
			switch (e.type) {
				case SDL_QUIT: {
					exit(0);
				}
				default: {
					foreach (ref dev ; computer.devices) {
						if (dev is null) continue;

						dev.HandleEvent(&e);
					}
					break;
				}
			}
		}

		auto sw = StopWatch(AutoStart.yes);

		foreach (i ; 0 .. instPerFrame) {
			try {
				computer.RunInstruction();
			}
			catch (CancelInstruction) {
				continue;
			}
			catch (Exception e) {
				stderr.writeln("EMULATOR CRASH!");
				stderr.writeln("===============");
				stderr.writefln(
					"A: %X\nB: %X\nC: %X\nD: %X\nE: %X\nF: %X\nDS: %X\nSR: %X\n" ~
					"IP: %X\nSP: %X\nBS: %X",
					computer.a, computer.b, computer.c, computer.d, computer.e, computer.f,
					computer.ds, computer.sr, computer.ip, computer.sp, computer.bs
				);
				stderr.writeln("===============");
				stderr.writefln("RAM[IP] = %.2X", computer.ram[computer.ip]);
				writeln(e);
				return 1;
			}
		}

		foreach (ref dev ; computer.devices) {
			if (dev is null) continue;

			dev.Update();
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
