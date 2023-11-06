module yeti16.util;

import std.algorithm;

T Op(T, char op)(T v1, T v2) {
	mixin("return v1" ~ op ~ "v2;");
}

bool IsHex(string str) {
	if (str.length < 2) {
		return false;
	}

	if (str == "0x") {
		return false;
	}

	if (str[0 .. 2] != "0x") {
		return false;
	}

	foreach (ref ch ; str[2 .. $]) {
		string chars = "0123456789ABCDEFabcdef";

		if (!chars.canFind(ch)) return false;
	}

	return true;
}

bool IsBinary(string str) {
	if (str.length < 2) {
		return false;
	}

	if (str == "0b") {
		return false;
	}

	if (str[0 .. 2] != "0b") {
		return false;
	}

	foreach (ref ch ; str[2 .. $]) {
		if (!"01".canFind(ch)) return false;
	}

	return true;
}
