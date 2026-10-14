import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Material 3 "shared axis X": the new page slides in 30 px from the right
/// while the old one slides out to the left, cross-fading through the
/// background. Going back mirrors it.
Widget sharedAxisX(Animation<double> animation, Animation<double> secondary, Widget child) {
  return AnimatedBuilder(
    animation: Listenable.merge([animation, secondary]),
    child: child,
    builder: (context, child) {
      final enter = Curves.easeInOutCubicEmphasized.transform(animation.value);
      final leave = Curves.easeInOutCubicEmphasized.transform(secondary.value);
      final opacity =
          const Interval(0.3, 1).transform(animation.value) *
          (1 - const Interval(0, 0.35).transform(secondary.value));
      return Transform.translate(
        offset: Offset(30 * (1 - enter) - 30 * leave, 0),
        child: Opacity(opacity: opacity, child: child),
      );
    },
  );
}

class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => sharedAxisX(animation, secondaryAnimation, child);
}

/// Where the element that opened a page sat on screen, for the container
/// transform. Set right before navigating; claimed by the page it opened.
abstract final class TransitionOrigin {
  static Rect? _pending;
  static final _byPage = <LocalKey, Rect>{};

  /// Records [context]'s render box as the origin of the next page.
  static void captureFrom(BuildContext context) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      _pending = box.localToGlobal(Offset.zero) & box.size;
    }
  }

  static Rect? _claim(LocalKey key) {
    final p = _pending;
    if (p != null) {
      _pending = null;
      _byPage[key] = p;
    }
    return _byPage[key];
  }
}

/// A page that grows out of the element that opened it (Material 3
/// container transform) when it has an origin; otherwise it uses the
/// style's regular transition (shared axis, or the iOS slide for glass).
Page<void> originPage(GoRouterState state, Widget child) {
  final origin = TransitionOrigin._claim(state.pageKey);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 420),
    transitionsBuilder: (context, animation, secondary, child) {
      if (context.colors.isGlass) {
        return CupertinoPageTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondary,
          linearTransition: false,
          child: child,
        );
      }
      if (origin == null) return sharedAxisX(animation, secondary, child);
      return _ContainerReveal(animation: animation, origin: origin, child: child);
    },
  );
}

class _ContainerReveal extends StatelessWidget {
  const _ContainerReveal({required this.animation, required this.origin, required this.child});

  final Animation<double> animation;

  /// Global rect of the element the page grows from.
  final Rect origin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        // The navigator may not start at the window's corner (desktop rail,
        // title bar), so bring the origin into its coordinates.
        final overlay = Navigator.of(context).overlay?.context.findRenderObject();
        final topLeft = overlay is RenderBox && overlay.hasSize
            ? overlay.globalToLocal(origin.topLeft)
            : origin.topLeft;
        final from = topLeft & origin.size;
        final to = Offset.zero & box.biggest;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final v = animation.value;
            final t = Curves.easeInOutCubicEmphasized.transform(v);
            final rect = Rect.lerp(from, to, t)!;
            final radius = lerpDouble(28, 0, t)!;
            return ClipRRect(
              clipper: _RRectClipper(RRect.fromRectAndRadius(rect, Radius.circular(radius))),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Color.lerp(
                      s.primaryContainer,
                      s.surface,
                      const Interval(0, 0.5).transform(v),
                    )!,
                  ),
                  Opacity(opacity: const Interval(0.25, 1).transform(v), child: child),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RRectClipper extends CustomClipper<RRect> {
  const _RRectClipper(this.rrect);

  final RRect rrect;

  @override
  RRect getClip(Size size) => rrect;

  @override
  bool shouldReclip(_RRectClipper old) => old.rrect != rrect;
}
