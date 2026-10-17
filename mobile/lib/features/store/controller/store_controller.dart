import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/store/store_service.dart';
import '../../../services/sync/sync_service.dart';
import '../widgets/cart_sheet.dart';
import '../widgets/receipt_view.dart';
import '../widgets/variant_picker_sheet.dart';

/// Controller managing product catalogue, cart, stock tracking, and checkout.
class StoreController extends GetxController {
  StoreController({
    required this.storeService,
    required this.authService,
    required this.syncService,
  });

  final StoreService storeService;
  final AuthService authService;
  final SyncService syncService;

  final RxBool isLoading = true.obs;
  final RxBool isCheckingOut = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessageKey = AppStrings.errDefault.obs;

  final RxList<Product> products = <Product>[].obs;
  final RxList<CartItem> cartItems = <CartItem>[].obs;

  final TextEditingController discountController = TextEditingController();
  final RxString appliedDiscount = ''.obs;

  // Rule C23 & A7: 3 Radio payment methods (default to tok_success)
  final RxString paymentToken = 'tok_success'.obs;

  final Rx<CheckoutResult?> lastReceipt = Rx<CheckoutResult?>(null);

  // Rule B7: Idempotent order_id reuse
  String? _currentOrderId;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  @override
  void onClose() {
    discountController.dispose();
    super.onClose();
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    hasError.value = false;

    final res = await storeService.getProducts();

    isLoading.value = false;

    if (res.isSuccess) {
      products.assignAll(res.dataOrNull ?? []);
    } else {
      hasError.value = true;
      errorMessageKey.value = res.failureOrNull?.userMessageKey ?? AppStrings.errDefault;
    }
  }

  void openVariantPicker(Product product) {
    AppSheet.show(
      child: VariantPickerSheet(
        product: product,
      ),
    );
  }

  /// Rule G5: Check variant stock before adding to cart
  void addToCart(Product product, ProductVariant variant) {
    addToCartWithQty(product, variant, 1);
  }

  /// Adds a specific quantity of a product variant to cart
  void addToCartWithQty(Product product, ProductVariant variant, int qty) {
    if (variant.stock <= 0) {
      AppSnackbar.error(AppStrings.errOutOfStock);
      return;
    }

    final existingIndex = cartItems.indexWhere(
      (item) => item.product.productId == product.productId && item.variant.variantId == variant.variantId,
    );

    if (existingIndex != -1) {
      final currentQty = cartItems[existingIndex].quantity;
      if (currentQty + qty > variant.stock) {
        AppSnackbar.error(AppStrings.errOutOfStock);
        return;
      }
      cartItems[existingIndex].quantity += qty;
      cartItems.refresh();
    } else {
      if (qty > variant.stock) {
        AppSnackbar.error(AppStrings.errOutOfStock);
        return;
      }
      cartItems.add(CartItem(product: product, variant: variant, quantity: qty));
    }

    _currentOrderId = null; // Cart changed, generate new order_id on checkout
    AppSnackbar.success(AppStrings.storeAddToCart);
  }

  void removeFromCart(CartItem item) {
    cartItems.remove(item);
    _currentOrderId = null;
  }

  /// Rule G5: Check variant stock on quantity increment
  void updateQuantity(CartItem item, int delta) {
    if (delta > 0) {
      if (item.quantity + delta > item.variant.stock) {
        AppSnackbar.error(AppStrings.errOutOfStock);
        return;
      }
    }

    item.quantity += delta;
    _currentOrderId = null;

    if (item.quantity <= 0) {
      cartItems.remove(item);
    } else {
      cartItems.refresh();
    }
  }

  int get subtotalMinor {
    int sub = 0;
    for (final item in cartItems) {
      sub += item.totalMinor;
    }
    return sub;
  }

  int get discountMinor {
    if (appliedDiscount.value == 'WELCOME10') {
      return (subtotalMinor * 10) ~/ 100;
    }
    return 0;
  }

  int get totalMinor => (subtotalMinor - discountMinor).clamp(0, 999999999);

