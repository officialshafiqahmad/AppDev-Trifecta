import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/store/store_service.dart';
import '../widgets/cart_sheet.dart';
import '../widgets/receipt_view.dart';
import '../widgets/variant_picker_sheet.dart';

/// Controller managing product catalogue, cart, discount, and mock checkout.
class StoreController extends GetxController {
  StoreController({
    required this.storeService,
    required this.authService,
  });

  final StoreService storeService;
  final AuthService authService;

  final RxBool isLoading = true.obs;
  final RxBool isCheckingOut = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessageKey = AppStrings.errDefault.obs;

  final RxList<Product> products = <Product>[].obs;
  final RxList<CartItem> cartItems = <CartItem>[].obs;

  final TextEditingController discountController = TextEditingController();
  final RxString appliedDiscount = ''.obs;
  final RxString paymentToken = 'tok_success'.obs;

  final Rx<CheckoutResult?> lastReceipt = Rx<CheckoutResult?>(null);

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
        onSelectVariant: (variant) {
          addToCart(product, variant);
          Get.back();
          AppSnackbar.success(AppStrings.storeAddToCart);
        },
      ),
    );
  }

  void addToCart(Product product, ProductVariant variant) {
    final existingIndex = cartItems.indexWhere(
      (item) => item.product.productId == product.productId && item.variant.variantId == variant.variantId,
    );

    if (existingIndex != -1) {
      cartItems[existingIndex].quantity += 1;
      cartItems.refresh();
    } else {
      cartItems.add(CartItem(product: product, variant: variant, quantity: 1));
    }
  }

  void removeFromCart(CartItem item) {
    cartItems.remove(item);
  }

  void updateQuantity(CartItem item, int delta) {
    item.quantity += delta;
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

  void applyDiscountCode() {
    final code = discountController.text.trim().toUpperCase();
    if (code == 'WELCOME10') {
      appliedDiscount.value = code;
      AppSnackbar.success(AppStrings.successSaved);
    } else {
      appliedDiscount.value = '';
      AppSnackbar.error(AppStrings.errInvalidDiscountCode);
    }
  }

  void openCart() {
    AppSheet.show(child: const CartSheet());
  }

  Future<void> confirmAndCheckout() async {
    if (cartItems.isEmpty) return;

    // Sanctioned confirmation dialog before risky action / payment
    final confirmed = await AppDialog.confirm(
      titleKey: AppStrings.storeConfirmPayment,
      bodyKey: AppStrings.storeConfirmDialogBody,
      confirmLabelKey: AppStrings.commonConfirm,
    );

    if (!confirmed) return;

    isCheckingOut.value = true;

    final orderId = 'ord-${DateTime.now().millisecondsSinceEpoch}';
    final userRes = await authService.getCurrentUser();
    final customerId = userRes.dataOrNull?.id ?? 'cust-anon-1';

    final req = CheckoutRequest(
      orderId: orderId,
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
      Get.back(); // close cart sheet
      AppSheet.show(child: ReceiptView(receipt: res.dataOrNull!));
    } else {
      final failure = res.failureOrNull;
      final msgKey = failure?.userMessageKey ?? AppStrings.errPaymentDeclined;
      AppSnackbar.error(msgKey);
    }
  }

  void downloadReceipt() {
    AppSnackbar.success(AppStrings.storeReceiptDownloaded);
  }
}
