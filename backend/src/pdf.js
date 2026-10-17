function escapePdf(text) {
  return String(text).replace(/\\/g, "\\\\").replace(/\(/g, "\\(").replace(/\)/g, "\\)");
}

function buildReceiptPdf({ orderId, customerId, totalText, items }) {
  const itemLines = items.map((item) => `${item.variant_id} x${item.quantity}`);
  const lines = [orderId, customerId, ...itemLines, totalText, `Total ${totalText}`];
  const content = [
    "BT",
    "/F1 12 Tf",
    "72 720 Td",
    ...lines.flatMap((line, index) => (index === 0 ? [`(${escapePdf(line)}) Tj`] : ["0 -18 Td", `(${escapePdf(line)}) Tj`])),
    "ET",
  ].join("\n");

  const objects = [];
  const add = (body) => {
    objects.push(body);
    return objects.length;
  };

  const font = add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>");
  const contents = add(`<< /Length ${Buffer.byteLength(content, "utf8")} >>\nstream\n${content}\nendstream`);
  const page = add(
    `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents ${contents} 0 R /Resources << /Font << /F1 ${font} 0 R >> >> >>`
  );
  // object numbers are assigned after we know catalog/pages; rebuild with fixed numbers
  const numbered = [
    "<< /Type /Catalog /Pages 2 0 R >>",
    `<< /Type /Pages /Kids [3 0 R] /Count 1 >>`,
    `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>`,
    `<< /Length ${Buffer.byteLength(content, "utf8")} >>\nstream\n${content}\nendstream`,
    "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
  ];

  let pdf = "%PDF-1.4\n";
  const offsets = [0];
  numbered.forEach((body, index) => {
    offsets.push(Buffer.byteLength(pdf, "utf8"));
    pdf += `${index + 1} 0 obj\n${body}\nendobj\n`;
  });
  const xref = Buffer.byteLength(pdf, "utf8");
  pdf += `xref\n0 ${numbered.length + 1}\n`;
  pdf += "0000000000 65535 f \n";
  for (let i = 1; i <= numbered.length; i += 1) {
    pdf += `${String(offsets[i]).padStart(10, "0")} 00000 n \n`;
  }
  pdf += `trailer\n<< /Size ${numbered.length + 1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF\n`;
  return Buffer.from(pdf, "utf8");
}

module.exports = { buildReceiptPdf };
