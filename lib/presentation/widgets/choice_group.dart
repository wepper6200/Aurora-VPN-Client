import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'glass.dart';

/// Single choice among a few options.
///
/// Material 3 Expressive: a connected button group — the selected button
/// turns into a full pill with a check mark while its neighbours keep tight
/// inner corners. Liquid Glass: a glass capsule with a sliding lens.
class ChoiceGroup<T> extends StatelessWidget {
  const ChoiceGroup({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  void _select(T v) {
    if (v == value) return;
    HapticFeedback.selectionClick();
    onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return context.colors.isGlass ? _glass(context) : _material(context);
  }

  Widget _material(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme.labelLarge!;
    final entries = options.entries.toList();
    // Narrow slots (4+ options) drop the check mark so labels stay on one line.
    final compact = entries.length > 3;
    const outer = Radius.circular(22);
    const inner = Radius.circular(AppRadii.xs);
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            child: Builder(
              builder: (context) {
                final selected = entries[i].key == value;
                final first = i == 0, last = i == entries.length - 1;
                final radius = selected
                    ? const BorderRadius.all(outer)
                    : BorderRadius.horizontal(
                        left: first ? outer : inner,
                        right: last ? outer : inner,
                      );
                final fg = selected ? s.onPrimary : s.onSurfaceVariant;
                return Semantics(
                  button: true,
                  selected: selected,
                  inMutuallyExclusiveGroup: true,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    constraints: const BoxConstraints(minHeight: 44),
                    decoration: BoxDecoration(
                      color: selected ? s.primary : s.surfaceContainerHighest,
                      borderRadius: radius,
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        borderRadius: radius,
                        onTap: () => _select(entries[i].key),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 10, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSize(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutBack,
                                child: selected && !compact
                                    ? Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: Icon(LucideIcons.check600, size: 16, color: fg),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              Flexible(
                                child: Text(
                                  entries[i].value,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.copyWith(color: fg),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _glass(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme.labelLarge!;
    final entries = options.entries.toList();
    final index = entries.indexWhere((e) => e.key == value).clamp(0, entries.length - 1);
    return GlassSurface(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      shadow: false,
      child: SizedBox(
        height: 46,
        child: LayoutBuilder(
          builder: (context, box) {
            final slot = (box.maxWidth - 8) / entries.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 460),
                  curve: Curves.easeOutBack,
                  left: 4 + slot * index,
                  top: 4,
                  bottom: 4,
                  width: slot,
                  child: GlassSurface(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    shadow: false,
                    tint: c.accentStart.withValues(alpha: c.isDark ? 0.28 : 0.3),
                    child: const SizedBox.expand(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      for (var i = 0; i < entries.length; i++)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: i == index,
                            inMutuallyExclusiveGroup: true,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _select(entries[i].key),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    entries[i].value,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.copyWith(
                                      fontSize: 13,
                                      color: i == index ? c.textPrimary : c.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
