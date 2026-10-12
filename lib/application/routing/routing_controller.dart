import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/routing/routing_settings.dart';
import '../di.dart';
import '../settings/settings_controller.dart';

final routingProvider = NotifierProvider<RoutingController, RoutingSettings>(RoutingController.new);

class RoutingController extends Notifier<RoutingSettings> {
  static const _p = 'routing.';

  @override
  RoutingSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    const d = RoutingSettings();
    T pick<T extends Enum>(List<T> values, String key, T fallback) {
      final name = prefs.getString('$_p$key');
      return values.where((v) => v.name == name).firstOrNull ?? fallback;
    }

    return RoutingSettings(
      mode: pick(RoutingMode.values, 'mode', d.mode),
      bypassLan: prefs.getBool('${_p}bypassLan') ?? d.bypassLan,
      ruDirect: prefs.getBool('${_p}ruDirect') ?? d.ruDirect,
      blockAds: prefs.getBool('${_p}blockAds') ?? d.blockAds,
      splitMode: pick(SplitTunnelMode.values, 'splitMode', d.splitMode),
      splitApps: (prefs.getStringList('${_p}splitApps') ?? const []).toSet(),
    );
  }

  Future<void> update(RoutingSettings Function(RoutingSettings r) change) async {
    final s = change(state);
    state = s;
    final prefs = ref.read(sharedPreferencesProvider);
    await Future.wait([
      prefs.setString('${_p}mode', s.mode.name),
      prefs.setBool('${_p}bypassLan', s.bypassLan),
      prefs.setBool('${_p}ruDirect', s.ruDirect),
      prefs.setBool('${_p}blockAds', s.blockAds),
      prefs.setString('${_p}splitMode', s.splitMode.name),
      prefs.setStringList('${_p}splitApps', s.splitApps.toList()..sort()),
    ]);
  }

  Future<void> toggleApp(String packageName) => update((r) {
    final apps = {...r.splitApps};
    if (!apps.remove(packageName)) apps.add(packageName);
    return r.copyWith(splitApps: apps);
  });
}

final installedAppsProvider = FutureProvider.family<List<InstalledApp>, bool>(
  (ref, includeSystem) => ref.watch(installedAppsSourceProvider).load(includeSystem: includeSystem),
);

/// PNG icon bytes per package (cached for the session).
final appIconProvider = FutureProvider.family<List<int>?, String>(
  (ref, pkg) => ref.watch(installedAppsSourceProvider).icon(pkg),
);
