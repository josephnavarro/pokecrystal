#!/usr/bin/env python3
"""
Copy the Tin Tower roof tiles from docs/tin_tower_roof/roof_tiles_template.png
into rows 6-8 of gfx/tilesets/tower.png (the roof's tile slots, VRAM $80-$af).

Usage: python3 tools/apply_roof_tiles.py [template.png]

The template must be 128x24 pixels and use at most 4 shades of gray
(white = palette color 0 ... black = color 3). Run `make` afterwards.
See docs/tin_tower_roof_tiles.md.
"""

import struct
import sys
import zlib

from PIL import Image

TEMPLATE = 'docs/tin_tower_roof/roof_tiles_template.png'
TILESET = 'gfx/tilesets/tower.png'
FIRST_ROW = 6  # tile row in tower.png where the roof slots start
WIDTH, HEIGHT = 128, 24


def read_shades(path, width, height):
	im = Image.open(path).convert('RGBA')
	if im.size != (width, height):
		sys.exit(f'{path}: expected {width}x{height} pixels, got {im.width}x{im.height}')
	px = im.load()
	values = sorted({(r * 299 + g * 587 + b * 114) // 1000
		for r, g, b, a in (px[x, y] for y in range(height) for x in range(width))})
	if len(values) > 4:
		sys.exit(f'{path}: uses {len(values)} shades; each pixel must be one of 4 grays')
	# darkest -> color 3, lightest -> color 0, keeping the 4 standard levels
	def color(r, g, b):
		lum = (r * 299 + g * 587 + b * 114) // 1000
		return 3 - min(3, (lum + 42) // 85)
	return [[color(*im.getpixel((x, y))[:3]) for x in range(width)] for y in range(height)]


def write_2bit_gray(path, rows):
	height, width = len(rows), len(rows[0])
	raw = b''
	for row in rows:
		line = bytearray([0])
		for x in range(0, width, 4):
			byte = 0
			for k in range(4):
				byte = byte << 2 | (3 - row[x + k])
			line.append(byte)
		raw += bytes(line)

	def chunk(kind, data):
		return (struct.pack('>I', len(data)) + kind + data
			+ struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff))

	with open(path, 'wb') as f:
		f.write(b'\x89PNG\r\n\x1a\n'
			+ chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 2, 0, 0, 0, 0))
			+ chunk(b'IDAT', zlib.compress(raw, 9))
			+ chunk(b'IEND', b''))


def main():
	template = sys.argv[1] if len(sys.argv) > 1 else TEMPLATE
	roof = read_shades(template, WIDTH, HEIGHT)
	tileset = Image.open(TILESET).convert('L')
	rows = [[3 - tileset.getpixel((x, y)) // 85 for x in range(tileset.width)]
		for y in range(tileset.height)]
	for y in range(HEIGHT):
		rows[FIRST_ROW * 8 + y] = roof[y]
	write_2bit_gray(TILESET, rows)
	print(f'Copied {template} into {TILESET} (rows {FIRST_ROW}-{FIRST_ROW + 2}). Now run make.')


if __name__ == '__main__':
	main()
