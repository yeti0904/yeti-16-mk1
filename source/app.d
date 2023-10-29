import std.stdio;
import yeti16.computer;
import yeti16.assembler.assembler;

int main(string[] args) {
	switch (args[1]) {
		case "asm": {
			return AssemblerCLI(args[2 .. $]);
		}
		case "run": {
			return ComputerCLI(args[2 .. $]);
		}
		default: {
			stderr.writefln("Unknown operation '%s'", args[1]);
			return 1;
		}
	}
}
