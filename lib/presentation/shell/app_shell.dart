import 'dart:ui' show ImageFilter;

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

/// Top-level layout: navigation rail on desktop / wide screens, glass bottom
/// bar on phones. Hosts the custom window caption on Windows.
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
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: NavigationRail(
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
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surfaceGlass,
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: NavigationBar(
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
          ),
        ),
      ),
    );
  }
}
