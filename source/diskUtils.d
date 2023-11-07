module yeti16.diskUtils;

import std.conv;
import std.file;
import std.stdio;
import std.string;

int CreateDiskCLI(string[] args) {
	if (args.length != 2) {
		stderr.writeln("Create disk tool requires 2 parameters: file name and size");
		return 1;
	}

	if (!args[1].isNumeric()) {
		stderr.writeln("Size parameter not numeric");
		return 1;
	}

	size_t size = parse!size_t(args[1]);

	if (size > 65535) {
		stderr.writeln("Disk cannot be larger than 65535 sectors");
		return 1;
	}

	ubyte[] disk = new ubyte[](size * 512);
	std.file.write(args[0], disk);
	return 0;
}
