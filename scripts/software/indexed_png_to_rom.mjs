// Convert a non-interlaced 320x240 indexed PNG into $readmemh ROM data.
// Usage: node scripts/software/indexed_png_to_rom.mjs INPUT.png OUTPUT_PREFIX
import fs from 'node:fs';
import { inflateSync } from 'node:zlib';

const [input, prefix] = process.argv.slice(2);
if (!input || !prefix) throw new Error('Expected INPUT.png and OUTPUT_PREFIX');
const png = fs.readFileSync(input);
if (!png.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])))
  throw new Error('Invalid PNG signature');
let header, palette, transparency;
const compressed = [];
for (let offset = 8; offset < png.length;) {
  const length = png.readUInt32BE(offset);
  if (offset + length + 12 > png.length) throw new Error('Truncated PNG');
  const type = png.toString('ascii', offset + 4, offset + 8);
  const data = png.subarray(offset + 8, offset + 8 + length);
  if (type === 'IHDR') header = data;
  if (type === 'PLTE') palette = data;
  if (type === 'tRNS') transparency = data;
  if (type === 'IDAT') compressed.push(data);
  offset += length + 12;
}
if (!header || !palette) throw new Error('Missing PNG header or palette');
const width = header.readUInt32BE(0), height = header.readUInt32BE(4), depth = header[8];
if (width !== 320 || height !== 240 || header[9] !== 3 || header[12] !== 0 ||
    header[10] !== 0 || header[11] !== 0 || ![1, 2, 4, 8].includes(depth))
  throw new Error('Expected non-interlaced indexed 320x240 PNG');
if (palette.length % 3 || palette.length > 48) throw new Error('Palette must have at most 16 entries');
if (transparency && [...transparency].some(alpha => alpha !== 255))
  throw new Error('Flatten transparency before export');
const stride = Math.ceil(width * depth / 8);
const raw = inflateSync(Buffer.concat(compressed));
if (raw.length !== (stride + 1) * height) throw new Error('Invalid PNG scanline size');
const paeth = (a, b, c) => {
  const p = a + b - c, da = Math.abs(p - a), db = Math.abs(p - b), dc = Math.abs(p - c);
  return da <= db && da <= dc ? a : db <= dc ? b : c;
};
let previous = Buffer.alloc(stride);
const indices = [];
for (let y = 0; y < height; y++) {
  const filter = raw[y * (stride + 1)];
  if (filter > 4) throw new Error('Invalid PNG filter');
  const row = Buffer.alloc(stride);
  for (let i = 0; i < stride; i++) {
    const left = i ? row[i - 1] : 0, above = previous[i], corner = i ? previous[i - 1] : 0;
    const prediction = [0, left, above, Math.floor((left + above) / 2), paeth(left, above, corner)][filter];
    row[i] = (raw[y * (stride + 1) + 1 + i] + prediction) & 255;
  }
  for (let x = 0; x < width; x++) {
    const bit = x * depth;
    const index = (row[Math.floor(bit / 8)] >> (8 - depth - bit % 8)) & ((1 << depth) - 1);
    if (index >= palette.length / 3) throw new Error('Pixel references absent palette entry');
    indices.push(index.toString(16));
  }
  previous = row;
}
const colors = Array.from({ length: 16 }, (_, index) => index * 3 < palette.length
  ? palette.subarray(index * 3, index * 3 + 3).toString('hex') : '000000');
fs.writeFileSync(`${prefix}_pixels.hex`, indices.join('\n') + '\n');
fs.writeFileSync(`${prefix}_palette.hex`, colors.join('\n') + '\n');
console.log(`Wrote ${indices.length} 4-bit indices and 16 RGB888 palette entries`);

// HSV hue rotation preserves the original minimum/maximum channel values.
const rotated = [[], [], []];
for (let step = 0; step < 256; step++) {
  for (const hex of colors) {
    const rgb = [0, 2, 4].map(i => parseInt(hex.slice(i, i + 2), 16));
    const max = Math.max(...rgb), min = Math.min(...rgb), c = max - min;
    let result = rgb;
    if (step && c) {
      let h = max === rgb[0] ? (rgb[1] - rgb[2]) / c :
        max === rgb[1] ? 2 + (rgb[2] - rgb[0]) / c : 4 + (rgb[0] - rgb[1]) / c;
      h = (h + 6 + step * 6 / 256) % 6;
      const x = c * (1 - Math.abs(h % 2 - 1));
      result = [[c,x,0], [x,c,0], [0,c,x], [0,x,c], [x,0,c], [c,0,x]][Math.floor(h)]
        .map(v => Math.round(v + min));
    }
    if (Math.max(...result) !== max || Math.min(...result) !== min)
      throw new Error('Hue rotation changed saturation/value');
    result.forEach((v, i) => rotated[i].push(v.toString(16).padStart(2, '0')));
  }
}
['red', 'green', 'blue'].forEach((channel, i) =>
  fs.writeFileSync(`${prefix}_hue_${channel}.hex`, rotated[i].join('\n') + '\n'));
console.log('Wrote 256 rotated palettes, 12 KiB total');
