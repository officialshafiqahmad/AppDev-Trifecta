import '../../core/utils/result.dart';

/// Product variant model (size, color, stock).
class ProductVariant {
  const ProductVariant({
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
  final int stock;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      variantId: json['variantId'] as String,
      name: json['name'] as String,
      size: json['size'] as String,
      color: json['color'] as String,
      stock: json['stock'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'variantId': variantId,
        'name': name,
        'size': size,
        'color': color,
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
      productId: json['productId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      basePriceMinor: json['basePriceMinor'] as int,
      currency: json['currency'] as String? ?? 'PKR',
      variants: (json['variants'] as List<dynamic>? ?? [])
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'description': description,
        'basePriceMinor': basePriceMinor,
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
    required this.paymentToken, // tok_success | tok_declined | tok_capture_fail
  });

  final String orderId;
  final String customerId;
  final List<CartItem> items;
  final String? discountCode;
  final String paymentToken;
}

/// Checkout result with receipt payload.
class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.status,
    required this.currency,
    required this.subtotalMinor,
    required this.discountMinor,
    required this.totalMinor,
    required this.paymentAuthId,
    required this.receiptPdfBase64,
    required this.timestamp,
  });

  final String orderId;
  final String status;
  final String currency;
  final int subtotalMinor;
  final int discountMinor;
  final int totalMinor;
  final String paymentAuthId;
  final String receiptPdfBase64;
  final DateTime timestamp;

  String get formattedTotal => '$currency ${(totalMinor / 100).toStringAsFixed(2)}';
  String get formattedSubtotal => '$currency ${(subtotalMinor / 100).toStringAsFixed(2)}';
  String get formattedDiscount => '$currency ${(discountMinor / 100).toStringAsFixed(2)}';
}

/// Store service contract.
abstract class StoreService {
  Future<Result<List<Product>>> getProducts();
  Future<Result<CheckoutResult>> checkout(CheckoutRequest request);
}
