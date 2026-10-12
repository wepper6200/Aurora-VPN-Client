import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../application/settings/settings_controller.dart';
import '../../../core/l10n.dart';
import '../../router/app_router.dart';
import '../../shell/app_logo.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/decorations.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pages = PageController();
  int _index = 0;

  static const _count = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go(AppRoutes.home);
  }

  void _next() {
    if (_index == _count - 1) {
      _finish();
    } else {
      _pages.nextPage(duration: AppDurations.slow, curve: AppCurves.emphasized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final slides = [
      (const _HeroLogo(), l10n.onb1Title, l10n.onb1Body),
      (
        const _IconCluster(
          center: LucideIcons.link,
          satellites: [LucideIcons.qrCode, LucideIcons.clipboardPaste, LucideIcons.layers],
        ),
        l10n.onb2Title,
        l10n.onb2Body,
      ),
      (
        const _IconCluster(
          center: LucideIcons.route,
          satellites: [LucideIcons.layoutGrid, LucideIcons.shieldCheck, LucideIcons.globeLock],
        ),
        l10n.onb3Title,
        l10n.onb3Body,
      ),
    ];

    return AppBackground(
      glowAlignment: _index - 1.0,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: AnimatedOpacity(
                        duration: AppDurations.medium,
                        opacity: _index == _count - 1 ? 0 : 1,
                        child: TextButton(
                          onPressed: _index == _count - 1 ? null : _finish,
                          style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                          child: Text(l10n.onbSkip),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: _count,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) {
                        final (art, title, body) = slides[i];
                        return _Slide(art: art, title: title, body: body);
                      },
                    ),
                  ),
                  _Dots(count: _count, index: _index),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.xxl,
                      AppSpacing.page,
                      AppSpacing.xxl,
                    ),
                    child: GradientButton(
                      label: _index == _count - 1 ? l10n.onbStart : l10n.onbNext,
                      icon: _index == _count - 1 ? LucideIcons.rocket : LucideIcons.arrowRight,
                      expand: true,
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.art, required this.title, required this.body});

  final Widget art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 220, child: Center(child: art)),
          const SizedBox(height: AppSpacing.xxxl),
          Text(title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            style: theme.textTheme.bodyLarge!.copyWith(color: context.colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HeroLogo extends StatelessWidget {
  const _HeroLogo();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            c.accentStart.withValues(alpha: 0.28 * c.glowStrength),
            c.accentEnd.withValues(alpha: 0.10 * c.glowStrength),
            Colors.transparent,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.surface,
          border: Border.all(color: c.border),
          boxShadow: [BoxShadow(color: c.shadow, blurRadius: 30, offset: const Offset(0, 12))],
        ),
        alignment: Alignment.center,
        child: const AppLogo(size: 72),
      ),
    );
  }
}

class _IconCluster extends StatelessWidget {
  const _IconCluster({required this.center, required this.satellites});

  final IconData center;
  final List<IconData> satellites;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const positions = [Offset(-78, -46), Offset(80, -30), Offset(0, 84)];
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
              gradient: RadialGradient(
                colors: [
                  c.accentEnd.withValues(alpha: 0.14 * c.glowStrength),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          IconBadge(icon: center, size: 96, gradient: true),
          for (var i = 0; i < satellites.length; i++)
            Transform.translate(
              offset: positions[i],
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.border),
                ),
                child: IconBadge(
                  icon: satellites[i],
                  size: 44,
                  color: [c.accentStart, c.info, c.accentEnd][i % 3],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppDurations.medium,
            curve: AppCurves.standard,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              gradient: i == index ? c.accentGradient : null,
              color: i == index ? null : c.textTertiary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
      ],
    );
  }
}
