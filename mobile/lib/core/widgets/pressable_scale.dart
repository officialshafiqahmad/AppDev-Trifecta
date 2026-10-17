import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';

/// Interactive scale wrapper for buttons and cards.
/// Provides a subtle tactile press feedback without blocking gestures.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  static const double _targetScale = 0.98;
  static const double _defaultScale = 1.0;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  static const AppSizes _sizes = AppSizes();
  bool _isPressed = false;

  void _onPointerDown(PointerDownEvent _) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
  }

  void _onPointerUp(PointerUpEvent _) {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _onPointerCancel(PointerCancelEvent _) {
    if (_isPressed) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final scale = (widget.enabled && _isPressed && !disableAnimations)
        ? PressableScale._targetScale
        : PressableScale._defaultScale;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        scale: scale,
        duration: disableAnimations ? Duration.zero : _sizes.motionFast,
        curve: _sizes.curveEnter,
        child: widget.child,
      ),
    );
  }
}
