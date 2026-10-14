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

/// Latency = ICMP echo round trip, via the system `ping` tool.
///
/// Used for UDP-based protocols, which have no TCP handshake to time. Needs
/// no root: Android's `ping` uses unprivileged ICMP sockets. Hosts that drop
/// ICMP report a timeout.
class IcmpLatencyTester implements LatencyTester {
  const IcmpLatencyTester({this.timeout = const Duration(seconds: 3)});

  final Duration timeout;

  // Windows prints "time=23ms TTL=57" (or "время=23мс", in the OEM code page),
  // so take the number right before the ASCII "TTL=". Unix: "time=23.4 ms".
  static final _windows = RegExp(r'[=<](\d+)\S*\s+TTL=', caseSensitive: false);
  static final _unix = RegExp(r'time[=<]([\d.]+)');

  @override
  bool supports(ServerProfile server) => true;

  @override
  Future<int?> test(ServerProfile server) async {
    try {
      final addresses = await InternetAddress.lookup(server.host).timeout(timeout);
      if (addresses.isEmpty) return null;
      final ip = addresses.first.address;
      final wait = timeout.inMilliseconds;
      final result = Platform.isWindows
          ? await Process.run('ping', ['-n', '1', '-w', '$wait', ip])
          : await Process.run('ping', ['-c', '1', '-W', '${(wait / 1000).ceil()}', ip]);
      if (result.exitCode != 0) return null;
      final out = '${result.stdout}';
      final match = Platform.isWindows ? _windows.firstMatch(out) : _unix.firstMatch(out);
      final ms = double.tryParse(match?.group(1) ?? '');
      return ms?.round().clamp(1, 99999);
    } on Exception {
      return null;
    }
  }
}

/// TCP handshake for TCP-based protocols, ICMP ping for UDP-based ones, so
/// every server gets a number.
class CompositeLatencyTester implements LatencyTester {
  const CompositeLatencyTester({
    this.tcp = const TcpLatencyTester(),
    this.icmp = const IcmpLatencyTester(),
  });

  final LatencyTester tcp;
  final LatencyTester icmp;

  @override
  bool supports(ServerProfile server) => true;

  @override
  Future<int?> test(ServerProfile server) =>
      tcp.supports(server) ? tcp.test(server) : icmp.test(server);
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
