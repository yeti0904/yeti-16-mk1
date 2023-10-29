module yeti16.assembler.error;

import std.stdio;
import core.stdc.stdlib;

struct ErrorInfo {
	string file;
	size_t line;
}

void ErrorBegin(ErrorInfo info) {
	version (Windows) {
		stderr.writef("%s:%d: error: ", info.file, info.line + 1);
	}
	else {
		stderr.writef(
			"\x1b[1m%s:%d: \x1b[31merror:\x1b[0m ", info.file, info.line + 1
		);
	}
}
