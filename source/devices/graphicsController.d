module yeti16.devices.graphicsController;

import std.stdio;
import core.stdc.stdlib;
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
				uint    paletteAddr;
				ubyte[] palette;

				switch (computer.ram[0x000404]) {
					case 0x00: {
						paletteAddr = 0x001885;
						palette     = cast(ubyte[]) palette16;
						break;
					}
					case 0x01: {
						paletteAddr = 0x001245;
						palette     = cast(ubyte[]) palette16;
						break;
					}
					case 0x10: {
						paletteAddr = 0x00FE05;
						palette     = cast(ubyte[]) palette256;
						break;
					}
					default:   return;
				}
			
				for (uint i = 0; i < cast(uint) palette.length; ++ i) {
					computer.ram[paletteAddr + i] = palette[i];
				}
				break;
			}
			case 'F': {
				uint fontAddr;

				switch (computer.ram[0x000404]) {
					case 0x00: {
						fontAddr = 0x001085;
						break;
					}
					case 0x01: {
						fontAddr = 0x000A45;
						break;
					}
					default: return;
				}
				
				for (uint i = 0; i < cast(uint) font8x8.length; ++ i) {
					computer.ram[fontAddr + i] = font8x8[i];
				}
				break;
			}
			case 'M': {
				ubyte mode = computer.ram[0x000404];
				int   pixelSize;
			
				switch (mode) {
					case 0x00: {
						computer.display.resolution = Vec2!int(80 * 8, 40 * 8);
						pixelSize = 1;
						break;
					}
					case 0x01: {
						computer.display.resolution = Vec2!int(40 * 8, 40 * 8);
						pixelSize = 1;
						break;
					}
					case 0x10: {
						computer.display.resolution = Vec2!int(320, 200);
						pixelSize = 1;
						break;
					}
					case 0x11: {
						computer.display.resolution = Vec2!int(320, 240);
						pixelSize = 1;
						break;
					}
					case 0x12: {
						computer.display.resolution = Vec2!int(320, 200);
						pixelSize = 3;
						break;
					}
					case 0xFF: {
						computer.display.resolution = Vec2!int(1920, 1080);
						pixelSize = 3;
						break;
					}
					default: break;
				}

				SDL_RenderSetLogicalSize(
					computer.display.renderer, computer.display.resolution.x,
					computer.display.resolution.y
				);
				
				SDL_DestroyTexture(computer.display.texture);

				computer.display.pixels  = new uint[](
					computer.display.resolution.x *
					computer.display.resolution.y *
					pixelSize
				);
				computer.display.texture = SDL_CreateTexture(
					computer.display.renderer, SDL_PIXELFORMAT_ABGR8888,
					SDL_TEXTUREACCESS_STREAMING, computer.display.resolution.x,
					computer.display.resolution.y
				);

				if (computer.display.texture is null) {
					stderr.writefln(
						"Failed to create texture: %s", computer.display.GetError()
					);
					exit(1);
				}

				writefln("Initialised graphics mode 0x%.2X", mode);
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
