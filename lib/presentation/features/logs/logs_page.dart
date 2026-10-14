import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../application/logs/logs_controller.dart';
import '../../../core/l10n.dart';
import '../../../domain/logs/log_entry.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/decorations.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/feedback.dart';
import '../../widgets/page_scaffold.dart';

String _two(int n) => n.toString().padLeft(2, '0');
String _time(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

String formatLogLine(LogEntry e) =>
    '${_time(e.time)} ${e.level.name.toUpperCase().padRight(5)} ${e.message}';

class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final logs = ref.watch(logsProvider);
    final ctrl = ref.read(logsProvider.notifier);
    final visible = logs.visible;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final actions = [
      _LogAction(
        logs.paused ? LucideIcons.play : LucideIcons.pause,
        logs.paused ? l10n.logsResume : l10n.logsPause,
        ctrl.togglePause,
        active: logs.paused,
      ),
      _LogAction(
        LucideIcons.copy,
        l10n.logsCopy,
        visible.isEmpty
            ? null
            : () async {
                await Clipboard.setData(
                  ClipboardData(text: visible.map(formatLogLine).join('\n')),
                );
                if (context.mounted) showToast(context, l10n.copied);
              },
      ),
      _LogAction(
        LucideIcons.fileDown,
        l10n.logsExport,
        logs.entries.isEmpty
            ? null
            : () async {
                try {
                  final path = await ctrl.export();
                  if (path != null && context.mounted) {
                    showToast(context, l10n.logsExported(path));
                  }
                } catch (_) {
                  if (context.mounted) showToast(context, l10n.logsExportFailed, error: true);
                }
              },
      ),
      _LogAction(
        LucideIcons.trash2,
        l10n.logsClear,
        logs.entries.isEmpty ? null : ctrl.clear,
      ),
    ];
    // Material 3 puts them on a floating toolbar; glass keeps header bubbles.
    final toolbar = c.isMaterial;

    return PageScaffold(
      title: l10n.logsTitle,
      bottomSpacing: false,
      floatingActionButton: toolbar ? _FloatingToolbar(actions: actions) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      actions: [
        if (!toolbar)
          for (final a in actions)
            AppIconButton(
              icon: a.icon,
              tooltip: a.tooltip,
              color: a.active ? c.warning : null,
              onPressed: a.onPressed,
            ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.page,
                vertical: AppSpacing.sm,
              ),
              children: [
                for (final level in <LogLevel?>[
                  null,
                  LogLevel.debug,
                  LogLevel.info,
                  LogLevel.warn,
                  LogLevel.error,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(level == null ? l10n.logsAll : level.name.toUpperCase()),
                      selected: logs.minLevel == level,
                      onSelected: (_) => ctrl.setMinLevel(level),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              // Keeps the newest lines clear of the floating toolbar.
              AppSpacing.lg + bottomInset + (toolbar ? 72 : 0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: AppDurations.medium,
                  child: logs.paused
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: StatusPill(
                              label: l10n.logsPaused,
                              color: c.warning,
                              icon: LucideIcons.pause,
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                Expanded(
                  child: AppCard(
                    variant: AppCardVariant.elevated,
                    padding: EdgeInsets.zero,
                    child: visible.isEmpty
                        ? EmptyState(
                            icon: LucideIcons.squareTerminal300,
                            title: l10n.logsEmptyTitle,
                            message: l10n.logsEmptyBody,
                          )
                        : _Console(entries: visible),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LogAction {
  const _LogAction(this.icon, this.tooltip, this.onPressed, {this.active = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Toggled on (the stream is paused).
  final bool active;
}

/// Material 3 Expressive floating toolbar; a toggled action sits in a
/// tonal pill.
class _FloatingToolbar extends StatelessWidget {
  const _FloatingToolbar({required this.actions});

  final List<_LogAction> actions;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Material(
      color: s.surfaceContainerHigh,
      shape: const StadiumBorder(),
      elevation: 3,
      shadowColor: Colors.black45,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in actions)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: IconButton(
                  tooltip: a.tooltip,
                  onPressed: a.onPressed,
                  isSelected: a.active,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 48),
                    foregroundColor: s.onSurfaceVariant,
                    backgroundColor: a.active ? s.secondaryContainer : null,
                    shape: const StadiumBorder(),
                  ),
                  icon: Icon(
                    a.icon,
                    size: 22,
                    color: a.active ? s.onSecondaryContainer : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Console extends StatelessWidget {
  const _Console({required this.entries});

  final List<LogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final timeStyle = AppTypography.mono(11.5, color: c.textTertiary);
    final msgStyle = AppTypography.mono(12, color: c.textPrimary);

    Color levelColor(LogLevel l) => switch (l) {
      LogLevel.trace || LogLevel.debug => c.textTertiary,
      LogLevel.info => c.accentStart,
      LogLevel.warn => c.warning,
      LogLevel.error => c.danger,
    };

    // Reversed so the newest line sits at the bottom and the view stays
    // pinned there while new lines arrive.
    return Scrollbar(
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[entries.length - 1 - i];
          final color = levelColor(e.level);
          // Fixed-width time/level column gives wrapped messages a hanging indent.
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${_time(e.time)} ', style: timeStyle),
                      TextSpan(
                        text: e.level.name.toUpperCase().padRight(6),
                        style: AppTypography.mono(11.5, color: color, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    e.message,
                    style: e.level == LogLevel.error
                        ? msgStyle.copyWith(color: c.danger)
                        : msgStyle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
