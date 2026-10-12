import 'dart:io';

import '../../domain/servers/repositories.dart';
import '../../domain/servers/server_profile.dart';

/// Latency = time of a TCP handshake to the server (DNS resolution excluded).
///
/// Works without the core and without root/admin. UDP-based protocols
/// (Hysteria2, TUIC, WireGuard) can't be measured this way; they are tested
/// through the core once it's running.
class TcpLatencyTester implements LatencyTester {
  const TcpLatencyTester({this.timeout = const Duration(seconds: 3)});

  final Duration timeout;

  @override
  bool supports(ServerProfile server) => !server.protocol.isUdpBased;

  @override
  Future<int?> test(ServerProfile server) async {
    try {
      final addresses = await InternetAddress.lookup(server.host).timeout(timeout);
      if (addresses.isEmpty) return null;
      final sw = Stopwatch()..start();
      final socket = await Socket.connect(addresses.first, server.port, timeout: timeout);
      sw.stop();
      socket.destroy();
      return sw.elapsedMilliseconds.clamp(1, 99999);
    } on Exception {
      return null;
    }
  }
}

/// Fixed latencies for tests and UI previews.
class StaticLatencyTester implements LatencyTester {
  const StaticLatencyTester(this.values, {this.delay = const Duration(milliseconds: 400)});

  final Map<String, int?> values;
  final Duration delay;

  @override
  bool supports(ServerProfile server) => true;

  @override
  Future<int?> test(ServerProfile server) async {
    await Future<void>.delayed(delay + Duration(milliseconds: (values[server.id] ?? 900)));
    return values[server.id];
  }
}
