import '../../domain/servers/server_profile.dart';
import 'import_item.dart';

/// Extracts proxy outbounds from a sing-box configuration
/// (`outbounds` and, since 1.11, WireGuard `endpoints`).
abstract final class SingBoxJsonParser {
  static ParseOutcome parse(Map<String, Object?> config) {
    final items = <ImportItem>[];
    final failures = <LinkParseException>[];
    final entries = [
      ...?(config['outbounds'] as List<Object?>?),
      ...?(config['endpoints'] as List<Object?>?),
    ];
    for (final raw in entries) {
      if (raw is! Map) continue;
      final o = raw.cast<String, Object?>();
      final type = o['type'] as String? ?? '';
      // Groups, direct/block/dns are not servers.
      if (const {'selector', 'urltest', 'direct', 'block', 'dns'}.contains(type)) continue;
      try {
        final item = _outbound(type, o);
        if (item != null) items.add(item);
      } on LinkParseException catch (e) {
        failures.add(LinkParseException(e.reason, o['tag'] as String?));
      } on TypeError {
        failures.add(LinkParseException('malformed $type outbound', o['tag'] as String?));
      }
    }
    return ParseOutcome(items: items, failures: failures);
  }

  static ServerItem? _outbound(String type, Map<String, Object?> o) {
    final protocol = switch (type) {
      'vless' => ProxyProtocol.vless,
      'vmess' => ProxyProtocol.vmess,
      'trojan' => ProxyProtocol.trojan,
      'shadowsocks' => ProxyProtocol.shadowsocks,
      'hysteria2' => ProxyProtocol.hysteria2,
      'tuic' => ProxyProtocol.tuic,
      'wireguard' => ProxyProtocol.wireguard,
      _ => null,
    };
    if (protocol == null) return null;

    final tag = o['tag'] as String? ?? '';
    String s(String k) => o[k] as String? ?? '';

    if (protocol == ProxyProtocol.wireguard) {
      // Endpoint form: peers[0]; legacy outbound form: server/server_port.
      final peers = (o['peers'] as List<Object?>?)?.cast<Map<Object?, Object?>>();
      final peer = peers?.isNotEmpty ?? false ? peers!.first.cast<String, Object?>() : o;
      final host = (peer['address'] ?? peer['server']) as String? ?? '';
      final port = (peer['port'] ?? peer['server_port']) as int? ?? 0;
      return ServerItem(
        name: tag.isEmpty ? host : tag,
        outbound: OutboundConfig(
          protocol: protocol,
          host: host,
          port: port,
          privateKey: s('private_key'),
          peerPublicKey: (peer['public_key'] ?? peer['peer_public_key']) as String? ?? '',
          preSharedKey: (peer['pre_shared_key'] as String?) ?? '',
          localAddresses: ((o['address'] ?? o['local_address']) as List<Object?>? ?? const [])
              .cast<String>(),
          reserved: (peer['reserved'] as List<Object?>? ?? const []).cast<int>(),
          mtu: o['mtu'] as int? ?? 0,
        ),
      );
    }

    final host = s('server');
    final port = o['server_port'] as int? ?? 0;
    if (host.isEmpty || port <= 0) throw const LinkParseException('missing server');
    final obfs = (o['obfs'] as Map?)?.cast<String, Object?>();
    return ServerItem(
      name: tag.isEmpty ? host : tag,
      outbound: OutboundConfig(
        protocol: protocol,
        host: host,
        port: port,
        uuid: s('uuid'),
        password: s('password'),
        method: s('method'),
        flow: s('flow'),
        alterId: o['alter_id'] as int? ?? 0,
        vmessSecurity: s('security').isEmpty ? 'auto' : s('security'),
        transport: _transport((o['transport'] as Map?)?.cast<String, Object?>()),
        tls: _tls((o['tls'] as Map?)?.cast<String, Object?>(), forced: protocol.isUdpBased),
        obfsPassword: obfs?['password'] as String? ?? '',
        upMbps: o['up_mbps'] as int? ?? 0,
        downMbps: o['down_mbps'] as int? ?? 0,
        congestionControl: s('congestion_control'),
        udpRelayMode: s('udp_relay_mode'),
      ),
    );
  }

  static TransportConfig _transport(Map<String, Object?>? t) {
    if (t == null) return const TransportConfig();
    final type = t['type'] as String?;
    final headers = (t['headers'] as Map?)?.cast<String, Object?>();
    final host = t['host'];
    return TransportConfig(
      type: switch (type) {
        'ws' => TransportType.ws,
        'grpc' => TransportType.grpc,
        'http' => TransportType.h2,
        'httpupgrade' => TransportType.httpupgrade,
        _ => throw LinkParseException('transport "$type" is not supported'),
      },
      path: t['path'] as String? ?? '',
      host: switch (host) {
        final String h => h,
        final List<Object?> l when l.isNotEmpty => '${l.first}',
        _ => (headers?['Host'] ?? headers?['host']) as String? ?? '',
      },
      serviceName: t['service_name'] as String? ?? '',
    );
  }

  static TlsConfig _tls(Map<String, Object?>? t, {required bool forced}) {
    if (t == null || t['enabled'] != true) {
      return forced ? const TlsConfig(mode: TlsMode.tls) : const TlsConfig();
    }
    final reality = (t['reality'] as Map?)?.cast<String, Object?>();
    final utls = (t['utls'] as Map?)?.cast<String, Object?>();
    final isReality = reality?['enabled'] == true;
    return TlsConfig(
      mode: isReality ? TlsMode.reality : TlsMode.tls,
      sni: t['server_name'] as String? ?? '',
      alpn: (t['alpn'] as List<Object?>? ?? const []).cast<String>(),
      fingerprint: utls?['enabled'] == true ? utls!['fingerprint'] as String? ?? 'chrome' : '',
      insecure: t['insecure'] == true,
      realityPublicKey: isReality ? reality!['public_key'] as String? ?? '' : '',
      realityShortId: isReality ? reality!['short_id'] as String? ?? '' : '',
    );
  }
}
