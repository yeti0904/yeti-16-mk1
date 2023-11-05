module yeti16.devices.debugDevice;

import std.stdio;
import bindbc.sdl;
import yeti16.deviceBase;

class Debug : Device {
	bool waiting;

	this() {
		name = "YETI-16 Debug Device";
	}

	override void Out(ushort dataIn) {
		if (waiting) {
			writef("%c", cast(char) dataIn);
			stdout.flush();
			waiting = 0;
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
				case 'P': {
					waiting = true;
					break;
				}
				default: break;
			}
		}
	}

	override void Update() {
		
	}

	override void HandleEvent(SDL_Event* e) {
		
	}
}
