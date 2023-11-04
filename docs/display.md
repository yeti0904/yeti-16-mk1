# Display

## Video modes

### 0x00
80x25 text mode with 9x16 font

Text data is stored in 0x000405 - 0x0013A5

Font data is stored in 0x0013A5 - 0x0025A5

Palette data is stored in 0x0025A5 - 0x25D5

### 0x01
80x80 text mode with 8x8 font

Text data is stored in 0x000405 - 0x001D05

Font data is stored in 0x001D05 - 0x002505

### 0x10
320x200 video mode with 8bpp

Pixel data is stored in 0x000405 - 0x00FE05

Palette data is stored in 0x00FE05 - 0x10105