  String get formattedSubtotal => 'PKR ${(subtotalMinor / 100).toStringAsFixed(2)}';
  String get formattedDiscount => 'PKR ${(discountMinor / 100).toStringAsFixed(2)}';
  String get formattedTotal => 'PKR ${(totalMinor / 100).toStringAsFixed(2)}';

  /// Rule C24 & G17: Discount code handling
  void applyDiscountCode() {
    final code = discountController.text.trim().toUpperCase();
    if (code.isEmpty) {
      appliedDiscount.value = '';
      _currentOrderId = null;
      return;
    }

    if (code == 'WELCOME10') {
      appliedDiscount.value = code;
      _currentOrderId = null;
      AppSnackbar.success(AppStrings.successSaved);
    } else {
      appliedDiscount.value = '';
      _currentOrderId = null;
      AppSnackbar.error(AppStrings.errInvalidDiscountCode);
    }
  }

  void clearDiscount() {
    appliedDiscount.value = '';
    discountController.clear();
    _currentOrderId = null;
  }

  void openCart() {
    AppSheet.show(child: const CartSheet());
  }

  Future<void> confirmAndCheckout() async {
    if (cartItems.isEmpty) return;

    // Rule G9 & G12: Double-tap guard
    if (isCheckingOut.value) return;

    // Rule G6: Refuse checkout if offline
    if (!syncService.isOnline) {
      AppSnackbar.error(AppStrings.storeOfflineCheckoutError);
      return;
    }

    final confirmed = await AppDialog.confirm(
      titleKey: AppStrings.storeConfirmPayment,
      bodyKey: AppStrings.storeConfirmDialogBody,
      confirmLabelKey: AppStrings.commonConfirm,
    );

    if (!confirmed) return;

    isCheckingOut.value = true;

    // Rule B7: Idempotency - reuse same order_id on retry if cart hasn't changed
    _currentOrderId ??= 'ord-${DateTime.now().millisecondsSinceEpoch}';

    final userRes = await authService.getCurrentUser();
    final customerId = userRes.dataOrNull?.id ?? 'cust-anon-1';

    final req = CheckoutRequest(
      orderId: _currentOrderId!,
      customerId: customerId,
      items: List.of(cartItems),
      discountCode: appliedDiscount.value.isNotEmpty ? appliedDiscount.value : null,
      paymentToken: paymentToken.value,
    );

    final res = await storeService.checkout(req);

    isCheckingOut.value = false;

    if (res.isSuccess) {
      lastReceipt.value = res.dataOrNull;
      cartItems.clear();
      appliedDiscount.value = '';
      discountController.clear();
      _currentOrderId = null;
      Get.back(); // close cart sheet
      AppSheet.show(child: ReceiptView(receipt: res.dataOrNull!));
      loadProducts(); // refresh stock numbers
    } else {
      final failure = res.failureOrNull;
      final msgKey = failure?.userMessageKey ?? AppStrings.errPaymentDeclined;
      AppSnackbar.error(msgKey);
    }
  }

  /// Rule A3 & C25: Real PDF Download and share
  Future<void> downloadReceipt(CheckoutResult receipt) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${appDir.path}/receipts');
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }
      final filePath = '${receiptsDir.path}/receipt_${receipt.orderId}.pdf';
      final file = File(filePath);

      if (!await file.exists() && receipt.receiptPdfBase64.isNotEmpty) {
        final bytes = base64Decode(receipt.receiptPdfBase64);
        await file.writeAsBytes(bytes, flush: true);
      }

      if (await file.exists()) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/pdf', name: 'receipt_${receipt.orderId}.pdf')],
            subject: 'Trifecta Receipt - ${receipt.orderId}',
          ),
        );
        AppSnackbar.success(AppStrings.storeReceiptDownloaded);
      } else {
        AppSnackbar.error(AppStrings.errDefault);
      }
    } catch (_) {
      AppSnackbar.error(AppStrings.errDefault);
    }
  }
}
