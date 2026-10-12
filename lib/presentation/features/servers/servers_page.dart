import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/feedback.dart';
import '../../widgets/page_scaffold.dart';

class ServersPage extends StatelessWidget {
  const ServersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageScaffold(
      title: l10n.serversTitle,
      actions: [
        AppIconButton(
          icon: LucideIcons.plus600,
          tooltip: l10n.serversAddSubscription,
          onPressed: () {},
        ),
      ],
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: LucideIcons.globe300,
            title: l10n.serversEmptyTitle,
            message: l10n.serversEmptyBody,
            action: GradientButton(
              label: l10n.serversAddSubscription,
              icon: LucideIcons.plus600,
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }
}
