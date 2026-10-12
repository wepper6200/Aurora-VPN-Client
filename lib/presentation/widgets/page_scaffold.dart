import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'app_background.dart';

/// Standard page layout: large title header + scrollable content column,
/// width-constrained on wide windows.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
    required this.slivers,
    this.floatingActionButton,
    this.opaque = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final List<Widget> slivers;
  final Widget? floatingActionButton;

  /// Paints its own background; needed for pages pushed over a tab so the
  /// page underneath doesn't show through during the transition.
  final bool opaque;

  @override
  Widget build(BuildContext context) {
    final page = _buildPage(context);
    return opaque ? AppBackground(child: page) : page;
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PageHeader(
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                    leading: leading,
                  ),
                ),
                ...slivers,
                SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.huge + MediaQuery.paddingOf(context).bottom),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (final a in actions) ...[const SizedBox(width: AppSpacing.sm), a],
        ],
      ),
    );
  }
}

/// Horizontal page padding for sliver content.
class PagePadding extends StatelessWidget {
  const PagePadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      sliver: child,
    );
  }
}
