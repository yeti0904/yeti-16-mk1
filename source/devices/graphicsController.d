module yeti16.devices.graphicsController;

import bindbc.sdl;
import yeti16.fonts;
import yeti16.types;
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
			case 'F': {
				uint fontAddr = 0x000A45;

				switch (computer.ram[0x000404]) {
					case 0x00: {
						fontAddr = 0x001085;
						break;
					}
					case 0x01: {
						fontAddr = 0x000A45;
						break;
					}
					default: break;
				}
				
				for (uint i = 0; i < cast(uint) font8x8.length; ++ i) {
					computer.ram[fontAddr + i] = font8x8[i];
				}
				break;
			}
			case 'M': {
				switch (computer.ram[0x000404]) {
					case 0x00: {
						computer.display.resolution = Vec2!int(80 * 8, 40 * 8);
						break;
					}
					case 0x01: {
						computer.display.resolution = Vec2!int(40 * 8, 40 * 8);
						break;
					}
					case 0x10: {
						computer.display.resolution = Vec2!int(320, 200);
						break;
					}
					default: break;
				}

				SDL_SetWindowSize(
					computer.display.window, cast(int) (computer.display.resolution.x) * 2,
					cast(int) (computer.display.resolution.y) * 2
				);
				
				SDL_DestroyTexture(computer.display.texture);

				computer.display.pixels  = new uint[](
					computer.display.resolution.x * computer.display.resolution.y
				);
				computer.display.texture = SDL_CreateTexture(
					computer.display.renderer, SDL_PIXELFORMAT_ABGR8888,
					SDL_TEXTUREACCESS_STREAMING, computer.display.resolution.x,
					computer.display.resolution.y
				);
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
