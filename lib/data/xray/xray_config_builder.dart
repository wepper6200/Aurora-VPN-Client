import 'dart:convert';

import '../../domain/logs/log_entry.dart';
import '../../domain/servers/server_profile.dart';
import '../singbox/config_builder.dart';

/// Builds the Xray-core config that runs behind sing-box: one authenticated
/// SOCKS inbound on 127.0.0.1 (the bridge) and the server's outbound.
///
/// sing-box keeps doing TUN, DNS and routing; Xray only carries traffic for
/// servers that need its features (XHTTP, VLESS encryption, mux…).
abstract final class XrayConfigBuilder {
  static String buildJson({
    required OutboundConfig server,
    required XrayBridge bridge,
    LogLevel logLevel = LogLevel.warn,
  }) =>
      const JsonEncoder.withIndent('  ')
          .convert(build(server: server, bridge: bridge, logLevel: logLevel));

  static Map<String, Object?> build({
    required OutboundConfig server,
    required XrayBridge bridge,
    LogLevel logLevel = LogLevel.warn,
  }) {
    final outbounds = server.xrayOutbound.isNotEmpty
        ? _imported(server.xrayOutbound)
        : [outbound(server)];
    return {
      'log': {
        'loglevel': switch (logLevel) {
          LogLevel.trace || LogLevel.debug => 'debug',
          LogLevel.info => 'info',
          LogLevel.warn => 'warning',
          LogLevel.error => 'error',
        },
      },
      'inbounds': [
        {
          'tag': 'bridge-in',
          'listen': '127.0.0.1',
          'port': bridge.port,
          'protocol': 'socks',
          'settings': {
            'auth': 'password',
            'accounts': [
              {'user': bridge.username, 'pass': bridge.password},
            ],
            'udp': true,
            'ip': '127.0.0.1',
          },
        },
      ],
      'outbounds': [
        ...outbounds,
        {'tag': 'direct', 'protocol': 'freedom'},
      ],
    };
  }

  /// Outbounds kept verbatim from an imported Xray config (first is `proxy`).
  static List<Object?> _imported(String raw) {
    final decoded = jsonDecode(raw);
    final list = decoded is Map ? decoded['outbounds'] : null;
    if (list is! List || list.isEmpty) throw const FormatException('broken Xray outbound');
    return list;
  }

  /// Xray outbound generated from the common model (e.g. an XHTTP share link).
  static Map<String, Object?> outbound(OutboundConfig o) {
    final settings = switch (o.protocol) {
      ProxyProtocol.vless => {
        'vnext': [
          {
            'address': o.host,
            'port': o.port,
            'users': [
              {'id': o.uuid, 'encryption': 'none', if (o.flow.isNotEmpty) 'flow': o.flow},
            ],
          },
        ],
      },
      ProxyProtocol.vmess => {
        'vnext': [
          {
            'address': o.host,
            'port': o.port,
            'users': [
              {'id': o.uuid, 'alterId': o.alterId, 'security': o.vmessSecurity},
            ],
          },
        ],
      },
      ProxyProtocol.trojan => {
        'servers': [
          {'address': o.host, 'port': o.port, 'password': o.password},
        ],
      },
      ProxyProtocol.shadowsocks => {
        'servers': [
          {'address': o.host, 'port': o.port, 'method': o.method, 'password': o.password},
        ],
      },
      _ => throw ArgumentError('${o.protocol.label} is not generated for Xray'),
    };
    return {
      'tag': 'proxy',
      'protocol': o.protocol == ProxyProtocol.shadowsocks ? 'shadowsocks' : o.protocol.name,
      'settings': settings,
      if (o.protocol != ProxyProtocol.shadowsocks) 'streamSettings': _stream(o),
    };
  }

  static Map<String, Object?> _stream(OutboundConfig o) {
    final t = o.transport;
    final tls = o.tls;
    final sni = tls.sni.isNotEmpty ? tls.sni : (_isIp(o.host) ? '' : o.host);
    return {
      'network': switch (t.type) {
        TransportType.tcp => 'raw',
        TransportType.ws => 'ws',
        TransportType.grpc => 'grpc',
        TransportType.httpupgrade => 'httpupgrade',
        TransportType.xhttp || TransportType.h2 => 'xhttp',
      },
      'security': tls.mode.name,
      if (tls.mode == TlsMode.tls)
        'tlsSettings': {
          if (sni.isNotEmpty) 'serverName': sni,
          if (tls.alpn.isNotEmpty) 'alpn': tls.alpn,
          // A browser fingerprint: Go's own TLS hello is easy for DPI to spot.
          'fingerprint': tls.fingerprint.isNotEmpty ? tls.fingerprint : 'chrome',
          if (tls.insecure) 'allowInsecure': true,
        },
      if (tls.mode == TlsMode.reality)
        'realitySettings': {
          if (sni.isNotEmpty) 'serverName': sni,
          'fingerprint': tls.fingerprint.isNotEmpty ? tls.fingerprint : 'chrome',
          'publicKey': tls.realityPublicKey,
          if (tls.realityShortId.isNotEmpty) 'shortId': tls.realityShortId,
          if (tls.realitySpiderX.isNotEmpty) 'spiderX': tls.realitySpiderX,
          if (tls.realityMldsa65Verify.isNotEmpty) 'mldsa65Verify': tls.realityMldsa65Verify,
        },
      if (t.httpObfs)
        'rawSettings': {
          'header': {
            'type': 'http',
            'request': {
              'path': [t.path.isEmpty ? '/' : t.path],
              if (t.host.isNotEmpty)
                'headers': {
                  'Host': t.host.split(',').map((h) => h.trim()).where((h) => h.isNotEmpty).toList(),
                },
            },
          },
        },
      if (t.type == TransportType.ws)
        'wsSettings': {
          'path': t.path.isEmpty ? '/' : t.path,
          if (t.host.isNotEmpty) 'host': t.host,
        },
      if (t.type == TransportType.grpc) 'grpcSettings': {'serviceName': t.serviceName},
      if (t.type == TransportType.httpupgrade)
        'httpupgradeSettings': {
          'path': t.path.isEmpty ? '/' : t.path,
          if (t.host.isNotEmpty) 'host': t.host,
        },
      if (t.type == TransportType.xhttp || t.type == TransportType.h2)
        'xhttpSettings': {
          'path': t.path.isEmpty ? '/' : t.path,
          if (t.host.isNotEmpty) 'host': t.host.split(',').first.trim(),
          if (t.mode.isNotEmpty) 'mode': t.mode,
          if (t.extra.isNotEmpty) 'extra': jsonDecode(t.extra),
        },
    };
  }

  static bool _isIp(String host) => RegExp(r'^[\d.]+$').hasMatch(host) || host.contains(':');
}
