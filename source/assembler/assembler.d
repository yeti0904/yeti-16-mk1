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
	bool    special;
}

class Assembler {
	InstructionDef[] defs;
	ubyte[]          output;
	size_t           i;
	Node[]           nodes;
	uint[string]     labels;
	Node[string]     macros;

	this() {
		// instructions
		AddInstruction("nop",   Opcode.NOP,   []);
		AddInstruction("set",   Opcode.SET,   [Param.Register, Param.Word]);
		AddInstruction("xchg",  Opcode.XCHG,  [Param.Register, Param.Register]);
		AddInstruction("wrb",   Opcode.WRB,   [Param.RegisterPair, Param.Register]);
		AddInstruction("rdb",   Opcode.RDB,   [Param.RegisterPair]);
		AddInstruction("wrw",   Opcode.WRW,   [Param.RegisterPair, Param.Register]);
		AddInstruction("rdw",   Opcode.RDW,   [Param.RegisterPair]);
		AddInstruction("add",   Opcode.ADD,   [Param.Register, Param.Register]);
		AddInstruction("sub",   Opcode.SUB,   [Param.Register, Param.Register]);
		AddInstruction("mul",   Opcode.MUL,   [Param.Register, Param.Register]);
		AddInstruction("div",   Opcode.DIV,   [Param.Register, Param.Register]);
		AddInstruction("mod",   Opcode.MOD,   [Param.Register, Param.Register]);
		AddInstruction("inc",   Opcode.INC,   [Param.Register]);
		AddInstruction("dec",   Opcode.DEC,   [Param.Register]);
		AddInstruction("cmp",   Opcode.CMP,   [Param.Register, Param.Register]);
		AddInstruction("not",   Opcode.NOT,   [Param.Register]);
		AddInstruction("and",   Opcode.AND,   [Param.Register, Param.Register]);
		AddInstruction("or",    Opcode.OR,    [Param.Register, Param.Register]);
		AddInstruction("xor",   Opcode.XOR,   [Param.Register, Param.Register]);
		AddInstruction("jnz",   Opcode.JNZ,   [Param.Addr]);
		AddInstruction("jmp",   Opcode.JMP,   [Param.Addr]);
		AddInstruction("out",   Opcode.OUT,   [Param.Register, Param.Register]);
		AddInstruction("in",    Opcode.IN,    [Param.Register]);
		AddInstruction("lda",   Opcode.LDA,   [Param.RegisterPair, Param.Addr]);
		AddInstruction("incp",  Opcode.INCP,  [Param.RegisterPair]);
		AddInstruction("decp",  Opcode.DECP,  [Param.RegisterPair]);
		AddInstruction("setl",  Opcode.SETL,  [Param.Register]);
		AddInstruction("cpl",   Opcode.CPL,   []);
		AddInstruction("call",  Opcode.CALL,  [Param.Addr]);
		AddInstruction("ret",   Opcode.RET,   []);
		AddInstruction("int",   Opcode.INT,   [Param.Byte]);
		AddInstruction("wra",   Opcode.WRA,   [Param.RegisterPair, Param.RegisterPair]);
		AddInstruction("rda",   Opcode.RDA,   [Param.RegisterPair]);
		AddInstruction("cpr",   Opcode.CPR,   [Param.Register, Param.Register]);
		AddInstruction("cpp",   Opcode.CPP,   [Param.RegisterPair, Param.RegisterPair]);
		AddInstruction("jmpb",  Opcode.JMPB,  [Param.Addr]);
		AddInstruction("jnzb",  Opcode.JNZB,  [Param.Addr]);
		AddInstruction("chk",   Opcode.CHK,   [Param.Register]);
		AddInstruction("actv",  Opcode.ACTV,  [Param.Register]);
		AddInstruction("addp",  Opcode.ADDP,  [Param.RegisterPair, Param.Register]);
		AddInstruction("subp",  Opcode.SUBP,  [Param.RegisterPair, Param.Register]);
		AddInstruction("diff",  Opcode.DIFF,  [Param.RegisterPair, Param.RegisterPair]);
		AddInstruction("push",  Opcode.PUSH,  [Param.Register]);
		AddInstruction("pop",   Opcode.POP,   [Param.Register]);
		AddInstruction("jz",    Opcode.JZ,    [Param.Addr]);
		AddInstruction("jzb",   Opcode.JZB,   [Param.Addr]);
		AddInstruction("rdbb",  Opcode.RDBB,  [Param.RegisterPair]);
		AddInstruction("rdwb",  Opcode.RDWB,  [Param.RegisterPair]);
		AddInstruction("rdab",  Opcode.RDAB,  [Param.RegisterPair]);
		AddInstruction("wrbb",  Opcode.WRBB,  [Param.RegisterPair, Param.Register]);
		AddInstruction("wrwb",  Opcode.WRWB,  [Param.RegisterPair, Param.Register]);
		AddInstruction("wrab",  Opcode.WRAB,  [Param.RegisterPair, Param.RegisterPair]);
		AddInstruction("lt",    Opcode.LT,    [Param.Register, Param.Register]);
		AddInstruction("gt",    Opcode.GT,    [Param.Register, Param.Register]);
		AddInstruction("cmpp",  Opcode.CMPP,  [Param.RegisterPair, Param.RegisterPair]);
		AddInstruction("gtp",   Opcode.GTP,   [Param.RegisterPair, Param.RegisterPair]);
		AddInstruction("ltp",   Opcode.LTP,   [Param.RegisterPair, Param.RegisterPair]);
		AddInstruction("pusha", Opcode.PUSHA, [Param.RegisterPair]);
		AddInstruction("popa",  Opcode.POPA,  [Param.RegisterPair]);
		AddInstruction("hlt",   Opcode.HLT,  []);

		// special
		AddInstruction("db", Param.Byte);
		AddInstruction("dw", Param.Word);
		AddInstruction("da", Param.Addr);
	}

