#!/usr/bin/env python3
"""Convert a WAV file to packed 1-bit PCM for ZX Spectrum beeper playback.

Usage: python3 wav_to_pcm.py input.wav output.bin [sample_rate]

Output is packed 8 samples per byte, MSB first.
Default sample rate is 8000 Hz (~437.5 T-states per sample at 3.5MHz).
"""

import sys
import wave
import struct
from pathlib import Path


def convert(input_path, output_path, target_rate=8000):
    w = wave.open(input_path, 'rb')
    channels = w.getnchannels()
    sampwidth = w.getsampwidth()
    framerate = w.getframerate()
    nframes = w.getnframes()
    raw = w.readframes(nframes)
    w.close()

    # Decode to list of float samples (-1.0 to 1.0), mono
    samples = []
    for i in range(nframes):
        offset = i * channels * sampwidth
        total = 0
        for ch in range(channels):
            ch_offset = offset + ch * sampwidth
            if sampwidth == 1:
                val = struct.unpack_from('B', raw, ch_offset)[0]
                total += (val - 128) / 128.0
            elif sampwidth == 2:
                val = struct.unpack_from('<h', raw, ch_offset)[0]
                total += val / 32768.0
        samples.append(total / channels)

    # Resample to target rate using linear interpolation
    ratio = framerate / target_rate
    target_count = int(len(samples) / ratio)
    resampled = []
    for i in range(target_count):
        src_pos = i * ratio
        idx = int(src_pos)
        frac = src_pos - idx
        if idx + 1 < len(samples):
            val = samples[idx] * (1 - frac) + samples[idx + 1] * frac
        else:
            val = samples[idx] if idx < len(samples) else 0
        resampled.append(val)

    # Normalize to full range
    peak = max(abs(s) for s in resampled) if resampled else 1
    if peak > 0:
        resampled = [s / peak for s in resampled]

    # Convert to 1-bit: positive = 1, negative/zero = 0
    bits = [1 if s > 0 else 0 for s in resampled]

    # Pad to multiple of 8
    while len(bits) % 8 != 0:
        bits.append(0)

    # Pack 8 bits per byte, MSB first
    packed = bytearray()
    for i in range(0, len(bits), 8):
        byte = 0
        for j in range(8):
            byte = (byte << 1) | bits[i + j]
        packed.append(byte)

    Path(output_path).write_bytes(packed)
    duration = len(bits) / target_rate
    print(f"Input: {nframes} frames, {framerate} Hz, {channels}ch, {sampwidth*8}-bit")
    print(f"Output: {len(packed)} bytes, {target_rate} Hz, {len(bits)} samples")
    print(f"Duration: {duration:.2f}s")
    return len(packed)


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} input.wav output.bin [sample_rate]")
        sys.exit(1)
    rate = int(sys.argv[3]) if len(sys.argv) > 3 else 8000
    convert(sys.argv[1], sys.argv[2], rate)
