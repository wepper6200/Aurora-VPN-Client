import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/import/import_service.dart';
import '../../core/l10n.dart';
import '../widgets/dialogs.dart';

/// Imports [text] and reports the outcome with a toast.
/// Returns `true` if anything was imported.
Future<bool> importWithFeedback(BuildContext context, WidgetRef ref, String text) async {
  final report = await ref.read(importServiceProvider).importText(text);
  if (!context.mounted) return !report.isEmpty;
  final l10n = context.l10n;
  if (report.isEmpty) {
    final reason = report.failures.isEmpty ? null : report.failures.first;
    showToast(
      context,
      reason == null ? l10n.clipboardNoLinks : '${l10n.clipboardNoLinks}: $reason',
      error: true,
    );
    return false;
  }
  final parts = [
    l10n.importResult(report.total),
    if (report.failures.isNotEmpty) l10n.importPartial(report.failures.length),
  ];
  showToast(context, parts.join(' · '));
  return true;
}
