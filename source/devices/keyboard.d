module yeti16.devices.keyboard;

import std.string;
import bindbc.sdl;
import yeti16.deviceBase;

static SDL_Scancode[] CharToKeys(ushort ch) {
	switch (ch) {
		case '0': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_0];
		case '1': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_1];
		case '2': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_2];
		case '3': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_3];
		case '4': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_4];
		case '5': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_5];
		case '6': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_6];
		case '7': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_7];
		case '8': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_8];
		case '9': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_9];
		case 'A': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_A];
		case 'B': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_B];
		case 'C': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_C];
		case 'D': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_D];
		case 'E': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_E];
		case 'F': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_F];
		case 'G': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_G];
		case 'H': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_H];
		case 'I': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_I];
		case 'J': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_J];
		case 'K': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_K];
		case 'L': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_L];
		case 'M': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_M];
		case 'N': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_N];
		case 'O': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_O];
		case 'P': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_P];
		case 'Q': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_Q];
		case 'R': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_R];
		case 'S': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_S];
		case 'T': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_T];
		case 'U': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_U];
		case 'V': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_V];
		case 'W': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_W];
		case 'X': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_X];
		case 'Y': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_Y];
		case 'Z': return [SDL_SCANCODE_LSHIFT, SDL_SCANCODE_Z];
		case 'a': return [SDL_SCANCODE_A];
		case 'b': return [SDL_SCANCODE_B];
		case 'c': return [SDL_SCANCODE_C];
		case 'd': return [SDL_SCANCODE_D];
		case 'e': return [SDL_SCANCODE_E];
		case 'f': return [SDL_SCANCODE_F];
		case 'g': return [SDL_SCANCODE_G];
		case 'h': return [SDL_SCANCODE_H];
		case 'i': return [SDL_SCANCODE_I];
		case 'j': return [SDL_SCANCODE_J];
		case 'k': return [SDL_SCANCODE_K];
		case 'l': return [SDL_SCANCODE_L];
		case 'm': return [SDL_SCANCODE_M];
		case 'n': return [SDL_SCANCODE_N];
		case 'o': return [SDL_SCANCODE_O];
		case 'p': return [SDL_SCANCODE_P];
		case 'q': return [SDL_SCANCODE_Q];
		case 'r': return [SDL_SCANCODE_R];
		case 's': return [SDL_SCANCODE_S];
		case 't': return [SDL_SCANCODE_T];
		case 'u': return [SDL_SCANCODE_U];
		case 'v': return [SDL_SCANCODE_V];
		case 'w': return [SDL_SCANCODE_W];
		case 'y': return [SDL_SCANCODE_Y];
		case 'x': return [SDL_SCANCODE_X];
		case 'z': return [SDL_SCANCODE_Z];
		default:  return [];
	}
}

class Keyboard : Device {
	ushort[] input;
	bool     waiting;

	this() {
		name = "YETI-16 Keyboard";
		SDL_StartTextInput();
	}

	~this() {
		SDL_StopTextInput();
	}

	override void Out(ushort dataIn) {
		if (waiting) {
			char op = cast(char) input[0];

			switch (op) {
				case 'S': {
					auto keys = CharToKeys(dataIn);

					if (keys.length == 0) {
						data ~= 0;
						return;
					}

					auto keystate = SDL_GetKeyboardState(null);

					bool ret = true;
					foreach (ref key ; keys) {
						if (!keystate[key]) {
							ret = false;
							break;
						}
					}

					data    ~= ret? 0xFFFF : 0;
					waiting  = false;
					input    = [];
					break;
				}
				default: assert(0);
			}
		}
		else {
			switch (dataIn) {
				case 'Q': {
					data ~= cast(ushort) 'Q';
					
					foreach (ref ch ; name) {
						data ~= cast(ushort) ch;
					}

					data ~= 0;
					break;
				}
				case 'S': {
					waiting  = true;
					input   ~= cast(ushort) 'S';
					break;
				}
				default: break;
			}
		}
	}

	override void Update() {
		
	}

	ushort KeycodeChar(SDL_Scancode key) {
		switch (key) {
			case SDL_SCANCODE_RETURN:    return 10; 
			case SDL_SCANCODE_BACKSPACE: return 8;  
			case SDL_SCANCODE_ESCAPE:    return 27; 
			case SDL_SCANCODE_LEFT:      return 256; 
			case SDL_SCANCODE_RIGHT:     return 257;
			case SDL_SCANCODE_UP:        return 258;
			case SDL_SCANCODE_DOWN:      return 259;
			default: return 0;
		}
	}

	override void HandleEvent(SDL_Event* e) {
		switch (e.type) {
			case SDL_KEYDOWN: {
				auto key = KeycodeChar(e.key.keysym.scancode);

				if (key != 0) {
					data ~= cast(ushort) 'D';
					data ~= cast(ushort) key;
				}
				break;
			}
			case SDL_TEXTINPUT: {
				string text = cast(string) e.text.text.fromStringz();

				foreach (ref ch ; text) {
					data ~= cast(ushort) 'D';
					data ~= cast(ushort) ch;
				}
				break;
			}
			default: break;
		}
	}
}
