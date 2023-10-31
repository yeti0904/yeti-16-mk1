module yeti16.display;

import std.stdio;
import std.string;
import core.stdc.stdlib;
import bindbc.sdl;
import yeti16.computer;

class Display {
	Computer      computer;
	SDL_Window*   window;
	SDL_Renderer* renderer;
	SDL_Texture*  texture;
	uint[]        pixels;

	this() {
		
	}

	void Init() {
		if (loadSDL() != sdlSupport) {
			stderr.writeln("No SDL support");
			exit(1);
		}

		if (SDL_Init(SDL_INIT_VIDEO) < 0) {
			stderr.writefln("Failed to initialise SDL: %s", GetError());
			exit(1);
		}

		window = SDL_CreateWindow(toStringz("YETI-16"), 0, 0, 640, 400, 0);

		if (window is null) {
			stderr.writefln("Failed to create window: %s", GetError());
			exit(1);
		}

		renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

		if (renderer is null) {
			stderr.writefln("Failed to create renderer: %s", GetError());
			exit(1);
		}

		texture = SDL_CreateTexture(
			renderer, SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STREAMING, 320, 200
		);

		if (texture is null) {
			stderr.writefln("Failed to create texture: %s", GetError());
			exit(1);
		}

		pixels = new uint[](320 * 200);
	}

	string GetError() {
		return cast(string) SDL_GetError().fromStringz();
	}

	uint ColourToInt(ubyte r, ubyte g, ubyte b) {
		return r | (g << 8) | (b << 16) | (255 << 24);
	}

	void Render() {
		// TODO: multiple video modes
		// currently assumes 320x200 8bpp (mode 0x10)

		ubyte[256 * 3] paletteData = computer.ram[0x00FE05 .. 0x10105];

		for (uint i = 0x000405; i < 0x00FE05; ++ i) {
			uint  offset   = i - 0x000405;
			ubyte colour   = computer.ram[i];
			pixels[offset] = ColourToInt(
				paletteData[colour * 3],
				paletteData[(colour * 3) + 1],
				paletteData[(colour * 3) + 2]
			);
		}

		SDL_UpdateTexture(texture, null, pixels.ptr, 320 * 4);
		SDL_RenderCopy(renderer, texture, null, null);
		SDL_RenderPresent(renderer);
	}
}
