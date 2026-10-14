import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_card.dart';
import 'choice_group.dart';
import 'decorations.dart';

/// Titled card that stacks form fields with even spacing.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact label + segmented selector for small enums inside a form.
class FormSegmented<T> extends StatelessWidget {
  const FormSegmented({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        ChoiceGroup<T>(value: value, options: options, onChanged: onChanged),
      ],
    );
  }
}
