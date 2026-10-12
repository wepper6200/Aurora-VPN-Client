import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../theme/app_colors.dart';

/// Floating snackbar with consistent styling.
void showToast(BuildContext context, String message, {bool error = false}) {
  final c = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? c.danger : null,
        duration: const Duration(seconds: 3),
      ),
    );
}

/// Destructive confirmation; resolves to `true` only on explicit confirm.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final l10n = context.l10n;
  final c = context.colors;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: c.textSecondary),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: c.danger),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Single-choice dialog returning the picked value (or `null` if dismissed).
Future<T?> pickOption<T>(
  BuildContext context, {
  required String title,
  required T current,
  required Map<T, String> options,
}) {
  final c = context.colors;
  return showDialog<T>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        for (final e in options.entries)
          ListTile(
            title: Text(e.value),
            trailing: e.key == current ? Icon(Icons.check_rounded, color: c.accentStart) : null,
            onTap: () => Navigator.of(context).pop(e.key),
          ),
      ],
    ),
  );
}
