module yeti16.deviceBase;

import bindbc.sdl;
import yeti16.computer;

class Device {
	Computer computer;
	string   name;
	ushort[] data; // read with IN

	abstract void Out(ushort dataIn);
	abstract void Update();
	abstract void HandleEvent(SDL_Event* e);
}
