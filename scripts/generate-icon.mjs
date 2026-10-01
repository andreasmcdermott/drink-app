// Dependency-free rasterization of Pour's geometric coupe mark.
import { writeFileSync } from 'node:fs';
import { deflateSync } from 'node:zlib';

const size = 1024;
const pixels = Buffer.alloc((size * 3 + 1) * size);
const background = [38, 74, 58], cream = [246, 243, 235], gold = [205, 167, 102];
function colorAt(x, y) {
  if ((x - 714) ** 2 + (y - 305) ** 2 < 68 ** 2) return gold;
  if (y >= 350 && y <= 490 && Math.abs(x - 512) < 191 * Math.sqrt(Math.max(0, 1 - ((y - 350) / 170) ** 2))) return gold;
  if (y >= 328 && y <= 562 && Math.abs(x - 512) < 232 * Math.sqrt(Math.max(0, 1 - ((y - 328) / 234) ** 2))) return cream;
  if (Math.abs(x - 512) < 16 && y >= 548 && y <= 750) return cream;
  if (((x - 512) / 130) ** 2 + ((y - 755) / 17) ** 2 < 1) return cream;
  return background;
}
for (let y = 0; y < size; y++) {
  const row = y * (size * 3 + 1);
  for (let x = 0; x < size; x++) {
    const samples = [[0.25, 0.25], [0.75, 0.25], [0.25, 0.75], [0.75, 0.75]].map(([dx, dy]) => colorAt(x + dx, y + dy));
    for (let c = 0; c < 3; c++) pixels[row + 1 + x * 3 + c] = Math.round(samples.reduce((sum, sample) => sum + sample[c], 0) / samples.length);
  }
}
function crc32(data) {
  let crc = 0xffffffff;
  for (const byte of data) {
    crc ^= byte;
    for (let i = 0; i < 8; i++) crc = (crc >>> 1) ^ (crc & 1 ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const body = Buffer.concat([Buffer.from(type), data]);
  const length = Buffer.alloc(4); length.writeUInt32BE(data.length);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(body));
  return Buffer.concat([length, body, crc]);
}
const header = Buffer.alloc(13); header.writeUInt32BE(size); header.writeUInt32BE(size, 4); header[8] = 8; header[9] = 2;
writeFileSync(new URL('../Pour/Assets.xcassets/AppIcon.appiconset/AppIcon.png', import.meta.url), Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', header), chunk('IDAT', deflateSync(pixels)), chunk('IEND', Buffer.alloc(0))
]));
