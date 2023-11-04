module yeti16.devices.keyboard;

import std.string;
import bindbc.sdl;
import yeti16.deviceBase;

class Keyboard : Device {
	this() {
		name = "YETI-16 Keyboard";
		SDL_StartTextInput();
	}

	~this() {
		SDL_StopTextInput();
	}

	override void Out(ushort dataIn) {
		switch (dataIn) {
			case 'Q': {
				foreach (ref ch ; name) {
					data ~= cast(ushort) ch;
				}

				data ~= 0;
				break;
			}
			default: break;
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
			case SDL_KEYUP: {
				auto key = KeycodeChar(e.key.keysym.scancode);

				if (key != 0) {
					data ~= cast(ushort) 'U';
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
