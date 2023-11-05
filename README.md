# YETI-16
![Lines demo](/screenshots/lines.png)

16-bit fantasy computer

Warning: Breaking changes will happen during early development, meaning older binaries
may not work properly on newer versions

## Specs
- 8 MHz CPU
- 16 MiB RAM
- Up to 256 devices

## Installation
You can either build from source (which is documented below) or download binaries
from the GitHub actions artifacts

Go to the artifacts page by clicking the green tick on a commit, then scroll down and
download a version for your operating system

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
./yeti016 run (bin file)
```

## TODO
- [ ] more graphics modes
- [ ] text mode
