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
import yeti16.assembler.parser;

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
	Node[]           nodes;
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
		AddInstruction("call", Opcode.CALL, [Param.Addr]);
		AddInstruction("ret",  Opcode.RET,  []);
		AddInstruction("int",  Opcode.INT,  [Param.Byte]);
		AddInstruction("wra",  Opcode.WRA,  [Param.RegisterPair, Param.RegisterPair]);
		AddInstruction("rda",  Opcode.RDA,  [Param.RegisterPair]);
		AddInstruction("cpr",  Opcode.CPR,  [Param.Register, Param.Register]);
		AddInstruction("cpp",  Opcode.CPP,  [Param.RegisterPair, Param.RegisterPair]);
		AddInstruction("jmpb", Opcode.JMPB, [Param.Addr]);
		AddInstruction("jnzb", Opcode.JNZB, [Param.Addr]);
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
		ErrorBegin(nodes[i].error);
		stderr.writeln(str);
	}

	void ExpectType(NodeType type) {
		if (nodes[i].type != type) {
			Error(format("Expected %s, got %s", type, nodes[i].type));
			exit(1);
		}
	}

	void Assemble() {
		// generate labels
		uint labelBase = 0x050000;
		uint labelAddr = labelBase;
		for (i = 0; i < nodes.length; ++ i) {
			switch (nodes[i].type) {
				case NodeType.Label: {
					auto node = cast(LabelNode) nodes[i];
				
					if (InstructionExists(node.name)) {
						Error("Labels cannot have the same name as an instruction");
						exit(1);
					}
				
					labels[node.name] = labelAddr;
					break;
				}
				case NodeType.Instruction: {
					auto node = cast(InstructionNode) nodes[i];
				
					if (!InstructionExists(node.name)) {
						break;
					}

					labelAddr += GetInstructionSize(node.name);
					break;
				}
				default: break;
			}
		}
	
		for (i = 0; i < nodes.length; ++ i) {
			if (nodes[i].type == NodeType.Label) {
				continue;
			}
		
			ExpectType(NodeType.Instruction);

			auto node = cast(InstructionNode) nodes[i];

			if (!InstructionExists(node.name)) {
				Error(format("No such instruction/keyword '%s'", node.name));
				exit(1);
			}

			auto inst  = GetInstruction(node.name);
			output    ~= inst.opcode;

			if (inst.args.length != node.params.length) {
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
						valid = node.params[i].type == NodeType.Register;
						break;
					}
					case Param.RegisterPair: {
						valid = node.params[i].type == NodeType.RegisterPair;
						break;
					}
					case Param.Byte: {
						valid = node.params[i].type == NodeType.Integer;
						break;
					}
					case Param.Word: {
						valid = node.params[i].type == NodeType.Integer;
						break;
					}
					case Param.Addr: {
						valid = (
							(node.params[i].type == NodeType.Integer) ||
							(node.params[i].type == NodeType.Identifier)
						);
						break;
					}
				}

				if (!valid) {
					Error(
						format(
							"Parameter %d is invalid for instruction %s", i + 1,
							inst.name
						)
					);
					exit(1);
				}
			}

			foreach (i, ref arg ; inst.args) {
				final switch (arg) {
					case Param.Register: {
						auto paramNode = cast(RegisterNode) node.params[i];
						
						output ~= RegisterByte(paramNode.name);
						break;
					}
					case Param.RegisterPair: {
						auto paramNode = cast(RegisterPairNode) node.params[i];
					
						output ~= RegisterPairByte(paramNode.name);
						break;
					}
					case Param.Byte: {
						auto paramNode = cast(IntegerNode) node.params[i];
					
						output ~= cast(ubyte) paramNode.value;
						break;
					}
					case Param.Word: {
						auto paramNode = cast(IntegerNode) node.params[i];
					
						ushort word  = cast(ushort) paramNode.value;
						output      ~= cast(ubyte) (word & 0xFF);
						output      ~= cast(ubyte) ((word & 0xFF00) >> 8);
						break;
					}
					case Param.Addr: {
						uint addr;
						
						switch (node.params[i].type) {
							case NodeType.Integer: {
								auto paramNode = cast(IntegerNode) node.params[i];
								
								addr = paramNode.value;

								if ((inst.name == "jmpb") || (inst.name == "jnzb")) {
									addr -= labelBase;
								}
								break;
							}
							case NodeType.Identifier: {
								auto paramNode = cast(IdentifierNode) node.params[i];
							
								addr = labels[paramNode.name];
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
	bool   debugParser;

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
				case "-a":
				case "--parser": {
					debugParser = true;
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

	auto parser = new Parser();
	parser.tokens = lexer.tokens;
	parser.Parse();

	if (debugParser) {
		parser.PrintNodes();
		return 0;
	}

	assembler.nodes = parser.nodes;
	assembler.Assemble();
	std.file.write(outFile, assembler.output);
	return 0;
}
