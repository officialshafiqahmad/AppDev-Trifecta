import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/store/store_service.dart';
import '../controller/store_controller.dart';

/// Redesigned bottom sheet for selecting a variant and quantity before adding to cart.
/// Follows Rules C4, C21, C26 (no "Size:" / "Color:" prefixes, clean card, stock badges).
class VariantPickerSheet extends StatefulWidget {
  const VariantPickerSheet({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  State<VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends State<VariantPickerSheet> {
  late ProductVariant? _selectedVariant;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Default to the first in-stock variant, or the first variant if all sold out
    final inStock = widget.product.variants.where((v) => v.stock > 0).toList();
    if (inStock.isNotEmpty) {
      _selectedVariant = inStock.first;
    } else if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    } else {
      _selectedVariant = null;
    }
  }

  void _incrementQty() {
    if (_selectedVariant == null) return;
    if (_quantity < _selectedVariant!.stock) {
      setState(() => _quantity++);
    }
  }

  void _decrementQty() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;
    final controller = Get.find<StoreController>();

    final isAvailable = _selectedVariant != null && _selectedVariant!.stock > 0;
    final totalPriceMinor = widget.product.basePriceMinor * _quantity;
    final formattedTotal = 'PKR ${(totalPriceMinor / 100).toStringAsFixed(2)}';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: sizes.lg,
        right: sizes.lg,
        top: sizes.sm,
        bottom: sizes.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Product Name and Close Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: textStyles.titleLg.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: sizes.xxs),
                    Text(
                      widget.product.formattedPrice,
                      style: textStyles.headlineMd.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_outlined, size: sizes.iconSm),
                tooltip: AppStrings.commonClose.tr,
                onPressed: () => Get.back(),
              ),
            ],
          ),
          if (widget.product.description.isNotEmpty) ...[
            SizedBox(height: sizes.xs),
            Text(
              widget.product.description,
              style: textStyles.bodySm.copyWith(color: colors.textSecondary),
            ),
          ],
          SizedBox(height: sizes.lg),

          // Variant Selection Section Header
          Text(
            AppStrings.storeSelectVariant.tr,
            style: textStyles.labelLg.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: sizes.sm),

          // Variants in a SINGLE AppCard with dividers (Rule C4 & C26)
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < widget.product.variants.length; i++) ...[
                  () {
                    final variant = widget.product.variants[i];
                    final isSelected = _selectedVariant?.variantId == variant.variantId;
                    final isSoldOut = variant.stock <= 0;

                    return InkWell(
                      onTap: isSoldOut
                          ? null
                          : () {
                              setState(() {
                                _selectedVariant = variant;
                                if (_quantity > variant.stock) {
                                  _quantity = variant.stock.clamp(1, 999);
                                }
                              });
                            },
                      borderRadius: i == 0
                          ? BorderRadius.vertical(top: Radius.circular(sizes.radiusLg))
                          : i == widget.product.variants.length - 1
                              ? BorderRadius.vertical(bottom: Radius.circular(sizes.radiusLg))
                              : BorderRadius.zero,
                      child: Container(
                        color: isSelected ? colors.primaryContainer.withAlpha(50) : null,
                        padding: EdgeInsets.symmetric(
                          horizontal: sizes.cardPadding,
                          vertical: sizes.md,
                        ),
                        child: Row(
                          children: [
                            // Selection Radio Icon
                            Icon(
                              isSoldOut
                                  ? Icons.block_outlined
                                  : isSelected
                                      ? Icons.radio_button_checked_outlined
                                      : Icons.radio_button_unchecked_outlined,
                              size: sizes.iconSm,
                              color: isSoldOut
                                  ? colors.textTertiary
                                  : isSelected
                                      ? colors.primary
                                      : colors.textSecondary,
                            ),
                            SizedBox(width: sizes.md),

                            // Variant description: Size — Color (No "Size:" / "Color:" prefixes per C26)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${variant.size} — ${variant.color}',
                                    style: textStyles.titleMd.copyWith(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSoldOut ? colors.textTertiary : colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: sizes.sm),

                            // Stock Chip
                            if (isSoldOut)
                              const AppStatusChip(
                                label: 'Sold Out',
                                tone: AppStatusTone.danger,
                              )
                            else if (variant.stock == 1)
                              const AppStatusChip(
                                label: 'Only 1 left!',
                                tone: AppStatusTone.warning,
                                showDot: true,
                              )
                            else
                              AppStatusChip(
                                label: '${variant.stock} available',
                                tone: AppStatusTone.neutral,
                              ),
                          ],
                        ),
                      ),
                    );
                  }(),
                  if (i < widget.product.variants.length - 1)
                    Divider(height: 1, thickness: 1, color: colors.border),
                ],
              ],
            ),
          ),
          SizedBox(height: sizes.lg),

          // Quantity Stepper (if selected variant has stock > 1)
          if (isAvailable && _selectedVariant!.stock > 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.storeQuantity.tr,
                  style: textStyles.labelLg.copyWith(color: colors.textSecondary),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(sizes.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_outlined, size: sizes.iconSm),
                        onPressed: _quantity > 1 ? _decrementQty : null,
                        tooltip: 'Decrease quantity',
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: sizes.sm),
                        child: Text(
                          '$_quantity',
                          style: textStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_outlined, size: sizes.iconSm),
                        onPressed: _quantity < _selectedVariant!.stock ? _incrementQty : null,
                        tooltip: 'Increase quantity',
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: sizes.lg),
          ],

          // Primary Add to Cart Button
          PrimaryButton(
            labelKey: isAvailable
                ? AppStrings.storeAddToCart
                : AppStrings.storeSoldOut,
            onPressed: isAvailable
                ? () {
                    controller.addToCartWithQty(
                      widget.product,
                      _selectedVariant!,
                      _quantity,
                    );
                    Get.back();
                  }
                : null,
            icon: isAvailable ? Icons.add_shopping_cart_outlined : Icons.block_outlined,
          ),
          if (isAvailable && _quantity > 1) ...[
            SizedBox(height: sizes.xs),
            Center(
              child: Text(
                'Total: $formattedTotal',
                style: textStyles.caption.copyWith(color: colors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
