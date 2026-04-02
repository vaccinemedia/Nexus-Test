#!/usr/bin/env python3
"""Convert an image to ZX Spectrum .SCR format (6912 bytes).

Usage: python3 img_to_scr.py input.png output.scr

The Spectrum screen is 256x192 pixels, with colour attributes in 8x8 cells.
Each cell has one INK and one PAPER colour (from 8 colours + bright bit).

The script:
1. Resizes the input image to 256x192
2. For each 8x8 cell, finds the best ink/paper colour pair
3. Dithers the cell to 1-bit using those two colours
4. Outputs a 6912-byte .SCR file (6144 pixel + 768 attribute bytes)

Requires Pillow: pip3 install Pillow
"""

import sys
from pathlib import Path
try:
    from PIL import Image
except ImportError:
    print("Error: Pillow is required. Install with: pip3 install Pillow")
    sys.exit(1)

# ZX Spectrum colour palette (non-bright and bright variants)
SPECTRUM_COLOURS = [
    (0, 0, 0),       # 0 Black
    (0, 0, 205),     # 1 Blue
    (205, 0, 0),     # 2 Red
    (205, 0, 205),   # 3 Magenta
    (0, 205, 0),     # 4 Green
    (0, 205, 205),   # 5 Cyan
    (205, 205, 0),   # 6 Yellow
    (205, 205, 205), # 7 White
]

SPECTRUM_BRIGHT = [
    (0, 0, 0),       # 0 Black
    (0, 0, 255),     # 1 Blue
    (255, 0, 0),     # 2 Red
    (255, 0, 255),   # 3 Magenta
    (0, 255, 0),     # 4 Green
    (0, 255, 255),   # 5 Cyan
    (255, 255, 0),   # 6 Yellow
    (255, 255, 255), # 7 White
]


def colour_distance(c1, c2):
    """Squared Euclidean distance between two RGB tuples."""
    return sum((a - b) ** 2 for a, b in zip(c1, c2))


def nearest_spectrum_colour(rgb):
    """Find the nearest Spectrum colour index and bright flag."""
    best_dist = float('inf')
    best_idx = 0
    best_bright = 0
    for i, c in enumerate(SPECTRUM_COLOURS):
        d = colour_distance(rgb, c)
        if d < best_dist:
            best_dist = d
            best_idx = i
            best_bright = 0
    for i, c in enumerate(SPECTRUM_BRIGHT):
        d = colour_distance(rgb, c)
        if d < best_dist:
            best_dist = d
            best_idx = i
            best_bright = 1
    return best_idx, best_bright


def find_best_cell_colours(cell_pixels):
    """Given an 8x8 block of RGB pixels, find the best ink/paper pair.
    
    Returns (ink, paper, bright) where ink and paper are 0-7 colour indices.
    """
    avg_colours = {}
    for px in cell_pixels:
        idx, bright = nearest_spectrum_colour(px)
        key = (idx, bright)
        if key not in avg_colours:
            avg_colours[key] = 0
        avg_colours[key] += 1

    sorted_colours = sorted(avg_colours.items(), key=lambda x: -x[1])

    if len(sorted_colours) == 1:
        (ink, bright) = sorted_colours[0][0]
        return ink, ink, bright

    (c1, b1) = sorted_colours[0][0]
    (c2, b2) = sorted_colours[1][0]

    bright = b1 or b2
    return c1, c2, bright


def pixel_to_bit(rgb, ink_rgb, paper_rgb):
    """Return 1 if pixel is closer to ink, 0 if closer to paper."""
    d_ink = colour_distance(rgb, ink_rgb)
    d_paper = colour_distance(rgb, paper_rgb)
    return 1 if d_ink <= d_paper else 0


def spectrum_screen_address(col, row):
    """Calculate the byte offset in the 6144-byte pixel area for a pixel row.
    
    col: character column (0-31)
    row: pixel row (0-191)
    """
    third = row // 64
    row_in_third = row % 64
    char_row = row_in_third // 8
    pixel_row = row_in_third % 8
    return (third * 2048) + (pixel_row * 256) + (char_row * 32) + col


