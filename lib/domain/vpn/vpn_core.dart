import '../logs/log_entry.dart';

enum VpnStatus { disconnected, connecting, connected, disconnecting, error }

/// What the UI needs to know about the tunnel at any moment.
class VpnState {
  const VpnState({
    this.status = VpnStatus.disconnected,
    this.serverId,
    this.connectedAt,
    this.error,
  });

  final VpnStatus status;
  final String? serverId;
  final DateTime? connectedAt;

  /// Human-readable failure reason when [status] is [VpnStatus.error].
  final String? error;

  bool get isBusy => status == VpnStatus.connecting || status == VpnStatus.disconnecting;
  bool get isActive => status == VpnStatus.connected || status == VpnStatus.connecting;

  VpnState copyWith({VpnStatus? status, String? serverId, DateTime? connectedAt, String? error}) {
    return VpnState(
      status: status ?? this.status,
      serverId: serverId ?? this.serverId,
      connectedAt: connectedAt ?? this.connectedAt,
      error: error ?? this.error,
    );
  }
}

/// One traffic sample: current speeds (bytes/s) and session totals (bytes).
class TrafficSample {
  const TrafficSample({this.upSpeed = 0, this.downSpeed = 0, this.upTotal = 0, this.downTotal = 0});

  final int upSpeed;
  final int downSpeed;
  final int upTotal;
  final int downTotal;

  static const zero = TrafficSample();
}

/// Everything the core needs to bring the tunnel up.
class CoreStartRequest {
  const CoreStartRequest({
    required this.serverId,
    required this.configJson,
    this.label = '',
    this.xrayConfigJson,
    this.tun = true,
    this.systemProxyPort,
    this.clashApiPort,
    this.clashApiSecret = '',
  });

  final String serverId;

  /// Human-readable server name (shown in the system notification).
  final String label;

  /// Complete sing-box configuration.
  final String configJson;

  /// Xray-core config for servers that need it (sing-box forwards to it).
  final String? xrayConfigJson;

  /// Captures traffic with a TUN adapter (Windows: needs administrator).
  final bool tun;

  /// Windows proxy mode: local mixed port to register as the system proxy.
  final int? systemProxyPort;

  /// Windows: Clash API used for live traffic stats.
  final int? clashApiPort;
  final String clashApiSecret;
}

/// Platform bridge to the sing-box core. Implemented by
/// `AndroidVpnController` (libbox + VpnService) and `WindowsVpnController`
/// (sing-box.exe child process); a mock is used until those land.
abstract interface class VpnCoreController {
  Stream<VpnState> get states;
  Stream<TrafficSample> get traffic;
  Stream<LogEntry> get logs;

  Future<void> start(CoreStartRequest request);
  Future<void> stop();

  /// Delay in ms through [serverId]'s outbound, or `null` if unreachable.
  Future<int?> urlTest(String serverId);

  Future<void> dispose();
}
