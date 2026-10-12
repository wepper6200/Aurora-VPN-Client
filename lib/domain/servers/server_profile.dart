import 'outbound.dart';

export 'outbound.dart';

enum ProxyProtocol {
  vless('VLESS'),
  vmess('VMess'),
  trojan('Trojan'),
  shadowsocks('Shadowsocks'),
  hysteria2('Hysteria2'),
  tuic('TUIC'),
  wireguard('WireGuard');

  const ProxyProtocol(this.label);

  final String label;

  /// Runs over UDP/QUIC, so a TCP handshake can't measure its latency.
  bool get isUdpBased => this == hysteria2 || this == tuic || this == wireguard;
}

/// A single proxy endpoint, either from a subscription or added manually.
class ServerProfile {
  const ServerProfile({
    required this.id,
    required this.name,
    required this.outbound,
    this.subscriptionId,
    this.favorite = false,
    this.sortIndex = 0,
  });

  final String id;
  final String name;
  final OutboundConfig outbound;

  /// `null` for manually added configs.
  final String? subscriptionId;
  final bool favorite;

  /// Position inside its subscription, as delivered by the provider.
  final int sortIndex;

  ProxyProtocol get protocol => outbound.protocol;
  String get host => outbound.host;
  int get port => outbound.port;

  /// tcp, ws, grpc, h2, httpupgrade, quic, udp.
  String get transport => outbound.transportLabel;

  /// none, tls, reality.
  String get security => outbound.securityLabel;

  /// Identity that survives subscription refreshes (ids are regenerated),
  /// used to keep favorites and the selection.
  String get identity => '${protocol.name}|$host|$port|$name';

  ServerProfile copyWith({
    String? id,
    String? name,
    OutboundConfig? outbound,
    String? Function()? subscriptionId,
    bool? favorite,
    int? sortIndex,
  }) {
    return ServerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      outbound: outbound ?? this.outbound,
      subscriptionId: subscriptionId != null ? subscriptionId() : this.subscriptionId,
      favorite: favorite ?? this.favorite,
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }
}
