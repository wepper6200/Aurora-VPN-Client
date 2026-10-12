import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'app_logo.dart';

/// Frameless-window caption for Windows: drag area + min/max/close buttons.
class WindowTitleBar extends StatefulWidget {
  const WindowTitleBar({super.key, this.onClose});

  static const double height = 40;

  /// Called instead of closing the window (the app minimizes to tray).
  final VoidCallback? onClose;

  @override
  State<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return SizedBox(
      height: WindowTitleBar.height,
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: Row(
                  children: [
                    const AppLogo(size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.appTitle,
                      style: Theme.of(context).textTheme.labelMedium!
                          .copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _CaptionButton(
            icon: LucideIcons.minus,
            tooltip: l10n.windowMinimize,
            onTap: () => windowManager.minimize(),
          ),
          _CaptionButton(
            icon: _maximized ? LucideIcons.copy : LucideIcons.square,
            tooltip: _maximized ? l10n.windowRestore : l10n.windowMaximize,
            onTap: _toggleMaximize,
          ),
          _CaptionButton(
            icon: LucideIcons.x,
            tooltip: l10n.windowClose,
            danger: true,
            onTap: widget.onClose ?? () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = !_hover
        ? Colors.transparent
        : widget.danger
        ? const Color(0xFFE81123)
        : c.textPrimary.withValues(alpha: 0.08);
    final fg = _hover && widget.danger ? Colors.white : c.textSecondary;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            width: 46,
            height: WindowTitleBar.height,
            color: bg,
            child: Icon(widget.icon, size: 14, color: fg),
          ),
        ),
      ),
    );
  }
}
