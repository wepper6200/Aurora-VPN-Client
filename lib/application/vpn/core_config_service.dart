import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/platform.dart';
import '../../data/singbox/config_builder.dart';
import '../../data/xray/xray_config_builder.dart';
import '../../domain/servers/server_profile.dart';
import '../../domain/settings/app_settings.dart';
import '../../domain/vpn/vpn_core.dart';
import '../routing/routing_controller.dart';
import '../settings/settings_controller.dart';

/// On-disk locations the core needs.
class CoreEnvironment {
  const CoreEnvironment({required this.ruleSetDir, required this.dataDir});

  final String ruleSetDir;
  final String dataDir;
}

/// Extracts bundled rule sets into the app's private directory (once per
/// launch, only when the bundled file differs) and resolves paths.
final coreEnvironmentProvider = FutureProvider<CoreEnvironment>((ref) async {
  final support = await getApplicationSupportDirectory();
  final rules = Directory('${support.path}/rules');
  await rules.create(recursive: true);
  for (final tag in RuleSets.all) {
    final data = await rootBundle.load('assets/rules/$tag.srs');
    final file = File('${rules.path}/$tag.srs');
    if (!file.existsSync() || file.lengthSync() != data.lengthInBytes) {
      await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    }
  }
  // sing-box wants forward slashes on every platform.
  String norm(String p) => p.replaceAll(r'\', '/');
  return CoreEnvironment(ruleSetDir: norm(rules.path), dataDir: norm(support.path));
});

final coreConfigServiceProvider = Provider<CoreConfigService>(CoreConfigService.new);

/// Turns the current server + routing + settings into a start request.
class CoreConfigService {
  CoreConfigService(this._ref);

  final Ref _ref;

  static const androidPackage = 'dev.aurora.aurora_vpn';

  Future<CoreStartRequest> build(ServerProfile server) async {
    final env = await _ref.read(coreEnvironmentProvider.future);
    final settings = _ref.read(settingsProvider);
    final platform = _ref.read(appPlatformProvider);
    final bridge = server.outbound.requiresXray ? _newBridge() : null;
    final options = switch (platform) {
      AppPlatform.android => CoreOptions(
        capture: CaptureMode.tun,
        android: true,
        ruleSetDir: env.ruleSetDir,
        cachePath: '${env.dataDir}/cache.db',
        xray: bridge,
        selfPackage: androidPackage,
      ),
      _ => CoreOptions(
        capture: settings.windowsMode == WindowsTunnelMode.tun
            ? CaptureMode.tun
            : CaptureMode.systemProxy,
        ruleSetDir: env.ruleSetDir,
        cachePath: '${env.dataDir}/cache.db',
        xray: bridge,
      ),
    };
    return CoreStartRequest(
      serverId: server.id,
      label: server.name,
      configJson: SingBoxConfigBuilder.buildJson(
        server: server,
        routing: _ref.read(routingProvider),
        settings: settings,
        options: options,
      ),
      xrayConfigJson: bridge == null
          ? null
          : XrayConfigBuilder.buildJson(
              server: server.outbound,
              bridge: bridge,
              logLevel: settings.logLevel,
            ),
    );
  }

  /// Fresh port and credentials for every session.
  static XrayBridge _newBridge() {
    final rnd = Random.secure();
    String token() => List.generate(16, (_) => rnd.nextInt(36).toRadixString(36)).join();
    return XrayBridge(port: 20000 + rnd.nextInt(40000), username: token(), password: token());
  }
}
