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

    return PageScaffold(
      title: l10n.logsTitle,
      bottomSpacing: false,
      actions: [
        AppIconButton(
          icon: logs.paused ? LucideIcons.play : LucideIcons.pause,
          tooltip: logs.paused ? l10n.logsResume : l10n.logsPause,
          color: logs.paused ? c.warning : null,
          onPressed: ctrl.togglePause,
        ),
        AppIconButton(
          icon: LucideIcons.copy,
          tooltip: l10n.logsCopy,
          onPressed: visible.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(
                    ClipboardData(text: visible.map(formatLogLine).join('\n')),
                  );
                  if (context.mounted) showToast(context, l10n.copied);
                },
        ),
        AppIconButton(
          icon: LucideIcons.trash2,
          tooltip: l10n.logsClear,
          onPressed: logs.entries.isEmpty ? null : ctrl.clear,
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
              AppSpacing.lg + bottomInset,
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
