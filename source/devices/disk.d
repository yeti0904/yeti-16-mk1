module yeti16.devices.disk;

import std.file;
import std.path;
import std.stdio;
import std.format;
import bindbc.sdl;
import yeti16.deviceBase;

class DiskException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

class Disk : Device {
	ubyte[]  diskData;
	string   diskPath;
	ushort[] input;
	bool     waiting;

	this(string fname) {
		name     = "YETI-16 Disk";
		diskPath = fname;
	
		try {
			diskData = cast(ubyte[]) read(fname);
		}
		catch (Exception) {
			throw new DiskException(format("Failed to read disk '%s'", fname.baseName()));
		}

		if (diskData.length % 512 != 0) {
			throw new DiskException(
				format(
					"Disk '%s' has a size that isn't a multiple of 512",
					fname.baseName()
				)
			);
		}
	}

	override void Out(ushort dataIn) {
		if (waiting) {
			input ~= dataIn;
		
			char op = cast(char) input[0];

			final switch (op) {
				case 'R': {
					if (input.length < 3) {
						return;
					}
					ushort sector = input[1];
					ushort amount = input[2];

					data ~= cast(ushort) 'R';

					for (uint i = 512 * sector; i < 512 * (sector + amount); ++ i) {
						data ~= diskData[i];
					}
					input = [];
					waiting = false;
					break;
				}
				case 'W': { // todo: test writes
					if (input.length < 514) {
						return;
					}

					ushort sector = input[1];

					uint sectorStart = sector * 512;
					uint sectorEnd   = sectorStart + 512;

					for (uint i = 0; i < 512; ++ i) {
						diskData[sectorStart] = cast(ubyte) input[2 + i];
					}

					std.file.write(diskPath, diskData);
					break;
				}
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
				case 'W':
				case 'R': {
					input   ~= dataIn;
					waiting  = true;
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
