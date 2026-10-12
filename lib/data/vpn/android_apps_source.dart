import 'package:flutter/services.dart';

import '../../domain/routing/routing_settings.dart';
import '../../domain/servers/repositories.dart';

/// Installed apps via `aurora/apps` (android/.../bridge/AppsChannel.kt).
class AndroidAppsSource implements InstalledAppsSource {
  const AndroidAppsSource();

  static const _channel = MethodChannel('aurora/apps');

  @override
  Future<List<InstalledApp>> load({bool includeSystem = false}) async {
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('list', {
      'includeSystem': includeSystem,
    });
    return [
      for (final m in raw ?? const <Map<Object?, Object?>>[])
        InstalledApp(
          packageName: m['package']! as String,
          label: m['label']! as String,
          isSystem: m['system'] as bool? ?? false,
        ),
    ];
  }

  @override
  Future<List<int>?> icon(String packageName) =>
      _channel.invokeMethod<Uint8List>('icon', {'package': packageName, 'size': 96});
}
