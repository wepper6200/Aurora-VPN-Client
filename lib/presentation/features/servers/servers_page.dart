import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../application/servers/servers_controller.dart';
import '../../../core/l10n.dart';
import '../../../domain/servers/server_profile.dart';
import '../../../domain/subscriptions/subscription.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/decorations.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/feedback.dart';
import '../../widgets/page_scaffold.dart';
import 'widgets/add_sheet.dart';
import 'widgets/server_widgets.dart';
import 'widgets/subscription_header.dart';

/// One row of the flattened list: a group header or a server.
sealed class _Row {
  const _Row();
}

class _SubRow extends _Row {
  const _SubRow(this.group);
  final ServerGroup group;
}

class _ManualHeaderRow extends _Row {
  const _ManualHeaderRow();
}

class _ServerRow extends _Row {
  const _ServerRow(this.server, this.index);
  final ServerProfile server;
  final int index;
}

class _EmptyGroupRow extends _Row {
  const _EmptyGroupRow();
}

class ServersPage extends ConsumerStatefulWidget {
  const ServersPage({super.key});

  @override
  ConsumerState<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends ConsumerState<ServersPage> {
  final _collapsed = <String>{};
  final _updating = <String>{};
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_Row> _flatten(List<ServerGroup> groups) {
    final rows = <_Row>[];
    var i = 0;
    for (final g in groups) {
      final sub = g.subscription;
      if (sub != null) {
        rows.add(_SubRow(g));
        if (_collapsed.contains(sub.id)) continue;
        if (g.servers.isEmpty) rows.add(const _EmptyGroupRow());
      } else {
        rows.add(const _ManualHeaderRow());
      }
      for (final s in g.servers) {
        rows.add(_ServerRow(s, i++));
      }
    }
    return rows;
  }

  Future<void> _onSubscriptionMenu(Subscription sub, SubscriptionMenuAction a) async {
    final l10n = context.l10n;
    final actions = ref.read(serverActionsProvider);
    switch (a) {
      case SubscriptionMenuAction.update:
        setState(() => _updating.add(sub.id));
        try {
          await actions.refreshSubscription(sub);
        } finally {
          if (mounted) setState(() => _updating.remove(sub.id));
        }
      case SubscriptionMenuAction.edit:
        context.go('${AppRoutes.servers}/subscription/${sub.id}');
      case SubscriptionMenuAction.copyLink:
        await Clipboard.setData(ClipboardData(text: sub.url));
        if (mounted) showToast(context, l10n.copied);
      case SubscriptionMenuAction.delete:
        final ok = await confirmDelete(
          context,
          title: l10n.deleteConfirmTitle(sub.name),
          body: l10n.deleteSubscriptionBody,
        );
        if (ok) await actions.deleteSubscription(sub.id);
    }
  }

  Future<void> _onServerMenu(ServerProfile s, ServerMenuAction a) async {
    final l10n = context.l10n;
    switch (a) {
      case ServerMenuAction.edit:
        context.go('${AppRoutes.servers}/server/${s.id}');
      case ServerMenuAction.copyLink:
        // Stage 3 serializes the profile back to its share link.
        await Clipboard.setData(ClipboardData(text: '${s.protocol.name}://${s.host}:${s.port}'));
        if (mounted) showToast(context, l10n.copied);
      case ServerMenuAction.delete:
        final ok = await confirmDelete(
          context,
          title: l10n.deleteConfirmTitle(s.name),
          body: l10n.deleteConfirmBody,
        );
        if (ok) await ref.read(serverActionsProvider).delete(s.id);
    }
  }

  void _testAll() {
    final servers = ref.read(serversProvider).value ?? const [];
    ref.read(latencyProvider.notifier).test(servers.map((s) => s.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groupsAsync = ref.watch(serverGroupsProvider);
    final query = ref.watch(serverQueryProvider);
    final latency = ref.watch(latencyProvider);
    final testing = latency.values.any((r) => r.state == LatencyState.testing);
    final selectedId = ref.watch(selectedServerProvider)?.id;
    final allServers = ref.watch(serversProvider).value ?? const [];
    final allSubs = ref.watch(subscriptionsProvider).value ?? const [];
    final isEmpty = groupsAsync.hasValue && allServers.isEmpty && allSubs.isEmpty;

    return PageScaffold(
      title: l10n.serversTitle,
      actions: [
        AppIconButton(
          icon: LucideIcons.zap,
          tooltip: l10n.serversTestLatency,
          onPressed: testing || allServers.isEmpty ? null : _testAll,
          color: testing ? context.colors.accentStart : null,
        ),
        AppIconButton(
          icon: LucideIcons.plus,
          tooltip: l10n.serversAdd,
          onPressed: () => showAddSheet(context, ref),
        ),
      ],
      slivers: [
        if (!isEmpty)
          PagePadding(
            child: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _search,
                    onChanged: ref.read(serverQueryProvider.notifier).setSearch,
                    decoration: InputDecoration(
                      hintText: l10n.serversSearchHint,
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      suffixIcon: query.search.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(LucideIcons.x, size: 18),
                              onPressed: () {
                                _search.clear();
                                ref.read(serverQueryProvider.notifier).setSearch('');
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FilterBar(query: query),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ...switch (groupsAsync) {
          AsyncData(:final value) when isEmpty || value.isEmpty => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: isEmpty
                  ? EmptyState(
                      icon: LucideIcons.globe300,
                      title: l10n.serversEmptyTitle,
                      message: l10n.serversEmptyBody,
                      action: GradientButton(
                        label: l10n.serversAddSubscription,
                        icon: LucideIcons.plus600,
                        onPressed: () => showAddSheet(context, ref),
                      ),
                    )
                  : EmptyState(
                      icon: LucideIcons.searchX300,
                      title: l10n.serversNothingFound,
                      message: l10n.serversNothingFoundBody,
                    ),
            ),
          ],
          AsyncData(:final value) => [
            PagePadding(child: _buildList(_flatten(value), selectedId, latency)),
          ],
          AsyncError() => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(icon: LucideIcons.cloudOff300, title: l10n.unknownError),
            ),
          ],
          _ => [const PagePadding(child: _SkeletonList())],
        },
      ],
    );
  }

  Widget _buildList(List<_Row> rows, String? selectedId, Map<String, LatencyResult> latency) {
    final l10n = context.l10n;
    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        final Widget child = switch (row) {
          _SubRow(:final group) => Padding(
            padding: EdgeInsets.only(
              top: i == 0 ? AppSpacing.sm : AppSpacing.xl,
              bottom: AppSpacing.sm,
            ),
            child: SubscriptionHeader(
              subscription: group.subscription!,
              serverCount: group.servers.length,
              collapsed: _collapsed.contains(group.subscription!.id),
              updating: _updating.contains(group.subscription!.id),
              onToggle: () => setState(() {
                final id = group.subscription!.id;
                if (!_collapsed.remove(id)) _collapsed.add(id);
              }),
              onMenu: (a) => _onSubscriptionMenu(group.subscription!, a),
            ),
          ),
          _ManualHeaderRow() => SectionHeader(l10n.serversManualGroup.toUpperCase()),
          _EmptyGroupRow() => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              l10n.serversEmptyGroup,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          _ServerRow(:final server, :final index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: StaggeredEntrance(
              index: index,
              child: ServerTile(
                server: server,
                selected: server.id == selectedId,
                latency: latency[server.id],
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(selectedServerIdProvider.notifier).select(server.id);
                },
                onToggleFavorite: () => ref.read(serverActionsProvider).toggleFavorite(server),
                onMenu: (a) => _onServerMenu(server, a),
              ),
            ),
          ),
        };
        return KeyedSubtree(
          key: ValueKey(switch (row) {
            _SubRow(:final group) => 'sub-${group.subscription!.id}',
            _ServerRow(:final server) => 'srv-${server.id}',
            _ManualHeaderRow() => 'manual',
            _EmptyGroupRow() => 'empty-$i',
          }),
          child: child,
        );
      },
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.query});

  final ServerQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final notifier = ref.read(serverQueryProvider.notifier);
    final sortLabel = switch (query.sort) {
      ServerSort.none => l10n.serversSortNone,
      ServerSort.latency => l10n.serversSortLatency,
      ServerSort.name => l10n.serversSortName,
    };
    return Row(
      children: [
        // Chips scroll if a long translation doesn't fit next to the sort menu.
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.serversFilterAll),
                  selected: !query.favoritesOnly,
                  onSelected: (_) {
                    if (query.favoritesOnly) notifier.toggleFavorites();
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  avatar: Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: query.favoritesOnly ? c.warning : c.textTertiary,
                  ),
                  label: Text(l10n.serversFilterFavorites),
                  selected: query.favoritesOnly,
                  onSelected: (_) => notifier.toggleFavorites(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        PopupMenuButton<ServerSort>(
          tooltip: l10n.serversSort,
          initialValue: query.sort,
          onSelected: notifier.setSort,
          itemBuilder: (context) => [
            menuItem(ServerSort.none, LucideIcons.listFilter, l10n.serversSortNone),
            menuItem(ServerSort.latency, LucideIcons.zap, l10n.serversSortLatency),
            menuItem(ServerSort.name, LucideIcons.arrowDownAZ, l10n.serversSortName),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.arrowUpDown, size: 16, color: c.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    sortLabel,
                    style: Theme.of(context).textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
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

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return SliverList.list(
      children: [
        for (var i = 0; i < 6; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Skeleton(width: 42, height: 42, radius: 21),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(width: 160, height: 14),
                        SizedBox(height: AppSpacing.sm),
                        Skeleton(width: 100, height: 11),
                      ],
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
