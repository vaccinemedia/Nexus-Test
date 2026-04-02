#!/usr/bin/env python3
"""Extract A-Z glyphs from a font PNG and produce an 8x8 binary font for the ZX Spectrum.

Output: 208 bytes (26 letters * 8 bytes), A first, Z last.
Each letter is 8 rows of 1 byte (MSB = leftmost pixel).

The script detects character bounding boxes per row, maps them to known
letter sequences, scales each glyph to fit 8x8 with aspect-ratio
preservation, thresholds to 1-bit, and packs into Spectrum font format.
"""

import argparse
import sys
from PIL import Image, ImageFilter


def find_regions(img_grey, y_start, y_end, min_gap=5):
    """Find horizontal character regions in a row slice."""
    w = img_grey.width
    col_data = []
    for x in range(w):
        has = any(img_grey.getpixel((x, y)) < 128 for y in range(y_start, y_end))
        col_data.append(has)

    regions = []
    in_char = False
    start = 0
    gap = 0
    for x in range(w):
        if col_data[x]:
            if not in_char:
                if regions and gap < min_gap:
                    regions[-1] = (regions[-1][0], x)
                else:
                    start = x
                in_char = True
            gap = 0
        else:
            gap += 1
            if in_char and gap >= min_gap:
                regions.append((start, x - min_gap))
                in_char = False
    if in_char:
        regions.append((start, w - 1))
    return regions


def find_rows(img_grey, min_gap=5):
    """Find vertical text row bands."""
    h = img_grey.height
    w = img_grey.width
    row_data = []
    for y in range(h):
        has = any(img_grey.getpixel((x, y)) < 128 for x in range(w))
        row_data.append(has)

    rows = []
    in_row = False
    start = 0
    gap = 0
    for y in range(h):
        if row_data[y]:
            if not in_row:
                if rows and gap < min_gap:
                    rows[-1] = (rows[-1][0], y)
                else:
                    start = y
                in_row = True
            gap = 0
        else:
            gap += 1
            if in_row and gap >= min_gap:
                rows.append((start, y - min_gap))
                in_row = False
    if in_row:
        rows.append((start, h - 1))
    return rows


def crop_tight(img_grey, x1, x2, y1, y2, threshold=128):
    """Tightly crop to actual ink pixels within the given bounding box."""
    min_x, max_x, min_y, max_y = x2, x1, y2, y1
    for y in range(y1, y2 + 1):
        for x in range(x1, x2 + 1):
            if img_grey.getpixel((x, y)) < threshold:
                min_x = min(min_x, x)
                max_x = max(max_x, x)
                min_y = min(min_y, y)
                max_y = max(max_y, y)
    if min_x > max_x:
        return img_grey.crop((x1, y1, x2 + 1, y2 + 1))
    return img_grey.crop((min_x, min_y, max_x + 1, max_y + 1))


def glyph_to_8x8(glyph_img, threshold=100):
    """Scale a glyph image to fit within 8x8, threshold, and return 8 bytes."""
    w, h = glyph_img.size
    if w == 0 or h == 0:
        return bytes(8)

    scale = min(8 / w, 8 / h)
    new_w = max(1, int(w * scale))
    new_h = max(1, int(h * scale))

    scaled = glyph_img.resize((new_w, new_h), Image.LANCZOS)

    canvas = Image.new('L', (8, 8), 255)
    ox = (8 - new_w) // 2
    oy = (8 - new_h) // 2
    canvas.paste(scaled, (ox, oy))

    canvas = canvas.filter(ImageFilter.SHARPEN)

    rows = []
    for y in range(8):
        byte_val = 0
        for x in range(8):
            if canvas.getpixel((x, y)) < threshold:
                byte_val |= (0x80 >> x)
        rows.append(byte_val)
    return bytes(rows)


def main():
    parser = argparse.ArgumentParser(description='Convert font PNG to Spectrum 8x8 binary')
    parser.add_argument('input', help='Input PNG file')
    parser.add_argument('-o', '--output', default='custom_font.bin', help='Output binary file')
    parser.add_argument('-t', '--threshold', type=int, default=100,
                        help='Black/white threshold for glyph pixels (0-255)')
    parser.add_argument('--preview', action='store_true',
                        help='Print ASCII preview of extracted glyphs')
    args = parser.parse_args()

    img = Image.open(args.input).convert('L')

    text_rows = find_rows(img)
    if len(text_rows) < 2:
        print(f"Error: expected 2 text rows, found {len(text_rows)}", file=sys.stderr)
        sys.exit(1)

    print(f"Found {len(text_rows)} text rows:")
    for i, (s, e) in enumerate(text_rows):
        print(f"  Row {i}: lines {s}-{e}")

    if len(text_rows) == 4:
        r1_y = (text_rows[0][0], text_rows[1][1])
        r2_y = (text_rows[2][0], text_rows[3][1])
    elif len(text_rows) == 2:
        r1_y = text_rows[0]
        r2_y = text_rows[1]
    else:
        r1_y = text_rows[0]
        r2_y = text_rows[-1]

    row1_regions = find_regions(img, r1_y[0], r1_y[1] + 1)
    row2_regions = find_regions(img, r2_y[0], r2_y[1] + 1)

    print(f"Row 1: {len(row1_regions)} characters, Row 2: {len(row2_regions)} characters")

    # Map to letters: Row 1 = A-P (16 chars), Row 2 = Q-Z (10 chars)
    row1_letters = list("ABCDEFGHIJKLMNOP")
    row2_letters = list("QRSTUVWXYZ")

    if len(row1_regions) != len(row1_letters):
        print(f"Warning: Row 1 expected {len(row1_letters)} chars, found {len(row1_regions)}")
    if len(row2_regions) != len(row2_letters):
        print(f"Warning: Row 2 expected {len(row2_letters)} chars, found {len(row2_regions)}")

    glyphs = {}

    for i, (x1, x2) in enumerate(row1_regions):
        if i < len(row1_letters):
            letter = row1_letters[i]
            crop = crop_tight(img, x1, x2, r1_y[0], r1_y[1])
            glyphs[letter] = glyph_to_8x8(crop, args.threshold)

    for i, (x1, x2) in enumerate(row2_regions):
        if i < len(row2_letters):
            letter = row2_letters[i]
            crop = crop_tight(img, x1, x2, r2_y[0], r2_y[1])
            glyphs[letter] = glyph_to_8x8(crop, args.threshold)

    # Derive O from D if missing
    if 'O' not in glyphs and 'D' in glyphs:
        print("Deriving O from D glyph")
        glyphs['O'] = glyphs['D']

    if args.preview:
        for ch in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
            if ch in glyphs:
                print(f"\n  {ch}:")
                for b in glyphs[ch]:
                    line = ''.join('#' if b & (0x80 >> x) else '.' for x in range(8))
                    print(f"    {line}")

    out = bytearray()
    for ch in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
        if ch in glyphs:
            out.extend(glyphs[ch])
        else:
            print(f"Warning: missing glyph for {ch}, using blank")
            out.extend(bytes(8))

    with open(args.output, 'wb') as f:
        f.write(out)

    print(f"\nWrote {len(out)} bytes to {args.output}")


if __name__ == '__main__':
    main()
