module yeti16.assembler.assembler;

import std.conv;
import std.file;
import std.stdio;
import std.format;
import std.algorithm;
import core.stdc.stdlib;
import ydlib.common;
import yeti16.computer;
import yeti16.assembler.error;
import yeti16.assembler.lexer;

enum Param {
	Register,
	RegisterPair,
	Byte,
	Word,
	Addr
}

struct InstructionDef {
	string  name;
	ubyte   opcode;
	Param[] args;
}

class Assembler {
	InstructionDef[] defs;
	ubyte[]          output;
	size_t           i;
	Token[]          tokens;
	uint[string]     labels;

	this() {
		AddInstruction("nop",  Opcode.NOP,  []);
		AddInstruction("set",  Opcode.SET,  [Param.Register, Param.Word]);
		AddInstruction("xchg", Opcode.XCHG, [Param.Register, Param.Register]);
		AddInstruction("wrb",  Opcode.WRB,  [Param.RegisterPair, Param.Register]);
		AddInstruction("rdb",  Opcode.RDB,  [Param.RegisterPair]);
		AddInstruction("wrw",  Opcode.WRW,  [Param.RegisterPair, Param.Register]);
		AddInstruction("rdw",  Opcode.RDW,  [Param.RegisterPair]);
		AddInstruction("add",  Opcode.ADD,  [Param.Register, Param.Register]);
		AddInstruction("sub",  Opcode.SUB,  [Param.Register, Param.Register]);
		AddInstruction("mul",  Opcode.MUL,  [Param.Register, Param.Register]);
		AddInstruction("div",  Opcode.DIV,  [Param.Register, Param.Register]);
		AddInstruction("mod",  Opcode.MOD,  [Param.Register, Param.Register]);
		AddInstruction("inc",  Opcode.INC,  [Param.Register]);
		AddInstruction("dec",  Opcode.DEC,  [Param.Register]);
		AddInstruction("cmp",  Opcode.CMP,  [Param.Register, Param.Register]);
		AddInstruction("not",  Opcode.NOT,  [Param.Register]);
		AddInstruction("and",  Opcode.AND,  [Param.Register, Param.Register]);
		AddInstruction("or",   Opcode.OR,   [Param.Register, Param.Register]);
		AddInstruction("xor",  Opcode.XOR,  [Param.Register, Param.Register]);
		AddInstruction("jnz",  Opcode.JNZ,  [Param.Addr]);
		AddInstruction("jmp",  Opcode.JMP,  [Param.Addr]);
		AddInstruction("out",  Opcode.OUT,  [Param.Byte, Param.Register]);
		AddInstruction("in",   Opcode.IN,   [Param.Byte]);
		AddInstruction("lda",  Opcode.LDA,  [Param.RegisterPair, Param.Addr]);
		AddInstruction("incp", Opcode.INCP, [Param.RegisterPair]);
		AddInstruction("decp", Opcode.DECP, [Param.RegisterPair]);
		AddInstruction("setl", Opcode.SETL, [Param.Register]);
		AddInstruction("cpl",  Opcode.CPL,  []);
		AddInstruction("hlt",  Opcode.HLT,  []);
	}

	void AddInstruction(string name, Opcode opcode, Param[] args) {
		defs ~= InstructionDef(name, cast(ubyte) opcode, args);
	}

	bool InstructionExists(string name) {
		foreach (ref inst ; defs) {
			if (inst.name.StringToLower() == name) {
				return true;
			}
		}

		return false;
	}

	InstructionDef GetInstruction(string name) {
		foreach (ref inst ; defs) {
			if (inst.name.StringToLower() == name) {
				return inst;
			}
		}

		assert(0);
	}

	uint GetInstructionSize(string name) {
		auto inst = GetInstruction(name);
		uint ret  = 1;

		foreach (ref param ; inst.args) {
			final switch (param) {
				case Param.Register:
				case Param.RegisterPair:
				case Param.Byte: {
					ret += 1;
					break;
				}
				case Param.Word: ret += 2; break;
				case Param.Addr: ret += 3; break;
			}
		}

		return ret;
	}

	ubyte RegisterByte(string reg) {
		switch (reg) {
			case "a": return 0;
			case "b": return 1;
			case "c": return 2;
			case "d": return 3;
			case "e": return 4;
			case "f": return 5;
			default:  assert(0);
		}
	}

	ubyte RegisterPairByte(string reg) {
		switch (reg) {
			case "ab": return 0;
			case "cd": return 1;
			case "ef": return 2;
			case "ds": return 3;
			case "sr": return 4;
			default:   assert(0);
		}
	}

	void Error(string str) {
		ErrorBegin(ErrorInfo(tokens[i].file, tokens[i].line));
		stderr.writeln(str);
	}

