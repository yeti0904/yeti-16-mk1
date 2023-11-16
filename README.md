<center><img src="/screenshots/biglogo.png"></center>

<hr>
![Lines demo](/screenshots/hello_world.png)

16-bit fantasy computer, aiming to be low-level yet easy to use

Unlike the most popular fantasy consoles/computers, YETI-16 uses an emulator instead of
embedding a scripting language

It also includes an assembler for you to write programs in assembly

## Links
- [itch.io page](https://mesyeti.itch.io/yeti-16)

## Specs
- 8 MHz CPU
- 16 MiB RAM
- Up to 256 devices

## Installation
You can either build from source (which is documented below) or download binaries
from the GitHub actions artifacts

Go to the artifacts page by clicking the green tick on a commit, then scroll down and
download a version for your operating system

### Dependencies
- SDL2

### Windows notes
You will have to download an SDL2 dll from the SDL2 releases page, then you will have to
rename it to `sdl2.dll` and put it in the same folder as the yeti-16 executable

## Build
```
dub build
```

## Run
### Compile assembly file
```
./yeti-16 asm (assembly file) -o (output bin)
```

### Run binary file
```
./yeti-16 run (bin file)
```

### See usage
```
./yeti-16
```