	void AddInstruction(string name, Opcode opcode, Param[] args) {
		defs ~= InstructionDef(name, cast(ubyte) opcode, args, false);
	}

	void AddInstruction(string name, Param p) {
		defs ~= InstructionDef(name, 0, [p], true);
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

	uint GetParamSize(Param p) {
		switch (p) {
			case Param.Register:
			case Param.RegisterPair:
			case Param.Byte: return 1;
			case Param.Word: return 2;
			case Param.Addr: return 3;
			default: return 0;
		}
	}

	uint GetInstructionSizeSpecial(InstructionNode node) {
		auto inst = GetInstruction(node.name);
		uint intsize = GetParamSize(inst.args[0]);
		uint ret = 0;

		foreach (ref param ; node.params) {
			switch (param.type) {
				case NodeType.Integer: ret += intsize; break;
				case NodeType.String:  ret += (cast(StringNode) param).value.length; break; // awful
				default: break; // should probably add more types here
			}
		}
		return ret;
	}

	uint GetInstructionSize(InstructionNode node) {
		auto inst = GetInstruction(node.name);

		if (inst.special) {
			return GetInstructionSizeSpecial(node);
		}

		uint ret  = 1;

		foreach (ref param ; inst.args) {
			ret += GetParamSize(param);
		}

		return ret;
	}

	ubyte RegisterByte(string reg) {
		switch (reg) {
			case "a": return Register.A;
			case "b": return Register.B;
			case "c": return Register.C;
			case "d": return Register.D;
			case "e": return Register.E;
			case "f": return Register.F;
			case "h": return Register.H;
			case "i": return Register.I;
			default:  assert(0);
		}
	}

	ubyte RegisterPairByte(string reg) {
		switch (reg) {
			case "ab": return RegPair.AB;
			case "cd": return RegPair.CD;
			case "ef": return RegPair.EF;
			case "ds": return RegPair.DS;
			case "sr": return RegPair.SR;
			case "bs": return RegPair.BS;
			case "ip": return RegPair.IP;
			case "sp": return RegPair.SP;
			case "hi": return RegPair.HI;
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

	Node EvalIdentifier(IdentifierNode id) {
		if (id.name in macros) {
			auto value = macros[id.name];
			if (value.type == NodeType.Identifier) {
				return EvalIdentifier(cast(IdentifierNode) value);
			}
			else {
				return value;
			}
		}
		else {
			return id;
		}
	}

	void Assemble(bool printLabels) {
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

					if (printLabels) {
						writefln("%s: %.6X", node.name, labelAddr);
					}

					labels[node.name] = labelAddr;
					break;
				}
				case NodeType.Instruction: {
					auto node = cast(InstructionNode) nodes[i];

					if (!InstructionExists(node.name)) {
						break;
					}

					labelAddr += GetInstructionSize(node);
					break;
				}
				case NodeType.Macro: {
					auto node = cast(MacroNode) nodes[i];

					if (InstructionExists(node.name)) {
						Error("Macros cannot have the same name as an instruction");
						exit(1);
					}

					macros[node.name] = node.value;
					break;
				}
				default: break;
			}
		}

		for (i = 0; i < nodes.length; ++ i) {
			if ((nodes[i].type == NodeType.Label) || (nodes[i].type == NodeType.Macro)) {
				continue;
			}

			ExpectType(NodeType.Instruction);

			auto node = cast(InstructionNode) nodes[i];

			if (!InstructionExists(node.name)) {
				Error(format("No such instruction/keyword '%s'", node.name));
				exit(1);
			}

			auto inst = GetInstruction(node.name);

			if (inst.special) {
				final switch (inst.name) {
					case "db": {
						foreach (ref param ; node.params) {
							if (param.type == NodeType.Identifier) {
								param = EvalIdentifier(cast(IdentifierNode) param);
							}

							switch (param.type) {
								case NodeType.Integer: {
									output ~= cast(ubyte) (cast(IntegerNode) param).value;
									break;
								}
								case NodeType.String: {
									auto str = cast(StringNode) param;

									foreach (ref ch ; str.value) {
										output ~= cast(ubyte) ch;
									}
									break;
								}
								default: {
									Error(format(
										"%s can't be used as parameter in db",
										param.type
									));
									exit(1);
								}
							}
						}
						break;
					}
					case "dw":
					case "da": {
						foreach (ref param ; node.params) {
							switch (param.type) {
								case NodeType.Integer: {
									output ~= cast(ubyte) (cast(IntegerNode) param).value;
									break;
								}
								default: {
									Error(format(
										"%s can't be used as parameter in %s",
										param.type, inst.name
									));
									exit(1);
								}
							}
						}
						break;
					}
				}
			}
			else {
				output ~= inst.opcode;

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

					auto param = node.params[i];
					if (param.type == NodeType.Identifier) {
						param = EvalIdentifier(cast(IdentifierNode) param);
					}

					final switch (arg) {
						case Param.Register: {
							valid = param.type == NodeType.Register;
							break;
						}
						case Param.RegisterPair: {
							valid = param.type == NodeType.RegisterPair;
							break;
						}
						case Param.Byte: {
							valid = param.type == NodeType.Integer;
							break;
						}
						case Param.Word: {
							valid = param.type == NodeType.Integer;
							break;
						}
						case Param.Addr: {
							valid = (
								(param.type == NodeType.Integer) ||
								(param.type == NodeType.Identifier)
							);
							break;
						}
					}

					if (!valid) {
						Error(format(
							"Parameter %d is invalid for instruction %s", i + 1,
							inst.name
						));
						exit(1);
					}
				}

				foreach (i, ref arg ; inst.args) {
					auto param = node.params[i];
					if (param.type == NodeType.Identifier) {
						param = EvalIdentifier(cast(IdentifierNode) param);
					}

					final switch (arg) {
						case Param.Register: {
							auto paramNode = cast(RegisterNode) param;

							output ~= RegisterByte(paramNode.name);
							break;
						}
						case Param.RegisterPair: {
							auto paramNode = cast(RegisterPairNode) param;

							output ~= RegisterPairByte(paramNode.name);
							break;
						}
						case Param.Byte: {
							auto paramNode = cast(IntegerNode) param;

							output ~= cast(ubyte) paramNode.value;
							break;
						}
						case Param.Word: {
							auto paramNode = cast(IntegerNode) param;

							ushort word  = cast(ushort) paramNode.value;
							output      ~= cast(ubyte) (word & 0xFF);
							output      ~= cast(ubyte) ((word & 0xFF00) >> 8);
							break;
						}
						case Param.Addr: {
							uint addr;

							switch (param.type) {
								case NodeType.Integer: {
									auto paramNode = cast(IntegerNode) param;

									addr = paramNode.value;
									break;
								}
								case NodeType.Identifier: {
									auto paramNode = cast(IdentifierNode) param;

									if (paramNode.name !in labels) {
										Error(format(
											"No such label: '%s'", paramNode.name
										));
										return;
									}

									addr = labels[paramNode.name];

									string[] bsInstructions = [
										"jmpb", "jnzb", "jzb", "rdbb", "rdwb", "rdab",
										"wrbb", "wrwb", "wrab"
									];

									/*if ((inst.name == "jmpb") || (inst.name == "jnzb")) {
										addr -= labelBase;
									}*/

									if (bsInstructions.canFind(inst.name)) {
										addr -= labelBase;
									}
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
}

int AssemblerCLI(string[] args) {
	string inFile;
	string outFile = "out.bin";
	bool   debugLexer;
	bool   debugParser;
	bool   printLabels = false;;

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
				case "-l":
				case "--labels": {
					printLabels = true;
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

	lexer.src  = readText(inFile);
	lexer.file = inFile;
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

	if (!parser.success) {
		return 1;
	}

	if (debugParser) {
		parser.PrintNodes();
		return 0;
	}

	assembler.nodes = parser.nodes;
	assembler.Assemble(printLabels);
	std.file.write(outFile, assembler.output);
	return 0;
}
