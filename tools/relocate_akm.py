#!/usr/bin/env python3
"""Relocate an Arkos Tracker AKM song file to a target address.

AKM files contain absolute 16-bit pointers baked in at export time.
This script detects the original export ORG and patches all internal
pointers to match the actual target address in the game binary.
"""
import sys

def relocate_akm(src_path, dst_path, target_org):
    with open(src_path, 'rb') as f:
        data = bytearray(f.read())

    size = len(data)
    first_ptr = data[0] | (data[1] << 8)
    # The first word is PtInstruments, pointing just past the header.
    # Export ORG is the nearest 256-byte boundary below.
    export_org = first_ptr & 0xFF00
    # Validate: the pointer should be within [export_org, export_org+size)
    if not (export_org <= first_ptr < export_org + size):
        export_org = first_ptr & 0xF000  # fallback: 4K boundary

    delta = target_org - export_org
    if delta == 0:
        with open(dst_path, 'wb') as f:
            f.write(data)
        print(f"AKM already at ${target_org:04X}, no relocation needed.")
        return

    end_range = export_org + size
    patched = 0
    for i in range(size - 1):
        val = data[i] | (data[i + 1] << 8)
        if export_org <= val < end_range:
            new_val = val + delta
            data[i] = new_val & 0xFF
            data[i + 1] = (new_val >> 8) & 0xFF
            patched += 1

    with open(dst_path, 'wb') as f:
        f.write(data)
    print(f"Relocated AKM: ${export_org:04X} -> ${target_org:04X} (delta=${delta:04X}, {patched} pointers patched)")

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <input.akm> <output.akm> <target_hex_address>")
        sys.exit(1)
    target = int(sys.argv[3], 16)
    relocate_akm(sys.argv[1], sys.argv[2], target)