	void ExpectType(TokenType type) {
		if (tokens[i].type != type) {
			Error(format("Expected %s, got %s", type, tokens[i].type));
			exit(1);
		}
	}

	void Assemble() {
		// generate labels
		for (i = 0; i < tokens.length; ++ i) {
			uint addr = 0x050000;

			switch (tokens[i].type) {
				case TokenType.Label: {
					if (InstructionExists(tokens[i].contents)) {
						Error("Labels cannot have the same name as an instruction");
						exit(1);
					}
				
					labels[tokens[i].contents] = addr;
					break;
				}
				case TokenType.Identifier: {
					if (!InstructionExists(tokens[i].contents)) {
						break;
					}

					addr += GetInstructionSize(tokens[i].contents);
					break;
				}
				default: break;
			}
		}
	
		for (i = 0; i < tokens.length; ++ i) {
			if (tokens[i].type == TokenType.End) {
				++ i;
			}
			if (tokens[i].type == TokenType.Label) {
				continue;
			}
		
			ExpectType(TokenType.Identifier);

			if (!InstructionExists(tokens[i].contents)) {
				Error(format("No such instruction/keyword '%s'", tokens[i].contents));
				exit(1);
			}

			auto inst  = GetInstruction(tokens[i].contents);
			output    ~= inst.opcode;

			Token[] params;

			++ i;
			while (tokens[i].type != TokenType.End) {
				params ~= tokens[i];
				++ i;
			}

			if (inst.args.length != params.length) {
				Error(
					format(
						"Wrong parameter amount for instruction '%s'", inst.name
					)
				);
				exit(1);
			}

			foreach (i, ref arg ; inst.args) {
				bool valid;
			
				final switch (arg) {
					case Param.Register: {
						valid = params[i].type == TokenType.Register;
						break;
					}
					case Param.RegisterPair: {
						valid = params[i].type == TokenType.RegisterPair;
						break;
					}
					case Param.Byte: {
						valid = params[i].type == TokenType.Integer;
						break;
					}
					case Param.Word: {
						valid = params[i].type == TokenType.Integer;
						break;
					}
					case Param.Addr: {
						valid = (
							(params[i].type == TokenType.Integer) ||
							(params[i].type == TokenType.Identifier)
						);
						break;
					}
				}

				if (!valid) {
					writeln(params[i]);
					Error(format("Parameter %d is invalid", i + 1));
					exit(1);
				}
			}

			foreach (i, ref arg ; inst.args) {
				final switch (arg) {
					case Param.Register: {
						output ~= RegisterByte(params[i].contents);
						break;
					}
					case Param.RegisterPair: {
						output ~= RegisterPairByte(params[i].contents);
						break;
					}
					case Param.Byte: {
						output ~= parse!ubyte(params[i].contents);
						break;
					}
					case Param.Word: {
						ushort word  = parse!ushort(params[i].contents);
						output      ~= cast(ubyte) (word & 0xFF);
						output      ~= cast(ubyte) ((word & 0xFF00) >> 8);
						break;
					}
					case Param.Addr: {
						uint addr;
						
						switch (params[i].type) {
							case TokenType.Integer: {
								addr = parse!int(params[i].contents);
								break;
							}
							case TokenType.Identifier: {
								if (InstructionExists(params[i].contents)) {
									Error("Instruction name as identifier");
									exit(1);
								}
							
								addr = labels[params[i].contents];
								break;
							}
							default: assert(0);
						}

						output ~= cast(ubyte) (addr & 0xFF);
						output ~= cast(ubyte) ((addr & 0xFF00) >> 8);
						output ~= cast(ubyte) ((addr & 0xFF0000) >> 16);
						break;
					}
				}
			}
		}
	}
}

int AssemblerCLI(string[] args) {
	string inFile;
	string outFile = "out.bin";
	bool   debugLexer;

	for (size_t i = 0; i < args.length; ++ i) {
		if (args[i][0] == '-') {
			switch (args[i]) {
				case "-o": {
					++ i;
					outFile = args[i];
					break;
				}
				case "-t":
				case "--tokens": {
					debugLexer = true;
					break;
				}
				default: {
					stderr.writefln("Unknown flag '%s'", args[i]);
					return 1;
				}
			}
		}
		else {
			inFile = args[i];
		}
	}

	if (inFile == "") {
		stderr.writefln("Assembler: no input file");
		return 1;
	}

	auto assembler = new Assembler();
	auto lexer     = new Lexer();

	lexer.src = readText(inFile);
	lexer.Lex();

	if (debugLexer) {
		foreach (ref token ; lexer.tokens) {
			writeln(token);
		}
		return 0;
	}

	assembler.tokens = lexer.tokens;
	assembler.Assemble();
	std.file.write(outFile, assembler.output);
	return 0;
}
