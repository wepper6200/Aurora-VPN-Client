import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../../core/platform.dart';
import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import '../widgets/app_background.dart';
import '../widgets/glass.dart';
import 'app_logo.dart';
import 'window_title_bar.dart';

class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations) label;
}

final _destinations = <_Destination>[
  _Destination(LucideIcons.house, LucideIcons.house600, (l) => l.navHome),
  _Destination(LucideIcons.globe, LucideIcons.globe600, (l) => l.navServers),
  _Destination(LucideIcons.route, LucideIcons.route600, (l) => l.navRouting),
  _Destination(LucideIcons.squareTerminal, LucideIcons.squareTerminal600, (l) => l.navLogs),
  _Destination(LucideIcons.settings, LucideIcons.settings600, (l) => l.navSettings),
];

/// Top-level layout: navigation rail on desktop / wide screens, a bottom bar
/// on phones (Material 3 navigation bar or a floating Liquid Glass capsule).
/// Hosts the custom window caption on Windows.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell, required this.body});

  final StatefulNavigationShell shell;
  final Widget body;

  void _onSelect(int index) {
    // Re-selecting the current tab pops it back to its root.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = ref.watch(appPlatformProvider);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = platform.isDesktop || width >= AppBreakpoints.rail;

    final content = useRail
        ? Row(
            children: [
              _SideNav(currentIndex: shell.currentIndex, onSelect: _onSelect),
              Expanded(child: body),
            ],
          )
        : body;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: platform.isDesktop
            ? Column(
                children: [
                  const WindowTitleBar(),
                  Expanded(child: content),
                ],
              )
            : content,
        bottomNavigationBar: useRail
            ? null
            : context.colors.isGlass
            ? _GlassTabBar(currentIndex: shell.currentIndex, onSelect: _onSelect)
            : _BottomNav(currentIndex: shell.currentIndex, onSelect: _onSelect),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    if (c.isGlass) return _GlassRail(currentIndex: currentIndex, onSelect: onSelect);
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onSelect,
      leading: const Padding(
        padding: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
        child: AppLogo(size: 34),
      ),
      destinations: [
        for (final d in _destinations)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label(l10n)),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          ),
      ],
    );
  }
}

/// Liquid Glass side rail (desktop): a blurred glass column whose selection
/// lens slides between destinations — the vertical twin of [_GlassTabBar].
class _GlassRail extends StatelessWidget {
  const _GlassRail({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const _slot = 72.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final label = Theme.of(context).textTheme.labelSmall!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, 0, AppSpacing.md),
      child: GlassSurface(
        blur: true,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        child: SizedBox(
          width: 84,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.lg),
                child: AppLogo(size: 34),
              ),
              SizedBox(
                height: _slot * _destinations.length,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutBack,
                      top: _slot * currentIndex + 4,
                      left: 6,
                      right: 6,
                      height: _slot - 8,
                      child: GlassSurface(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        shadow: false,
                        tint: c.isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.white.withValues(alpha: 0.85),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Column(
                      children: [
                        for (var i = 0; i < _destinations.length; i++)
                          SizedBox(
                            height: _slot,
                            child: Semantics(
                              selected: i == currentIndex,
                              button: true,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => onSelect(i),
                                  child: _GlassTab(
                                    icon: i == currentIndex
                                        ? _destinations[i].selectedIcon
                                        : _destinations[i].icon,
                                    label: _destinations[i].label(l10n),
                                    selected: i == currentIndex,
                                    style: label,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Liquid Glass tab bar: a floating blurred capsule; the selection lens
/// slides between tabs with a slight springy overshoot.
class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final label = Theme.of(context).textTheme.labelSmall!;
    final count = _destinations.length;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: GlassSurface(
        blur: true,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        tint: c.isDark ? const Color(0x1FFFFFFF) : const Color(0xA6FFFFFF),
        child: SizedBox(
          height: 66,
          child: LayoutBuilder(
            builder: (context, box) {
              final slot = (box.maxWidth - 12) / count;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutBack,
                    left: 6 + slot * currentIndex,
                    top: 6,
                    bottom: 6,
                    width: slot,
                    child: GlassSurface(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      shadow: false,
                      tint: c.isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.white.withValues(alpha: 0.85),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        for (var i = 0; i < count; i++)
                          Expanded(
                            child: Semantics(
                              selected: i == currentIndex,
                              button: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onSelect(i);
                                },
                                child: _GlassTab(
                                  icon: i == currentIndex
                                      ? _destinations[i].selectedIcon
                                      : _destinations[i].icon,
                                  label: _destinations[i].label(l10n),
                                  selected: i == currentIndex,
                                  style: label,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlassTab extends StatelessWidget {
  const _GlassTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.style,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.accentStart : c.textSecondary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: selected ? 1.12 : 1,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(color: color, fontSize: 10.5),
        ),
      ],
    );
  }
}

/// Material 3 navigation bar on a tonal `surfaceContainer`.
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        HapticFeedback.selectionClick();
        onSelect(i);
      },
      destinations: [
        for (final d in _destinations)
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label(l10n),
          ),
      ],
    );
  }
}