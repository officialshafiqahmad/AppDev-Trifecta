const zlib = require('zlib');
const QRCode = require('qrcode');

function escapeXml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function escapePdf(value) {
  return String(value).replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)');
}

function matrixFor(text) {
  return QRCode.create(text, { errorCorrectionLevel: 'M' }).modules;
}

function qrSvg(shortUrl) {
  const modules = matrixFor(shortUrl);
  const cell = 4;
  const dim = modules.size * cell;
  const rects = [];
  for (let y = 0; y < modules.size; y += 1) {
    for (let x = 0; x < modules.size; x += 1) {
      if (!modules.get(x, y)) continue;
      rects.push(`<rect x="${x * cell}" y="${y * cell}" width="${cell}" height="${cell}"/>`);
    }
  }
  return `<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="${dim}" height="${dim}" viewBox="0 0 ${dim} ${dim}"><desc>${escapeXml(shortUrl)}</desc><rect width="100%" height="100%" fill="#ffffff"/><g fill="#000000">${rects.join('')}</g></svg>`;
}

function crc32(buffer) {
  let crc = 0xffffffff;
  for (let i = 0; i < buffer.length; i += 1) {
    crc ^= buffer[i];
    for (let bit = 0; bit < 8; bit += 1) {
      crc = (crc >>> 1) ^ (crc & 1 ? 0xedb88320 : 0);
    }
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function pngChunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length, 0);
  const typeAndData = Buffer.concat([Buffer.from(type), data]);
  const checksum = Buffer.alloc(4);
  checksum.writeUInt32BE(crc32(typeAndData), 0);
  return Buffer.concat([length, typeAndData, checksum]);
}

function qrPng(shortUrl) {
  const modules = matrixFor(shortUrl);
  const scale = 8;
  const dim = modules.size * scale;
  const raw = Buffer.alloc((1 + dim) * dim);
  for (let y = 0; y < dim; y += 1) {
    const row = y * (dim + 1);
    raw[row] = 0;
    const moduleY = Math.floor(y / scale);
    for (let x = 0; x < dim; x += 1) {
      const dark = modules.get(Math.floor(x / scale), moduleY) ? 0 : 255;
      raw[row + 1 + x] = dark;
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(dim, 0);
  ihdr.writeUInt32BE(dim, 4);
  ihdr[8] = 8;
  ihdr[9] = 0;
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    pngChunk('IHDR', ihdr),
    pngChunk('IDAT', zlib.deflateSync(raw)),
    pngChunk('IEND', Buffer.alloc(0)),
  ]);
}

function qrPdf(shortUrl, entityId) {
  const modules = matrixFor(shortUrl);
  const cell = 6;
  const originX = 72;
  const originY = 360;
  const paint = ['0 0 0 rg'];
  for (let y = 0; y < modules.size; y += 1) {
    for (let x = 0; x < modules.size; x += 1) {
      if (!modules.get(x, y)) continue;
      const px = originX + x * cell;
      const py = originY + (modules.size - 1 - y) * cell;
      paint.push(`${px} ${py} ${cell} ${cell} re f`);
    }
  }
  const content = [
    ...paint,
    'BT',
    '/F1 16 Tf',
    '72 740 Td',
    `(${escapePdf(entityId)}) Tj`,
    'ET',
    'BT',
    '/F1 10 Tf',
    '72 718 Td',
    `(${escapePdf(shortUrl)}) Tj`,
    'ET',
  ].join('\n');
  const objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>`,
    `<< /Length ${Buffer.byteLength(content, 'utf8')} >>\nstream\n${content}\nendstream`,
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];
  let pdf = '%PDF-1.4\n';
  const offsets = [0];
  objects.forEach((body, index) => {
    offsets.push(Buffer.byteLength(pdf, 'utf8'));
    pdf += `${index + 1} 0 obj\n${body}\nendobj\n`;
  });
  const xref = Buffer.byteLength(pdf, 'utf8');
  pdf += `xref\n0 ${objects.length + 1}\n`;
  pdf += '0000000000 65535 f \n';
  for (let i = 1; i <= objects.length; i += 1) {
    pdf += `${String(offsets[i]).padStart(10, '0')} 00000 n \n`;
  }
  pdf += `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF\n`;
  return Buffer.from(pdf, 'utf8');
}

module.exports = { qrPdf, qrPng, qrSvg };
