module yeti16.deviceBase;

import bindbc.sdl;

class Device {
	string   name;
	ushort[] data; // read with IN

	abstract void Out(ushort dataIn);
	abstract void Update();
	abstract void HandleEvent(SDL_Event* e);
}