def convert(input_path, output_path, mono=False):
    """Convert an image file to .SCR format."""
    img = Image.open(input_path).convert('RGB')

    if mono:
        convert_mono(img, output_path)
        return

    img = img.resize((256, 192), Image.LANCZOS)

    pixels = list(img.getdata())

    def get_pixel(x, y):
        return pixels[y * 256 + x]

    pixel_data = bytearray(6144)
    attr_data = bytearray(768)

    for cell_y in range(24):
        for cell_x in range(32):
            cell_pixels = []
            for py in range(8):
                for px in range(8):
                    x = cell_x * 8 + px
                    y = cell_y * 8 + py
                    cell_pixels.append(get_pixel(x, y))

            ink, paper, bright = find_best_cell_colours(cell_pixels)

            palette = SPECTRUM_BRIGHT if bright else SPECTRUM_COLOURS
            ink_rgb = palette[ink]
            paper_rgb = palette[paper]

            for py in range(8):
                byte_val = 0
                for px in range(8):
                    x = cell_x * 8 + px
                    y = cell_y * 8 + py
                    rgb = get_pixel(x, y)
                    bit = pixel_to_bit(rgb, ink_rgb, paper_rgb)
                    byte_val = (byte_val << 1) | bit

                addr = spectrum_screen_address(cell_x, cell_y * 8 + py)
                pixel_data[addr] = byte_val

            attr_byte = (ink & 7) | ((paper & 7) << 3)
            if bright:
                attr_byte |= 64
            attr_data[cell_y * 32 + cell_x] = attr_byte

    scr_data = bytes(pixel_data) + bytes(attr_data)
    assert len(scr_data) == 6912

    Path(output_path).write_bytes(scr_data)
    print(f"Wrote {output_path} ({len(scr_data)} bytes)")


def convert_mono(img, output_path, threshold=18):
    """Monochrome conversion optimised for wireframe / line-art on black.

    Converts to greyscale, resizes with edge-preserving sharpening,
    applies a low threshold, and writes bright white ink on black paper
    for every cell.
    """
    from PIL import ImageEnhance, ImageFilter

    grey = img.convert('L')

    # Resize to 2x target first to preserve thin lines, then sharpen, then final resize
    grey = grey.resize((512, 384), Image.LANCZOS)
    grey = grey.filter(ImageFilter.SHARPEN)
    grey = grey.filter(ImageFilter.SHARPEN)
    grey = grey.resize((256, 192), Image.LANCZOS)

    # Boost contrast aggressively to bring out faint lines
    grey = ImageEnhance.Contrast(grey).enhance(3.0)
    grey = ImageEnhance.Brightness(grey).enhance(1.5)

    pixels = list(grey.getdata())

    def get_grey(x, y):
        return pixels[y * 256 + x]

    pixel_data = bytearray(6144)
    attr_data = bytearray(768)

    for cell_y in range(24):
        for cell_x in range(32):
            for py in range(8):
                byte_val = 0
                for px in range(8):
                    x = cell_x * 8 + px
                    y = cell_y * 8 + py
                    bit = 1 if get_grey(x, y) > threshold else 0
                    byte_val = (byte_val << 1) | bit

                addr = spectrum_screen_address(cell_x, cell_y * 8 + py)
                pixel_data[addr] = byte_val

            # Bright white ink (7) on black paper (0)
            attr_data[cell_y * 32 + cell_x] = 7 | (0 << 3) | 64

    scr_data = bytes(pixel_data) + bytes(attr_data)
    assert len(scr_data) == 6912

    Path(output_path).write_bytes(scr_data)
    print(f"Wrote {output_path} (mono, threshold={threshold}, {len(scr_data)} bytes)")


if __name__ == '__main__':
    mono = '--mono' in sys.argv
    args = [a for a in sys.argv[1:] if a != '--mono']
    if len(args) != 2:
        print(f"Usage: {sys.argv[0]} [--mono] input.png output.scr")
        sys.exit(1)
    convert(args[0], args[1], mono=mono)
