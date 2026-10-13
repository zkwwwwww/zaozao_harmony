const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

function crc32(buf) {
  let c = ~0;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1));
  }
  return ~c >>> 0;
}

function chunk(type, data) {
  const body = Buffer.concat([Buffer.from(type), data]);
  const out = Buffer.alloc(12 + data.length);
  out.writeUInt32BE(data.length, 0);
  body.copy(out, 4);
  out.writeUInt32BE(crc32(body), 8 + data.length);
  return out;
}

function png(width, height, pixels) {
  const raw = Buffer.alloc((width * 4 + 1) * height);
  for (let y = 0; y < height; y++) {
    const row = y * (width * 4 + 1);
    raw[row] = 0;
    pixels.copy(raw, row + 1, y * width * 4, (y + 1) * width * 4);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw)),
    chunk('IEND', Buffer.alloc(0))
  ]);
}

function canvas(size) {
  return Buffer.alloc(size * size * 4);
}

function set(px, size, x, y, r, g, b, a) {
  if (x < 0 || y < 0 || x >= size || y >= size) return;
  const i = (y * size + x) * 4;
  const alpha = a / 255;
  const oldA = px[i + 3] / 255;
  const outA = alpha + oldA * (1 - alpha);
  if (outA <= 0) return;
  px[i] = Math.round((r * alpha + px[i] * oldA * (1 - alpha)) / outA);
  px[i + 1] = Math.round((g * alpha + px[i + 1] * oldA * (1 - alpha)) / outA);
  px[i + 2] = Math.round((b * alpha + px[i + 2] * oldA * (1 - alpha)) / outA);
  px[i + 3] = Math.round(outA * 255);
}

function fill(px, size, r, g, b) {
  for (let i = 0; i < px.length; i += 4) {
    px[i] = r;
    px[i + 1] = g;
    px[i + 2] = b;
    px[i + 3] = 255;
  }
}

function ellipse(px, size, cx, cy, rx, ry, r, g, b, a) {
  const left = Math.floor(cx - rx);
  const right = Math.ceil(cx + rx);
  const top = Math.floor(cy - ry);
  const bottom = Math.ceil(cy + ry);
  for (let y = top; y <= bottom; y++) {
    for (let x = left; x <= right; x++) {
      const dx = (x + 0.5 - cx) / rx;
      const dy = (y + 0.5 - cy) / ry;
      if (dx * dx + dy * dy <= 1) set(px, size, x, y, r, g, b, a);
    }
  }
}

function roundRect(px, size, x, y, w, h, radius, r, g, b, a) {
  for (let yy = y; yy < y + h; yy++) {
    for (let xx = x; xx < x + w; xx++) {
      let inside = true;
      if (xx < x + radius && yy < y + radius) {
        const dx = xx + 0.5 - (x + radius);
        const dy = yy + 0.5 - (y + radius);
        inside = dx * dx + dy * dy <= radius * radius;
      } else if (xx >= x + w - radius && yy < y + radius) {
        const dx = xx + 0.5 - (x + w - radius);
        const dy = yy + 0.5 - (y + radius);
        inside = dx * dx + dy * dy <= radius * radius;
      } else if (xx < x + radius && yy >= y + h - radius) {
        const dx = xx + 0.5 - (x + radius);
        const dy = yy + 0.5 - (y + h - radius);
        inside = dx * dx + dy * dy <= radius * radius;
      } else if (xx >= x + w - radius && yy >= y + h - radius) {
        const dx = xx + 0.5 - (x + w - radius);
        const dy = yy + 0.5 - (y + h - radius);
        inside = dx * dx + dy * dy <= radius * radius;
      }
      if (inside) set(px, size, xx, yy, r, g, b, a);
    }
  }
}

function drawMark(px, size, ox, oy, scale) {
  const s = (n) => Math.round(n * scale);
  ellipse(px, size, ox, oy + s(18), s(34), s(16), 183, 228, 199, 255);
  ellipse(px, size, ox - s(22), oy + s(8), s(22), s(12), 232, 248, 238, 255);
  ellipse(px, size, ox + s(20), oy + s(4), s(18), s(11), 216, 243, 220, 255);
  roundRect(px, size, ox - s(3), oy + s(8), s(6), s(48), s(3), 246, 241, 231, 255);
  roundRect(px, size, ox - s(28), oy + s(52), s(56), s(36), s(10), 246, 241, 231, 255);
  ellipse(px, size, ox, oy + s(54), s(22), s(7), 196, 165, 116, 255);
}

function write(file, buffer) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, buffer);
}

const root = path.resolve(__dirname, '..');
const size = 256;

const background = canvas(size);
fill(background, size, 46, 125, 91);

const foreground = canvas(size);
drawMark(foreground, size, 128, 78, 1.55);

const start = canvas(size);
fill(start, size, 46, 125, 91);
drawMark(start, size, 128, 78, 1.55);

write(path.join(root, 'AppScope/resources/base/media/background.png'), png(size, size, background));
write(path.join(root, 'AppScope/resources/base/media/foreground.png'), png(size, size, foreground));
write(path.join(root, 'entry/src/main/resources/base/media/startIcon.png'), png(size, size, start));
console.log('icons written');
