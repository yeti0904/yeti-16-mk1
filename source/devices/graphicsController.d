module yeti16.devices.graphicsController;

import bindbc.sdl;
import yeti16.palette;
import yeti16.deviceBase;

class GraphicsController : Device {
	this() {
		name = "YETI-16 Graphics Controller";
	}	

	override void Out(ushort dataIn) {
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
				for (uint i = 0; i < cast(uint) palette.length; ++ i) {
					computer.ram[0x00FE05 + i] = palette[i];
				}
				break;
			}
			default: break;
		}
	}

	override void Update() {
		
	}

	override void HandleEvent(SDL_Event* e) {
		
	}
}
