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
}

/// A single proxy endpoint, either from a subscription or added manually.
///
/// Protocol-specific settings (credentials, transport, TLS) are added to this
/// model in stage 3 together with the link parsers.
class ServerProfile {
  const ServerProfile({
    required this.id,
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    this.subscriptionId,
    this.transport = 'tcp',
    this.security = 'none',
    this.favorite = false,
  });

  final String id;
  final String name;
  final ProxyProtocol protocol;
  final String host;
  final int port;

  /// `null` for manually added configs.
  final String? subscriptionId;

  /// tcp, ws, grpc, h2, httpupgrade, quic…
  final String transport;

  /// none, tls, reality.
  final String security;
  final bool favorite;

  ServerProfile copyWith({String? name, bool? favorite}) {
    return ServerProfile(
      id: id,
      name: name ?? this.name,
      protocol: protocol,
      host: host,
      port: port,
      subscriptionId: subscriptionId,
      transport: transport,
      security: security,
      favorite: favorite ?? this.favorite,
    );
  }
}
