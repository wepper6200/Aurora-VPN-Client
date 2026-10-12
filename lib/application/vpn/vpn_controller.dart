import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/vpn/vpn_core.dart';
import '../di.dart';
import '../servers/servers_controller.dart';
import 'core_config_service.dart';

final vpnStateProvider = NotifierProvider<VpnController, VpnState>(VpnController.new);

class VpnController extends Notifier<VpnState> {
  @override
  VpnState build() {
    final sub = ref.watch(vpnCoreProvider).states.listen((s) => state = s);
    ref.onDispose(sub.cancel);
    return const VpnState();
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
