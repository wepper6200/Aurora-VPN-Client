import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform.dart';
import '../../domain/servers/server_profile.dart';
import '../../domain/vpn/vpn_core.dart';
import '../di.dart';
import '../routing/routing_controller.dart';
import '../servers/servers_controller.dart';
import '../settings/settings_controller.dart';
import 'core_config_service.dart';

final vpnStateProvider = NotifierProvider<VpnController, VpnState>(VpnController.new);

class VpnController extends Notifier<VpnState> {
  @override
  VpnState build() {
    final sub = ref.watch(vpnCoreProvider).states.listen((s) => state = s);
    ref.onDispose(sub.cancel);
    ref.onDispose(() => _reload?.cancel());

    // Anything that ends up in the core config is applied live: another
    // server, an edited server, routing, DNS/MTU/IPv6/kill switch/log level.
    // null → server is the list loading at launch, not a change: restarting
    // then would hang a tunnel that kept running while the UI was closed.
    ref.listen(
      selectedServerProvider.select(_serverKey),
      (prev, _) => _scheduleReload(restart: prev != null),
    );
    ref.listen(routingProvider, (_, _) => _scheduleReload());
    ref.listen(
      settingsProvider.select(
        (s) => (s.dnsProtocol, s.dnsServer, s.mtu, s.ipv6, s.killSwitch, s.logLevel, s.windowsMode),
      ),
      (_, _) => _scheduleReload(),
    );
    return const VpnState();
  }

  Timer? _reload;

  static String? _serverKey(ServerProfile? s) =>
      s == null ? null : '${s.id}|${jsonEncode(s.outbound.toJson())}';

  /// Debounced so a burst of toggles restarts the core once. While
  /// disconnected, the new config is only remembered for the tile/widget.
  void _scheduleReload({bool restart = true}) {
    if (state.status != VpnStatus.connected) {
      if (state.status == VpnStatus.disconnected || state.status == VpnStatus.error) {
        unawaited(_remember());
      }
      return;
    }
    if (!restart) return;
    _reload?.cancel();
    _reload = Timer(reloadDelay, () {
      if (ref.mounted && state.status == VpnStatus.connected) unawaited(connect());
    });
  }

  static const reloadDelay = Duration(milliseconds: 700);

  /// Android: stores the selected server's config so the quick settings tile
  /// and the home-screen widget connect to it without opening the app.
  Future<void> _remember() async {
    if (ref.read(appPlatformProvider) != AppPlatform.android) return;
    final server = ref.read(selectedServerProvider);
    if (server == null) return;
    try {
      final request = await ref.read(coreConfigServiceProvider).build(server);
      if (!ref.mounted || state.isActive) return;
      await ref.read(vpnCoreProvider).remember(request);
    } catch (_) {
      // Best effort: the tile then uses the last connected server.
    }
  }

  Future<void> connect() async {
    final server = ref.read(selectedServerProvider);
    if (server == null) {
      state = const VpnState(status: VpnStatus.error, error: 'no-server');
      return;
    }
    state = VpnState(status: VpnStatus.connecting, serverId: server.id);
    final CoreStartRequest request;
    try {
      request = await ref.read(coreConfigServiceProvider).build(server);
    } catch (e) {
      state = VpnState(status: VpnStatus.error, serverId: server.id, error: '$e');
      return;
    }
    await ref.read(vpnCoreProvider).start(request);
  }

  Future<void> disconnect() => ref.read(vpnCoreProvider).stop();

  /// "Connect on launch": only when enabled, a server is chosen and no
  /// tunnel is already up (the Android service may outlive the UI).
  Future<void> autoConnect() async {
    if (!ref.read(settingsProvider).autoConnect) return;
    // At launch the server list is still loading from the database.
    await ref.read(serversProvider.future);
    if (!ref.mounted || ref.read(selectedServerProvider) == null) return;
    if (await ref.read(vpnCoreProvider).isRunning()) return;
    if (!ref.mounted || state.status != VpnStatus.disconnected) return;
    await connect();
  }

  Future<void> toggle() async {
    switch (state.status) {
      case VpnStatus.disconnected:
      case VpnStatus.error:
        await connect();
      case VpnStatus.connecting:
      case VpnStatus.connected:
        await disconnect();
      case VpnStatus.disconnecting:
        break;
    }
  }
}

/// Latest traffic sample.
final trafficProvider = NotifierProvider<TrafficController, TrafficSample>(TrafficController.new);

class TrafficController extends Notifier<TrafficSample> {
  @override
  TrafficSample build() {
    final sub = ref.watch(vpnCoreProvider).traffic.listen((t) => state = t);
    ref.onDispose(sub.cancel);
    return TrafficSample.zero;
  }
}

/// Rolling window of speed samples for the sparklines.
class SpeedHistory {
  const SpeedHistory({this.up = const [], this.down = const []});

  static const length = 40;

  final List<double> up;
  final List<double> down;
}

final speedHistoryProvider = NotifierProvider<SpeedHistoryController, SpeedHistory>(
  SpeedHistoryController.new,
);

class SpeedHistoryController extends Notifier<SpeedHistory> {
  @override
  SpeedHistory build() {
    ref.listen(trafficProvider, (_, t) => _push(t));
    ref.listen(vpnStateProvider.select((s) => s.status), (prev, next) {
      // Start from a zero baseline so the line spans the full width at once.
      if (next == VpnStatus.connecting) {
        final zeros = List<double>.filled(SpeedHistory.length, 0);
        state = SpeedHistory(up: zeros, down: zeros);
      }
    });
    return const SpeedHistory();
  }

  void _push(TrafficSample t) {
    List<double> add(List<double> l, int v) {
      final n = [...l, v.toDouble()];
      return n.length > SpeedHistory.length ? n.sublist(n.length - SpeedHistory.length) : n;
    }

    state = SpeedHistory(up: add(state.up, t.upSpeed), down: add(state.down, t.downSpeed));
  }
}
