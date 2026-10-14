import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n.dart';
import '../../../../core/platform.dart';
import '../../../router/app_router.dart';
import '../../../router/transitions.dart';
import 'add_sheet.dart';

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.onSelected, {this.opensPage = false});

  final IconData icon;
  final String label;
  final VoidCallback onSelected;

  /// The page it opens grows out of the item (container transform).
  final bool opensPage;
}

/// Material 3 Expressive FAB menu: the "+" button unfolds into a column of
/// labelled pills and turns into a close button.
class AddFabMenu extends ConsumerStatefulWidget {
  const AddFabMenu({super.key});

  @override
  ConsumerState<AddFabMenu> createState() => _AddFabMenuState();
}

class _AddFabMenuState extends ConsumerState<AddFabMenu> {
  /// The menu draws its own copy of the button (morphing into "close");
  /// the real one hides meanwhile so its square corners don't peek out.
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = Theme.of(context).colorScheme;
    return Opacity(
      opacity: _menuOpen ? 0 : 1,
      child: FloatingActionButton(
        heroTag: null,
        tooltip: l10n.serversAdd,
        backgroundColor: s.primaryContainer,
        foregroundColor: s.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _open(context, ref),
        child: const Icon(LucideIcons.plus600),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    unawaited(HapticFeedback.lightImpact());
    final fab = box.localToGlobal(Offset.zero) & box.size;
    final l10n = context.l10n;
    final items = [
      _MenuItem(
        LucideIcons.link,
        l10n.addFromUrl,
        () => context.go(AppRoutes.newSubscription),
        opensPage: true,
      ),
      _MenuItem(
        LucideIcons.clipboardPaste,
        l10n.addFromClipboard,
        () => importFromClipboard(context, ref),
      ),
      if (ref.read(appPlatformProvider).isMobile)
        _MenuItem(
          LucideIcons.scanQrCode,
          l10n.addScanQr,
          () => context.go(AppRoutes.scanQr),
          opensPage: true,
        ),
      _MenuItem(
        LucideIcons.squarePen,
        l10n.addManual,
        () => context.go(AppRoutes.newServer),
        opensPage: true,
      ),
    ];
    setState(() => _menuOpen = true);
    final route = showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (menuContext, animation, _) =>
          _FabMenuOverlay(fab: fab, items: items, animation: animation),
    );
    await route;
    if (mounted) setState(() => _menuOpen = false);
  }
}

class _FabMenuOverlay extends StatelessWidget {
  const _FabMenuOverlay({required this.fab, required this.items, required this.animation});

  /// Global rect of the FAB the menu unfolds from.
  final Rect fab;
  final List<_MenuItem> items;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final screen = MediaQuery.sizeOf(context);
    final text = Theme.of(context).textTheme.titleSmall!.copyWith(color: s.onPrimaryContainer);
    final n = items.length;

    Widget item(int i) {
      final it = items[i];
      // The item nearest the FAB comes first.
      final order = n - 1 - i;
      final start = order * 0.08, end = 0.6 + order * 0.08;
      // Springy scale may overshoot 1; opacity must not.
      final pop = CurvedAnimation(
        parent: animation,
        curve: Interval(start, end, curve: Curves.easeOutBack),
        reverseCurve: const Interval(0, 0.6, curve: Curves.easeIn),
      );
      final fade = CurvedAnimation(
        parent: animation,
        curve: Interval(start, end, curve: Curves.easeOut),
        reverseCurve: const Interval(0, 0.6, curve: Curves.easeIn),
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            alignment: Alignment.centerRight,
            scale: pop.drive(Tween(begin: 0.6, end: 1.0)),
            child: Builder(
              builder: (itemContext) => Material(
                color: s.primaryContainer,
                shape: const StadiumBorder(),
                elevation: 2,
                shadowColor: Colors.black38,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (it.opensPage) TransitionOrigin.captureFrom(itemContext);
                    Navigator.of(context).pop();
                    it.onSelected();
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 24, 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(it.icon, size: 22, color: s.onPrimaryContainer),
                        const SizedBox(width: 12),
                        Text(it.label, style: text),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          right: screen.width - fab.right,
          bottom: screen.height - fab.bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < n; i++) item(i),
              const SizedBox(height: 4),
              // The FAB itself, morphed into a round close button.
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final t = Curves.easeOutBack.transform(animation.value.clamp(0.0, 1.0));
                  return SizedBox(
                    width: fab.width,
                    height: fab.height,
                    child: Material(
                      color: Color.lerp(s.primaryContainer, s.primary, animation.value),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16 + (fab.width / 2 - 16) * t),
                      ),
                      elevation: 3,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: Transform.rotate(
                          angle: t * math.pi / 4,
                          child: Icon(
                            LucideIcons.plus600,
                            color: Color.lerp(s.onPrimaryContainer, s.onPrimary, animation.value),
                            semanticLabel: MaterialLocalizations.of(context).closeButtonLabel,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
