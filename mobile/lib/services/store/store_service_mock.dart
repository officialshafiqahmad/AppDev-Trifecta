import 'dart:convert';
import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import 'store_service.dart';

/// Mock store service adhering to API_MODELS.md §2.4.
class StoreServiceMock implements StoreService {
  static const List<Product> _mockProducts = [
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
          color: 'Navy / Royal Blue',
          stock: 25,
        ),
        ProductVariant(
          variantId: 'var-jersey-001-L',
          name: 'Large',
          size: 'L',
          color: 'Navy / Royal Blue',
          stock: 18,
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
          stock: 50,
        ),
      ],
    ),
  ];

  @override
  Future<Result<List<Product>>> getProducts() async {
    return const Success(_mockProducts);
  }

  @override
  Future<Result<CheckoutResult>> checkout(CheckoutRequest request) async {
    // 1. Check payment gateway token
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

    // 2. Calculate subtotal
    int subtotal = 0;
    for (final item in request.items) {
      subtotal += item.totalMinor;
    }

    // 3. Discount check
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
    final authId = 'auth-${DateTime.now().millisecondsSinceEpoch}';

    // Simulated PDF receipt payload (starts with standard %PDF header)
    final receiptPayload = '%PDF-1.4 Mock Receipt for Order #${request.orderId}\nTotal: PKR ${(total / 100).toStringAsFixed(2)}\nAuthorized: $authId';
    final base64Pdf = base64Encode(utf8.encode(receiptPayload));

    return Success(
      CheckoutResult(
        orderId: request.orderId,
        status: 'paid',
        currency: 'PKR',
        subtotalMinor: subtotal,
        discountMinor: discount,
        totalMinor: total,
        paymentAuthId: authId,
        receiptPdfBase64: base64Pdf,
        timestamp: DateTime.now(),
      ),
    );
  }
}
