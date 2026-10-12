import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/page_scaffold.dart';

class RoutingPage extends StatelessWidget {
  const RoutingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageScaffold(
      title: l10n.routingTitle,
      subtitle: l10n.routingSubtitle,
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(icon: LucideIcons.route300, title: l10n.routingTitle),
        ),
      ],
    );
  }
}
