import 'dart:convert';
import 'dart:typed_data';

/// Generates valid, standards-compliant PDF 1.4 binary documents without third-party native dependencies.
/// The output includes proper PDF headers, objects, xref table, and trailer readable by any standard PDF viewer.
class PdfReceiptBuilder {
  static Uint8List buildReceiptPdf({
    required String orderId,
    required String tenantName,
    required String dateFormatted,
    required List<({String name, String variant, int qty, String price})> items,
    required String subtotal,
    required String discount,
    required String total,
    required String paymentMethod,
    required String authId,
  }) {
    // Build PDF content stream operations
    final contentOps = StringBuffer();
    contentOps.writeln('BT');
    contentOps.writeln('/F1 20 Tf');
    contentOps.writeln('50 740 Td');
    contentOps.writeln('(TRIFECTA - OFFICIAL MATCH RECEIPT) Tj');

    contentOps.writeln('/F1 12 Tf');
    contentOps.writeln('0 -30 Td');
    contentOps.writeln('(Organization: $tenantName) Tj');
    contentOps.writeln('0 -20 Td');
    contentOps.writeln('(Order ID: $orderId) Tj');
    contentOps.writeln('0 -20 Td');
    contentOps.writeln('(Date: $dateFormatted) Tj');
    contentOps.writeln('0 -20 Td');
    contentOps.writeln('(Payment Method: $paymentMethod) Tj');
    contentOps.writeln('0 -20 Td');
    contentOps.writeln('(Auth ID: $authId) Tj');

    contentOps.writeln('0 -30 Td');
    contentOps.writeln('(------------------------------------------------------------) Tj');
    contentOps.writeln('0 -20 Td');
    contentOps.writeln('(ITEMS PURCHASED:) Tj');

    for (final item in items) {
      contentOps.writeln('0 -18 Td');
      final line = '${item.qty}x ${item.name} (${item.variant}) - ${item.price}';
      // Escape parentheses in PDF text
      final escaped = line.replaceAll('(', '\\(').replaceAll(')', '\\)');
      contentOps.writeln('($escaped) Tj');
    }

    contentOps.writeln('0 -24 Td');
    contentOps.writeln('(------------------------------------------------------------) Tj');
    contentOps.writeln('0 -20 Td');
    contentOps.writeln('(Subtotal: $subtotal) Tj');
    if (discount != 'PKR 0.00' && discount != '0') {
      contentOps.writeln('0 -18 Td');
      contentOps.writeln('(Discount: -$discount) Tj');
    }
    contentOps.writeln('/F1 14 Tf');
    contentOps.writeln('0 -22 Td');
    contentOps.writeln('(TOTAL PAID: $total) Tj');
    contentOps.writeln('/F1 10 Tf');
    contentOps.writeln('0 -40 Td');
    contentOps.writeln('(Thank you for supporting your grassroots club!) Tj');
    contentOps.writeln('ET');

    final streamBytes = utf8.encode(contentOps.toString());
    final streamLength = streamBytes.length;

    // Construct valid PDF objects
    final obj1 = '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n';
    final obj2 = '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n';
    final obj3 = '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n';
    final obj4Header = '4 0 obj\n<< /Length $streamLength >>\nstream\n';
    final obj4Footer = '\nendstream\nendobj\n';
    final obj5 = '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n';

    final header = '%PDF-1.4\n%\xE2\xE3\xCF\xD3\n';

    // Calculate byte offsets for xref table
    final headerBytes = utf8.encode(header);
    final obj1Bytes = utf8.encode(obj1);
    final obj2Bytes = utf8.encode(obj2);
    final obj3Bytes = utf8.encode(obj3);
    final obj4HeaderBytes = utf8.encode(obj4Header);
    final obj4FooterBytes = utf8.encode(obj4Footer);
    final obj5Bytes = utf8.encode(obj5);

    final offset1 = headerBytes.length;
    final offset2 = offset1 + obj1Bytes.length;
    final offset3 = offset2 + obj2Bytes.length;
    final offset4 = offset3 + obj3Bytes.length;
    final offset5 = offset4 + obj4HeaderBytes.length + streamBytes.length + obj4FooterBytes.length;

    final xrefOffset = offset5 + obj5Bytes.length;

    String pad10(int n) => n.toString().padLeft(10, '0');

    final xref = StringBuffer();
    xref.writeln('xref');
    xref.writeln('0 6');
    xref.writeln('0000000000 65535 f ');
    xref.writeln('${pad10(offset1)} 00000 n ');
    xref.writeln('${pad10(offset2)} 00000 n ');
    xref.writeln('${pad10(offset3)} 00000 n ');
    xref.writeln('${pad10(offset4)} 00000 n ');
    xref.writeln('${pad10(offset5)} 00000 n ');
    xref.writeln('trailer\n<< /Size 6 /Root 1 0 R >>');
    xref.writeln('startxref');
    xref.writeln('$xrefOffset');
    xref.writeln('%%EOF');

    final xrefBytes = utf8.encode(xref.toString());

    // Assemble final PDF bytes
    final totalBytes = Uint8List(
      headerBytes.length +
          obj1Bytes.length +
          obj2Bytes.length +
          obj3Bytes.length +
          obj4HeaderBytes.length +
          streamBytes.length +
          obj4FooterBytes.length +
          obj5Bytes.length +
          xrefBytes.length,
    );

    int pos = 0;
    void append(List<int> bytes) {
      totalBytes.setRange(pos, pos + bytes.length, bytes);
      pos += bytes.length;
    }

    append(headerBytes);
    append(obj1Bytes);
    append(obj2Bytes);
    append(obj3Bytes);
    append(obj4HeaderBytes);
    append(streamBytes);
    append(obj4FooterBytes);
    append(obj5Bytes);
    append(xrefBytes);

    return totalBytes;
  }
}
