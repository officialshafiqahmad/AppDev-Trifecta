import '../../core/utils/result.dart';

/// Product variant model (size, color, stock/inventory).
class ProductVariant {
  ProductVariant({
    required this.variantId,
    required this.name,
    required this.size,
    required this.color,
    required this.stock,
  });

  final String variantId;
  final String name;
  final String size;
  final String color;
  int stock;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      variantId: (json['variant_id'] ?? json['variantId']) as String,
      name: (json['name']) as String,
      size: (json['size']) as String,
      color: (json['color']) as String,
      stock: (json['inventory'] ?? json['stock']) as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'variant_id': variantId,
        'name': name,
        'size': size,
        'color': color,
        'inventory': stock,
        'stock': stock,
      };
}

/// Store catalogue product.
class Product {
  const Product({
    required this.productId,
    required this.name,
    required this.description,
    required this.basePriceMinor,
    this.currency = 'PKR',
    required this.variants,
  });

  final String productId;
  final String name;
  final String description;
  final int basePriceMinor; // e.g. 450000 = PKR 4500.00
  final String currency;
  final List<ProductVariant> variants;

  /// Returns major units formatted string: 'PKR 4500.00'
  String get formattedPrice {
    final major = (basePriceMinor / 100).toStringAsFixed(2);
    return '$currency $major';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: (json['product_id'] ?? json['productId']) as String,
      name: (json['name']) as String,
      description: (json['description']) as String,
      basePriceMinor: (json['base_price_minor'] ?? json['basePriceMinor']) as int,
      currency: (json['currency']) as String? ?? 'PKR',
      variants: ((json['variants']) as List<dynamic>? ?? [])
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name': name,
        'description': description,
        'base_price_minor': basePriceMinor,
        'currency': currency,
        'variants': variants.map((v) => v.toJson()).toList(),
      };
}

/// Cart line item.
class CartItem {
  CartItem({
    required this.product,
    required this.variant,
    this.quantity = 1,
  });

  final Product product;
  final ProductVariant variant;
  int quantity;

  int get totalMinor => product.basePriceMinor * quantity;

  String get formattedTotal {
    final major = (totalMinor / 100).toStringAsFixed(2);
    return '${product.currency} $major';
  }
}

/// Checkout request payload.
class CheckoutRequest {
  const CheckoutRequest({
    required this.orderId,
    required this.customerId,
    required this.items,
    this.discountCode,
    required this.paymentToken, // tok_cash | tok_success | tok_club_credit
  });

  final String orderId;
  final String customerId;
  final List<CartItem> items;
  final String? discountCode;
  final String paymentToken;

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'customer_id': customerId,
        'discount_code': discountCode,
        'payment_token': paymentToken,
        'items': items
            .map((i) => {
                  'product_id': i.product.productId,
                  'variant_id': i.variant.variantId,
                  'quantity': i.quantity,
                  'unit_price_minor': i.product.basePriceMinor,
                })
            .toList(),
      };
}

/// Checkout result with receipt payload according to API_MODELS.md §2.
class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.tenantId,
    required this.status,
    required this.currency,
    required this.subtotalMinor,
    required this.discountMinor,
    required this.totalMinor,
    required this.paymentAuthId,
    required this.chargeId,
    required this.inventoryUpdated,
    required this.receiptPdfBase64,
    required this.timestamp,
  });

  final String orderId;
  final String tenantId;
  final String status;
  final String currency;
  final int subtotalMinor;
  final int discountMinor;
  final int totalMinor;
  final String paymentAuthId;
  final String chargeId;
  final bool inventoryUpdated;
  final String receiptPdfBase64;
  final DateTime timestamp;

  String get formattedTotal => '$currency ${(totalMinor / 100).toStringAsFixed(2)}';
  String get formattedSubtotal => '$currency ${(subtotalMinor / 100).toStringAsFixed(2)}';
  String get formattedDiscount => '$currency ${(discountMinor / 100).toStringAsFixed(2)}';

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    return CheckoutResult(
      orderId: (json['order_id'] ?? json['orderId']) as String,
      tenantId: (json['tenant_id'] ?? json['tenantId']) as String? ?? 'tenant-alpha',
      status: (json['status']) as String,
      currency: (json['currency']) as String? ?? 'PKR',
      subtotalMinor: (json['subtotal_minor'] ?? json['subtotalMinor']) as int,
      discountMinor: (json['discount_minor'] ?? json['discountMinor']) as int? ?? 0,
      totalMinor: (json['total_minor'] ?? json['totalMinor']) as int,
      paymentAuthId: (json['payment_auth_id'] ?? json['paymentAuthId']) as String? ?? '',
      chargeId: (json['charge_id'] ?? json['chargeId']) as String? ?? 'ch_mock',
      inventoryUpdated: (json['inventory_updated'] ?? json['inventoryUpdated']) as bool? ?? true,
      receiptPdfBase64: (json['receipt_pdf_base64'] ?? json['receiptPdfBase64']) as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'tenant_id': tenantId,
        'status': status,
        'currency': currency,
        'subtotal_minor': subtotalMinor,
        'discount_minor': discountMinor,
        'total_minor': totalMinor,
        'payment_auth_id': paymentAuthId,
        'charge_id': chargeId,
        'inventory_updated': inventoryUpdated,
        'receipt_pdf_base64': receiptPdfBase64,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Store service contract.
abstract class StoreService {
  Future<Result<List<Product>>> getProducts();
  Future<Result<CheckoutResult>> checkout(CheckoutRequest request);
}
