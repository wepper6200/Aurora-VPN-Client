import 'dart:convert';

import '../../domain/servers/server_profile.dart';

/// Turns a profile back into a standard share link (inverse of LinkParser).
abstract final class LinkSerializer {
  static String toLink(String name, OutboundConfig o) {
    final fragment = name.isEmpty ? '' : '#${Uri.encodeComponent(name)}';
    final hostPort = '${o.host.contains(':') ? '[${o.host}]' : o.host}:${o.port}';
    String enc(String s) => Uri.encodeComponent(s);

    switch (o.protocol) {
      case ProxyProtocol.vless:
        return 'vless://${enc(o.uuid)}@$hostPort?${_query({'encryption': 'none', 'flow': o.flow, ..._transportQuery(o.transport), ..._tlsQuery(o.tls)})}$fragment';
      case ProxyProtocol.trojan:
        return 'trojan://${enc(o.password)}@$hostPort?${_query({..._transportQuery(o.transport), ..._tlsQuery(o.tls)})}$fragment';
      case ProxyProtocol.vmess:
        final t = o.transport;
        final json = {
          'v': '2',
          'ps': name,
          'add': o.host,
          'port': '${o.port}',
          'id': o.uuid,
          'aid': '${o.alterId}',
          'scy': o.vmessSecurity,
          'net': t.type.name,
          'type': 'none',
          'host': t.host,
          'path': t.type == TransportType.grpc ? t.serviceName : t.path,
          'tls': o.tls.enabled ? 'tls' : '',
          'sni': o.tls.sni,
          'alpn': o.tls.alpn.join(','),
          'fp': o.tls.fingerprint,
        };
        return 'vmess://${base64.encode(utf8.encode(jsonEncode(json)))}';
      case ProxyProtocol.shadowsocks:
        final userInfo = o.method.startsWith('2022-')
            ? '${enc(o.method)}:${enc(o.password)}'
            : base64Url.encode(utf8.encode('${o.method}:${o.password}')).replaceAll('=', '');
        return 'ss://$userInfo@$hostPort$fragment';
      case ProxyProtocol.hysteria2:
        return 'hysteria2://${enc(o.password)}@$hostPort/?${_query({'sni': o.tls.sni, 'alpn': o.tls.alpn.join(','), 'insecure': o.tls.insecure ? '1' : '', 'obfs': o.obfsPassword.isEmpty ? '' : 'salamander', 'obfs-password': o.obfsPassword})}$fragment';
      case ProxyProtocol.tuic:
        return 'tuic://${enc(o.uuid)}:${enc(o.password)}@$hostPort?${_query({'congestion_control': o.congestionControl, 'udp_relay_mode': o.udpRelayMode, 'alpn': o.tls.alpn.join(','), 'sni': o.tls.sni, 'allow_insecure': o.tls.insecure ? '1' : ''})}$fragment';
      case ProxyProtocol.wireguard:
        return 'wireguard://${enc(o.privateKey)}@$hostPort?${_query({'publickey': o.peerPublicKey, 'presharedkey': o.preSharedKey, 'address': o.localAddresses.join(','), 'reserved': o.reserved.join(','), 'mtu': o.mtu == 0 ? '' : '${o.mtu}'})}$fragment';
    }
  }

  static Map<String, String> _transportQuery(TransportConfig t) => {
    'type': t.type.name,
    'path': t.path,
    'host': t.host,
    'serviceName': t.serviceName,
  };

  static Map<String, String> _tlsQuery(TlsConfig t) => {
    'security': t.mode.name,
    'sni': t.sni,
    'alpn': t.alpn.join(','),
    'fp': t.fingerprint,
    'pbk': t.realityPublicKey,
    'sid': t.realityShortId,
    'allowInsecure': t.insecure ? '1' : '',
  };

  static String _query(Map<String, String> q) => [
    for (final e in q.entries)
      if (e.value.isNotEmpty) '${e.key}=${Uri.encodeComponent(e.value)}',
  ].join('&');
}
