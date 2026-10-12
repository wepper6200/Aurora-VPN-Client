import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/feedback.dart';
import '../../widgets/page_scaffold.dart';

/// QR import (Android). The camera preview is wired up in stage 3.
class ScanQrPage extends StatelessWidget {
  const ScanQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageScaffold(
      opaque: true,
      title: l10n.addScanQr,
      leading: AppIconButton(icon: LucideIcons.arrowLeft, onPressed: () => context.pop()),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: LucideIcons.scanQrCode,
            title: l10n.addScanQr,
            message: l10n.addScanQrSub,
          ),
        ),
      ],
    );
  }
}
