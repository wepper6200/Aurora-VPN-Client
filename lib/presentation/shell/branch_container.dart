import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Keeps every tab's navigator alive (like an IndexedStack) but cross-fades
/// and slightly lifts the active one when switching tabs.
class AnimatedBranchContainer extends StatelessWidget {
  const AnimatedBranchContainer({super.key, required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [for (var i = 0; i < children.length; i++) _branch(i)],
    );
  }

  Widget _branch(int i) {
    final active = i == currentIndex;
    // TickerMode must sit *inside* the transition widgets, otherwise it would
    // freeze the fade-out of the branch being left.
    return IgnorePointer(
      ignoring: !active,
      child: AnimatedSlide(
        offset: active ? Offset.zero : const Offset(0, 0.015),
        duration: AppDurations.medium,
        curve: AppCurves.standard,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: AppDurations.medium,
          curve: AppCurves.standard,
          child: TickerMode(
            enabled: active,
            child: ExcludeSemantics(excluding: !active, child: children[i]),
          ),
        ),
      ),
    );
  }
}
