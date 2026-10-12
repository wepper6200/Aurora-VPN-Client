import '../../domain/servers/server_profile.dart';
import 'import_item.dart';

/// Extracts `proxies` from a Clash / Clash.Meta (mihomo) YAML profile.
abstract final class ClashYamlParser {
  /// [doc] is the YAML already converted to plain Dart maps/lists.
  static ParseOutcome parse(Map<String, Object?> doc) {
    final items = <ImportItem>[];
    final failures = <LinkParseException>[];
    for (final raw in (doc['proxies'] as List<Object?>? ?? const [])) {
      if (raw is! Map) continue;
      final p = raw.cast<String, Object?>();
      final name = '${p['name'] ?? ''}';
      try {
        final item = _proxy(p);
        if (item != null) items.add(item);
      } on LinkParseException catch (e) {
        failures.add(LinkParseException(e.reason, name));
      } on TypeError {
        failures.add(LinkParseException('malformed ${p['type']} proxy', name));
      }
    }
    return ParseOutcome(items: items, failures: failures);
  }

  static ServerItem? _proxy(Map<String, Object?> p) {
    final type = '${p['type'] ?? ''}'.toLowerCase();
    final protocol = switch (type) {
      'vless' => ProxyProtocol.vless,
      'vmess' => ProxyProtocol.vmess,
      'trojan' => ProxyProtocol.trojan,
      'ss' => ProxyProtocol.shadowsocks,
      'hysteria2' => ProxyProtocol.hysteria2,
      'tuic' => ProxyProtocol.tuic,
      'wireguard' => ProxyProtocol.wireguard,
      _ => null,
    };
    if (protocol == null) {
      throw LinkParseException('proxy type "$type" is not supported');
    }

    String s(String k) => p[k] == null ? '' : '${p[k]}';
    final host = s('server');
    final port = int.tryParse(s('port')) ?? 0;
    if (host.isEmpty || port <= 0 || port > 65535) {
      throw const LinkParseException('missing server or port');
    }
    final name = s('name').isEmpty ? host : s('name');

    if (protocol == ProxyProtocol.shadowsocks && s('plugin').isNotEmpty) {
      throw const LinkParseException('shadowsocks plugins are not supported');
    }

    if (protocol == ProxyProtocol.wireguard) {
      return ServerItem(
        name: name,
        outbound: OutboundConfig(
          protocol: protocol,
          host: host,
          port: port,
          privateKey: s('private-key'),
          peerPublicKey: s('public-key'),
          preSharedKey: s('pre-shared-key'),
          localAddresses: [
            if (s('ip').isNotEmpty) s('ip').contains('/') ? s('ip') : '${s('ip')}/32',
            if (s('ipv6').isNotEmpty) s('ipv6').contains('/') ? s('ipv6') : '${s('ipv6')}/128',
          ],
          reserved: (p['reserved'] is List)
              ? [for (final r in p['reserved']! as List<Object?>) int.tryParse('$r') ?? 0]
              : const [],
          mtu: int.tryParse(s('mtu')) ?? 0,
        ),
      );
    }

    final reality = (p['reality-opts'] as Map?)?.cast<String, Object?>();
    final tlsEnabled =
        p['tls'] == true ||
        reality != null ||
        protocol.isUdpBased ||
        protocol == ProxyProtocol.trojan;
    final tls = !tlsEnabled
        ? const TlsConfig()
        : TlsConfig(
            mode: reality != null ? TlsMode.reality : TlsMode.tls,
            sni: s('servername').isNotEmpty ? s('servername') : s('sni'),
            alpn: (p['alpn'] as List<Object?>? ?? const []).map((e) => '$e').toList(),
            fingerprint: s('client-fingerprint'),
            insecure: p['skip-cert-verify'] == true,
            realityPublicKey: '${reality?['public-key'] ?? ''}',
            realityShortId: '${reality?['short-id'] ?? ''}',
          );

    return ServerItem(
      name: name,
      outbound: OutboundConfig(
        protocol: protocol,
        host: host,
        port: port,
        uuid: s('uuid'),
        password: s('password'),
        method: protocol == ProxyProtocol.shadowsocks ? s('cipher') : '',
        flow: s('flow'),
        alterId: int.tryParse(s('alterId')) ?? 0,
        vmessSecurity: protocol == ProxyProtocol.vmess && s('cipher').isNotEmpty
            ? s('cipher')
            : 'auto',
        transport: protocol == ProxyProtocol.shadowsocks || protocol.isUdpBased
            ? const TransportConfig()
            : _transport(p),
        tls: tls,
        obfsPassword: s('obfs') == 'salamander' ? s('obfs-password') : '',
        upMbps: int.tryParse(RegExp(r'\d+').stringMatch(s('up')) ?? '') ?? 0,
        downMbps: int.tryParse(RegExp(r'\d+').stringMatch(s('down')) ?? '') ?? 0,
        congestionControl: s('congestion-controller'),
        udpRelayMode: s('udp-relay-mode'),
      ),
    );
  }

  static TransportConfig _transport(Map<String, Object?> p) {
    final network = '${p['network'] ?? 'tcp'}';
    final type = TransportType.parse(network);
    if (type == null) throw LinkParseException('network "$network" is not supported');
    Map<String, Object?> opts(String k) => (p[k] as Map?)?.cast<String, Object?>() ?? const {};
    switch (type) {
      case TransportType.ws:
        final o = opts('ws-opts');
        final headers = (o['headers'] as Map?)?.cast<String, Object?>() ?? const {};
        return TransportConfig(
          type: type,
          path: '${o['path'] ?? ''}',
          host: '${headers['Host'] ?? headers['host'] ?? ''}',
        );
      case TransportType.grpc:
        return TransportConfig(
          type: type,
          serviceName: '${opts('grpc-opts')['grpc-service-name'] ?? ''}',
        );
      case TransportType.h2:
        final o = opts('h2-opts');
        final hosts = o['host'] as List<Object?>? ?? const [];
        return TransportConfig(
          type: type,
          path: '${o['path'] ?? ''}',
          host: hosts.isEmpty ? '' : '${hosts.first}',
        );
      case TransportType.httpupgrade:
        final o = opts('http-upgrade-opts');
        return TransportConfig(type: type, path: '${o['path'] ?? ''}', host: '${o['host'] ?? ''}');
      case TransportType.xhttp:
        final o = opts('xhttp-opts');
        return TransportConfig(
          type: type,
          path: '${o['path'] ?? ''}',
          host: '${o['host'] ?? ''}',
          mode: '${o['mode'] ?? ''}',
        );
      case TransportType.tcp:
        return const TransportConfig();
    }
  }
}
