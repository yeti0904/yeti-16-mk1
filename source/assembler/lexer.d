module yeti16.assembler.lexer;

import std.array;
import std.string;
import std.algorithm;
import yeti16.assembler.language;

enum TokenType {
	Null,
	Identifier,
	Register,
	RegisterPair,
	Integer,
	String,
	Label,
	End
}

struct Token {
	TokenType type;
	string    contents;
	string    file;
	size_t    line;
	size_t    col;
}

class Lexer {
	Token[] tokens;
	string  src;
	size_t  i;
	string  reading;
	bool    inString;
	size_t  line;
	size_t  col;
	string  file;

	this() {
		
	}

	void AddToken(TokenType type) {
		tokens  ~= Token(type, reading, file, line, col);
		reading  = "";
	}

	void AddReading() {
		if (Language.registers.canFind(reading)) {
			AddToken(TokenType.Register);
		}
		else if (Language.registerPairs.canFind(reading)) {
			AddToken(TokenType.RegisterPair);
		}
		else if (reading.isNumeric()) {
			AddToken(TokenType.Integer);
		}
		else {
			AddToken(TokenType.Identifier);
		}
	}

	void Lex() {
		reading   = "";
		inString  = false;
		line      = 1;
		col       = 1;
		src      ~= '\n';

		for (i = 0; i < src.length; ++ i) {
			if (src[i] == '\n') {
				++ line;
				col = 1;
			}
			else {
				++ col;
			}
		
			if (inString) {
				switch (src[i]) {
					case '"': {
						inString = false;
						AddToken(TokenType.String);
						break;
					}
					default: {
						reading ~= src[i];
					}
				}
			}
			else {
				switch (src[i]) {
					case ' ':
					case ',':
					case '\t': {
						if (reading.strip() == "") {
							reading = "";
							break;
						}
					
						AddReading();
						break;
					}
					case '\n': {
						if (reading.strip() == "") {
							reading = "";
							break;
						}
						AddReading();
						AddToken(TokenType.End);
						break;
					}
					case '"': {
						inString = true;
						break;
					}
					case ':': {
						AddToken(TokenType.Label);
						break;
					}
					case ';': {
						while ((i < src.length) && (src[i] != '\n')) {
							++ i;

							if (src[i] == '\n') {
								++ line;
								col = 0;
							}
							else {
								++ col;
							}
						}
						break;
					}
					default: {
						reading ~= src[i];
					}
				}
			}
		}
	}
}
