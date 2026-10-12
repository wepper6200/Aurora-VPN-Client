import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens.dart';
import '../../util/import_feedback.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/decorations.dart';
import '../../widgets/feedback.dart';

/// Full-screen camera that imports the first QR code it recognizes (Android).
class ScanQrPage extends ConsumerStatefulWidget {
  const ScanQrPage({super.key});

  @override
  ConsumerState<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends ConsumerState<ScanQrPage> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final value = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (value == null || value.trim().isEmpty) return;
    _handled = true;
    await _controller.stop();
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    final ok = await importWithFeedback(context, ref, value);
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      _handled = false;
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => ColoredBox(
              color: c.background,
              child: EmptyState(icon: LucideIcons.cameraOff, title: l10n.cameraDenied),
            ),
          ),
          // Viewfinder
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.xxl),
                border: Border.all(color: c.accentStart, width: 3),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIconButton(icon: LucideIcons.arrowLeft, onPressed: () => context.pop()),
                  const Spacer(),
                  Center(
                    child: StatusPill(
                      label: l10n.scanHint,
                      color: Colors.white,
                      icon: LucideIcons.scanQrCode,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
