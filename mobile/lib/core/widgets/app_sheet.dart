import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/theme_ext.dart';

/// Sanctioned bottom-sheet wrapper.
/// Features never call showModalBottomSheet or Get.bottomSheet directly.
abstract final class AppSheet {
  static Future<T?> show<T>({
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) async {
    final context = Get.context;
    if (context == null) return null;

    final colors = context.colors;
    final sizes = context.sizes;

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: colors.scrim,
      builder: (bottomSheetContext) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: sizes.contentMaxWidth,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(sizes.radiusSheet),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: sizes.md),
                      // Drag handle indicator
                      Container(
                        width: sizes.huge,
                        height: sizes.xs,
                        decoration: BoxDecoration(
                          color: colors.textTertiary,
                          borderRadius: BorderRadius.circular(sizes.radiusPill),
                        ),
                      ),
                      SizedBox(height: sizes.md),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
