import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n.dart';
import '../../router/app_router.dart';
import '../../shell/app_logo.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/feedback.dart';
import '../../widgets/page_scaffold.dart';

/// Stage 1 placeholder: the connect button and live stats arrive in stage 2.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageScaffold(
      title: l10n.homeTitle,
      subtitle: l10n.homeSubtitle,
      leading: const AppLogo(size: 40),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: LucideIcons.shieldCheck300,
            title: l10n.homeNoServerTitle,
            message: l10n.homeNoServerBody,
            action: GradientButton(
              label: l10n.serversAddSubscription,
              icon: LucideIcons.plus600,
              onPressed: () => context.go(AppRoutes.servers),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }
}
