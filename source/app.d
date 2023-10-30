import std.stdio;
import std.string;
import yeti16.computer;
import yeti16.assembler.assembler;

const string appHelp = "
Usage: %s {operation} [args]

Operations:
	asm {file} [-o {file}]
		Compiles an assembly file to machine code
		-o : Sets output binary file

	run {file}
		Runs the given file in the emulator
";

int main(string[] args) {
	assert(args.length > 0);

	if (args.length == 1) {
		writefln(appHelp.strip(), args[0]);
		return 0;
	}

	switch (args[1]) {
		case "asm": {
			return AssemblerCLI(args[2 .. $]);
		}
		case "run": {
			return ComputerCLI(args[2 .. $]);
		}
		case "help":
		case "--help": {
			writefln(appHelp.strip(), args[0]);
			return 0;
		}
		default: {
			stderr.writefln("Unknown operation '%s'", args[1]);
			return 1;
		}
	}
}
