import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../application/routing/routing_controller.dart';
import '../../../core/l10n.dart';
import '../../../domain/routing/routing_settings.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/feedback.dart';
import '../../widgets/form_section.dart';
import '../../widgets/page_scaffold.dart';

/// Android per-app routing: pick the mode and the apps it applies to.
class SplitAppsPage extends ConsumerStatefulWidget {
  const SplitAppsPage({super.key});

  @override
  ConsumerState<SplitAppsPage> createState() => _SplitAppsPageState();
}

class _SplitAppsPageState extends ConsumerState<SplitAppsPage> {
  String _query = '';
  bool _showSystem = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final r = ref.watch(routingProvider);
    final ctrl = ref.read(routingProvider.notifier);
    final appsAsync = ref.watch(installedAppsProvider(_showSystem));
    final enabled = r.splitMode != SplitTunnelMode.off;

    return PageScaffold(
      opaque: true,
      title: l10n.splitApps,
      leading: AppIconButton(icon: LucideIcons.arrowLeft, onPressed: () => context.pop()),
      slivers: [
        PagePadding(
          child: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: FormSegmented<SplitTunnelMode>(
                    label: l10n.routingSplit,
                    value: r.splitMode,
                    options: {
                      SplitTunnelMode.off: l10n.splitModeOff,
                      SplitTunnelMode.include: l10n.splitModeInclude,
                      SplitTunnelMode.exclude: l10n.splitModeExclude,
                    },
                    onChanged: (m) => ctrl.update((s) => s.copyWith(splitMode: m)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: l10n.splitSearchHint,
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                  ),
                ),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  title: Text(l10n.splitShowSystem, style: Theme.of(context).textTheme.bodyMedium),
                  value: _showSystem,
                  onChanged: (v) => setState(() => _showSystem = v),
                ),
              ],
            ),
          ),
        ),
        ...switch (appsAsync) {
          AsyncData(:final value) => () {
            final apps =
                value
                    .where(
                      (a) =>
                          _query.isEmpty ||
                          a.label.toLowerCase().contains(_query) ||
                          a.packageName.toLowerCase().contains(_query),
                    )
                    .toList()
                  // Selected apps first, then alphabetical.
                  ..sort((a, b) {
                    final sa = r.splitApps.contains(a.packageName) ? 0 : 1;
                    final sb = r.splitApps.contains(b.packageName) ? 0 : 1;
                    return sa != sb
                        ? sa - sb
                        : a.label.toLowerCase().compareTo(b.label.toLowerCase());
                  });
            if (apps.isEmpty) {
              return [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(icon: LucideIcons.searchX300, title: l10n.splitNoApps),
                ),
              ];
            }
            return [
              PagePadding(
                child: SliverToBoxAdapter(
                  child: AnimatedOpacity(
                    duration: AppDurations.medium,
                    opacity: enabled ? 1 : 0.5,
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Column(
                        children: [
                          for (final a in apps)
                            CheckboxListTile(
                              value: r.splitApps.contains(a.packageName),
                              onChanged: enabled ? (_) => ctrl.toggleApp(a.packageName) : null,
                              secondary: _AppIcon(app: a),
                              title: Text(a.label, style: Theme.of(context).textTheme.titleSmall),
                              subtitle: Text(
                                a.packageName,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              activeColor: c.accentStart,
                              checkboxShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ];
          }(),
          AsyncError() => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(icon: LucideIcons.cloudOff300, title: l10n.unknownError),
            ),
          ],
          _ => [
            const PagePadding(
              child: SliverToBoxAdapter(
                child: AppCard(
                  child: Column(
                    children: [
                      Skeleton(height: 36),
                      SizedBox(height: AppSpacing.md),
                      Skeleton(height: 36),
                      SizedBox(height: AppSpacing.md),
                      Skeleton(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ],
        },
      ],
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.app});

  final InstalledApp app;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icon = app.icon;
    if (icon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Image.memory(Uint8List.fromList(icon), width: 40, height: 40, gaplessPlayback: true),
      );
    }
    // Placeholder: hue derived from the package name keeps colors stable.
    final hue = (app.packageName.hashCode % 360).abs().toDouble();
    final color = HSLColor.fromAHSL(1, hue, 0.55, c.isDark ? 0.6 : 0.5).toColor();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        app.label.characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium!.copyWith(color: color),
      ),
    );
  }
}
