import 'package:flutter/material.dart';
import 'package:trifecta/core/theme/theme_ext.dart';

enum AppStatusTone {
  neutral,
  success,
  warning,
  danger,
  info,
}

typedef AppChipTone = AppStatusTone;

/// Status chip component adhering to design token hard law.
/// Only status chips and round icon-button avatars are permitted to use [radiusPill].
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.showDot = false,
    this.hasDot = false,
    this.icon,
  });

  final String label;
  final AppStatusTone tone;
  final bool showDot;
  final bool hasDot;
  final IconData? icon;

  bool get _shouldShowDot => showDot || hasDot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final text = context.text;

    final (Color bg, Color fg) = switch (tone) {
      AppStatusTone.success => (colors.successBg, colors.success),
      AppStatusTone.warning => (colors.warningBg, colors.warning),
      AppStatusTone.danger => (colors.errorBg, colors.error),
      AppStatusTone.info => (colors.primaryContainer, colors.primary),
      AppStatusTone.neutral => (colors.surfaceVariant, colors.textSecondary),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sizes.sm + sizes.xs,
        vertical: sizes.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(sizes.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_shouldShowDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: sizes.xs + 2),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            SizedBox(width: sizes.xs + 2),
          ],
          Text(
            label,
            style: text.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
