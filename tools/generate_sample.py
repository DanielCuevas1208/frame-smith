#!/usr/bin/env python3
"""Generate the Frame Smith sample image.

The output is a deterministic 128 x 128 RGBA PNG. It has a sky gradient,
a sun, a hill, and a checker strip. The checker strip shows edge details.

Usage:
    generate_sample.py data/sample.png
    generate_sample.py data/sample.png --check

The --check mode verifies that an existing file matches the generator
output. It compares decoded pixels, not file bytes. This makes the check
independent of the zlib encoder version.

This script uses only the Python standard library.
"""

import math
import struct
import sys
import zlib

WIDTH = 128
HEIGHT = 128


def clamp(value, low=0, high=255):
    return max(low, min(high, int(round(value))))


def lerp(start, end, t):
    return start + (end - start) * t


def sky_gradient(x, y):
    t = y / (HEIGHT - 1)
    return (
        clamp(lerp(96, 12, t)),
        clamp(lerp(160, 26, t)),
        clamp(lerp(224, 42, t)),
    )


def build_rows():
    rows = []
    for y in range(HEIGHT):
        row = []
        for x in range(WIDTH):
            r, g, b = sky_gradient(x, y)

            dx = x - 34
            dy = y - 26
            dist = math.sqrt(dx * dx + dy * dy)
            if dist <= 16.0:
                r, g, b = 250, 190, 60
            elif dist <= 20.0:
                t = (dist - 16.0) / 4.0
                r = clamp(lerp(250, 96, t))
                g = clamp(lerp(190, 160, t))
                b = clamp(lerp(60, 224, t))

            if y >= 112:
                col = x // 8
                row_in = (y - 112) // 8
                if (col + row_in) % 2 == 0:
                    r, g, b = 28, 28, 32
                else:
                    r, g, b = 214, 214, 208
            else:
                ridge = 84 + 10 * math.sin(x / 9.0)
                if y > ridge and x < 112:
                    depth = (y - ridge) / 30.0
                    r = clamp(lerp(96, 34, depth))
                    g = clamp(lerp(150, 88, depth))
                    b = clamp(lerp(70, 40, depth))

            row.append((r, g, b, 255))
        rows.append(row)
    return rows


def raw_scanlines(rows):
    data = bytearray()
    for row in rows:
        data.append(0)
        for pixel in row:
            data.extend(pixel)
    return bytes(data)


def chunk(tag, payload):
    return (
        struct.pack(">I", len(payload))
        + tag
        + payload
        + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)
    )


def encode_png(rows):
    ihdr = struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 6, 0, 0, 0)
    idat = zlib.compress(raw_scanlines(rows), 9)
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", idat)
        + chunk(b"IEND", b"")
    )


def parse_png(data):
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("bad png signature")
    pos = 8
    width = height = bit_depth = color_type = None
    idat = bytearray()
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        tag = data[pos + 4:pos + 8]
        payload = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if tag == b"IHDR":
            (width, height, bit_depth, color_type, _, _, _) = struct.unpack(">IIBBBBB", payload)
        elif tag == b"IDAT":
            idat.extend(payload)
        elif tag == b"IEND":
            break
    if width is None or bit_depth != 8:
        raise ValueError("unsupported png header")
    channels = 4 if color_type == 6 else 3
    return width, height, channels, zlib.decompress(bytes(idat))


def unfilter(raw, width, height, channels):
    stride = width * channels
    rows = []
    prev = bytearray(stride)
    pos = 0
    for _ in range(height):
        ftype = raw[pos]
        pos += 1
        line = bytearray(raw[pos:pos + stride])
        pos += stride
        if ftype == 1:
            for i in range(channels, stride):
                line[i] = (line[i] + line[i - channels]) & 0xFF
        elif ftype == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif ftype == 3:
            for i in range(stride):
                left = line[i - channels] if i >= channels else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 0xFF
        elif ftype == 4:
            for i in range(stride):
                left = line[i - channels] if i >= channels else 0
                up = prev[i]
                up_left = prev[i - channels] if i >= channels else 0
                p = left + up - up_left
                pa = abs(p - left)
                pb = abs(p - up)
                pc = abs(p - up_left)
                if pa <= pb and pa <= pc:
                    pred = left
                elif pb <= pc:
                    pred = up
                else:
                    pred = up_left
                line[i] = (line[i] + pred) & 0xFF
        elif ftype != 0:
            raise ValueError("unknown filter type %d" % ftype)
        rows.append(bytes(line))
        prev = line
    return rows


def verify(path):
    with open(path, "rb") as fh:
        data = fh.read()
    width, height, channels, raw = parse_png(data)
    if (width, height, channels) != (WIDTH, HEIGHT, 4):
        raise ValueError("dimensions or channel count mismatch")
    rows = unfilter(raw, width, height, channels)
    expected = bytes(c for row in build_rows() for pixel in row for c in pixel)
    got = b"".join(rows)
    if got != expected:
        for i in range(len(got)):
            if got[i] != expected[i]:
                raise ValueError("pixel mismatch at byte %d" % i)
    print("verified %dx%d RGBA png, %d bytes" % (width, height, len(data)))


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: generate_sample.py <output.png> [--check]")
    path = sys.argv[1]
    if len(sys.argv) > 2 and sys.argv[2] == "--check":
        verify(path)
        return 0
    data = encode_png(build_rows())
    with open(path, "wb") as fh:
        fh.write(data)
    print("wrote %s (%d bytes)" % (path, len(data)))
    verify(path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
