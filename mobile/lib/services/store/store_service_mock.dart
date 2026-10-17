import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import 'pdf_receipt_builder.dart';
import 'store_service.dart';

/// Mock store service adhering to API_MODELS.md §2.4 and test rules.
class StoreServiceMock implements StoreService {
  // In-memory stock state. Size M starts with 1, Size L starts with 5 (Rule G5).
  final List<Product> _products = [
    Product(
      productId: 'prod-jersey-001',
      name: 'Alpha FC Official Home Jersey',
      description: 'Official 2026 Season competition jersey with moisture-wicking fabric and stitched crest.',
      basePriceMinor: 450000, // PKR 4500.00
      currency: 'PKR',
      variants: [
        ProductVariant(
          variantId: 'var-jersey-001-M',
          name: 'Medium',
          size: 'M',
          color: 'Home Navy',
          stock: 1, // Rule G5: starts with 1 to test low stock
        ),
        ProductVariant(
          variantId: 'var-jersey-001-L',
          name: 'Large',
          size: 'L',
          color: 'Home Navy',
          stock: 5, // Rule G5: starts with 5
        ),
      ],
    ),
    Product(
      productId: 'prod-scarf-001',
      name: 'Supporters Club Knit Scarf',
      description: 'Double-knit acrylic team scarf with fringed edges and club lettering.',
      basePriceMinor: 150000, // PKR 1500.00
      currency: 'PKR',
      variants: [
        ProductVariant(
          variantId: 'var-scarf-001-OS',
          name: 'Standard One Size',
          size: 'One Size',
          color: 'Royal Blue / White',
          stock: 20,
        ),
      ],
    ),
  ];

  @override
  Future<Result<List<Product>>> getProducts() async {
    return Success(List.unmodifiable(_products));
  }

  @override
  Future<Result<CheckoutResult>> checkout(CheckoutRequest request) async {
    // 1. Payment token validation
    if (request.paymentToken == 'tok_declined') {
      return const Failure(
        AppFailure(
          code: 'PAYMENT_DECLINED',
          userMessageKey: AppStrings.errPaymentDeclined,
        ),
      );
    }
    if (request.paymentToken == 'tok_capture_fail') {
      return const Failure(
        AppFailure(
          code: 'PAYMENT_CAPTURE_FAILED',
          userMessageKey: AppStrings.errPaymentCaptureFailed,
        ),
      );
    }

    // 2. Stock inventory check (Rule G5)
    for (final cartItem in request.items) {
      final product = _products.firstWhere(
        (p) => p.productId == cartItem.product.productId,
        orElse: () => cartItem.product,
      );
      final variant = product.variants.firstWhere(
        (v) => v.variantId == cartItem.variant.variantId,
        orElse: () => cartItem.variant,
      );

      if (variant.stock < cartItem.quantity) {
        return const Failure(
          AppFailure(
            code: 'OUT_OF_STOCK',
            userMessageKey: AppStrings.errOutOfStock,
          ),
        );
      }
    }

    // 3. Subtotal calculation
    int subtotal = 0;
    for (final item in request.items) {
      subtotal += item.totalMinor;
    }

    // 4. Discount validation (Rule C24 & G17)
    int discount = 0;
    if (request.discountCode != null && request.discountCode!.trim().isNotEmpty) {
      final code = request.discountCode!.trim().toUpperCase();
      if (code == 'WELCOME10') {
        discount = (subtotal * 10) ~/ 100;
      } else {
        return const Failure(
          AppFailure(
            code: 'INVALID_DISCOUNT_CODE',
            userMessageKey: AppStrings.errInvalidDiscountCode,
          ),
        );
      }
    }

    final total = (subtotal - discount).clamp(0, 999999999);

    // 5. Deduct inventory on success (Rule G5)
    for (final cartItem in request.items) {
      final product = _products.firstWhere(
        (p) => p.productId == cartItem.product.productId,
        orElse: () => cartItem.product,
      );
      final variant = product.variants.firstWhere(
        (v) => v.variantId == cartItem.variant.variantId,
        orElse: () => cartItem.variant,
      );
      variant.stock = (variant.stock - cartItem.quantity).clamp(0, 9999);
    }

    final authId = 'auth-${DateTime.now().millisecondsSinceEpoch}';
    final chargeId = 'ch_${request.paymentToken}_${DateTime.now().millisecondsSinceEpoch}';

    // 6. Build real PDF receipt (Rule A3)
    final paymentMethodLabel = switch (request.paymentToken) {
      'tok_cash' => 'Cash at Ground',
      'tok_club_credit' => 'Club Credit',
      _ => 'Card (Stripe Mock)',
    };

    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final pdfBytes = PdfReceiptBuilder.buildReceiptPdf(
      orderId: request.orderId,
      tenantName: 'Punjab FA / Lahore District League',
      dateFormatted: dateStr,
      items: request.items
          .map((i) => (
                name: i.product.name,
                variant: '${i.variant.size} · ${i.variant.color}',
                qty: i.quantity,
                price: i.formattedTotal,
              ))
          .toList(),
      subtotal: 'PKR ${(subtotal / 100).toStringAsFixed(2)}',
      discount: 'PKR ${(discount / 100).toStringAsFixed(2)}',
      total: 'PKR ${(total / 100).toStringAsFixed(2)}',
      paymentMethod: paymentMethodLabel,
      authId: authId,
    );

    // Save PDF to documents directory
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${appDir.path}/receipts');
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }
      final pdfFile = File('${receiptsDir.path}/receipt_${request.orderId}.pdf');
      await pdfFile.writeAsBytes(pdfBytes, flush: true);
    } catch (_) {}

    final base64Pdf = base64Encode(pdfBytes);

    return Success(
      CheckoutResult(
        orderId: request.orderId,
        tenantId: 'tenant-alpha',
        status: 'paid',
        currency: 'PKR',
        subtotalMinor: subtotal,
        discountMinor: discount,
        totalMinor: total,
        paymentAuthId: authId,
        chargeId: chargeId,
        inventoryUpdated: true,
        receiptPdfBase64: base64Pdf,
        timestamp: DateTime.now(),
      ),
    );
  }
}
