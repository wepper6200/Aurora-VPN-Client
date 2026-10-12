import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Scales its child down slightly while pressed — the base tactile feedback
/// for custom-drawn buttons and cards.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.enabled = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _active => widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _set(bool v) {
    if (_active && v != _pressed) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: _active,
      enabled: _active,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: _active ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: _active ? widget.onTap : null,
          onLongPress: _active ? widget.onLongPress : null,
          child: AnimatedScale(
            scale: _pressed ? widget.scale : 1,
            duration: AppDurations.fast,
            curve: AppCurves.standard,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
