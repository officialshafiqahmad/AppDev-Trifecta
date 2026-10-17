import 'package:flutter/material.dart';
import 'package:trifecta/core/theme/theme_ext.dart';

class SegmentedItem<T> {
  const SegmentedItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

typedef SegmentItem<T> = SegmentedItem<T>;

/// Shared segmented control with minimum touch target of 48dp.
/// Adheres to corner radius law: uses radiusMd for container and radiusSm for selected item.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    this.items,
    this.segments,
    required this.selectedValue,
    this.onChanged,
    this.onValueChanged,
  }) : assert(items != null || segments != null, 'Either items or segments must be provided'),
       assert(onChanged != null || onValueChanged != null, 'Either onChanged or onValueChanged must be provided');

  final List<SegmentedItem<T>>? items;
  final List<SegmentedItem<T>>? segments;
  final T selectedValue;
  final ValueChanged<T>? onChanged;
  final ValueChanged<T>? onValueChanged;

  List<SegmentedItem<T>> get _effectiveItems => items ?? segments!;
  ValueChanged<T> get _effectiveOnChanged => onChanged ?? onValueChanged!;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final text = context.text;

    return Container(
      constraints: BoxConstraints(minHeight: sizes.minTouchTarget),
      padding: EdgeInsets.all(sizes.xs),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(sizes.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: _effectiveItems.map((item) {
          final isSelected = item.value == selectedValue;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(sizes.radiusSm),
                onTap: () => _effectiveOnChanged(item.value),
                child: AnimatedContainer(
                  duration: sizes.motionFast,
                  curve: sizes.curveDefault,
                  alignment: Alignment.center,
                  constraints: BoxConstraints(minHeight: sizes.minTouchTarget - (sizes.xs * 2)),
                  padding: EdgeInsets.symmetric(
                    horizontal: sizes.sm,
                    vertical: sizes.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(sizes.radiusSm),
                    border: isSelected
                        ? Border.all(color: colors.border.withValues(alpha: 0.6))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item.icon != null) ...[
                        Icon(
                          item.icon,
                          size: sizes.iconSm - 2,
                          color: isSelected ? colors.primary : colors.textSecondary,
                        ),
                        SizedBox(width: sizes.xs),
                      ],
                      Flexible(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: text.labelMd.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? colors.textPrimary : colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
