import 'dart:convert';

import '../../domain/routing/routing_settings.dart';
import '../../domain/servers/server_profile.dart';
import '../../domain/settings/app_settings.dart';

/// How the core captures traffic on this platform.
enum CaptureMode {
  /// Android VpnService / Windows wintun.
  tun,

  /// Windows: local mixed (HTTP+SOCKS) inbound registered as system proxy.
  systemProxy,
}

class CoreOptions {
  const CoreOptions({
    required this.capture,
    required this.ruleSetDir,
    this.android = false,
    this.mixedPort = 2080,
    this.clashApiPort,
    this.clashApiSecret = '',
    this.cachePath,
    this.xray,
    this.selfPackage,
    this.xrayProcessName = 'xray.exe',
  });

  final CaptureMode capture;

  /// Directory holding the bundled `*.srs` rule sets.
  final String ruleSetDir;

  /// Enables Android-only TUN options (per-app include/exclude).
  final bool android;
  final int mixedPort;

  /// Exposes the Clash API on 127.0.0.1 (Windows stats / URL tests).
  final int? clashApiPort;
  final String clashApiSecret;
  final String? cachePath;

  /// Local hop to Xray-core; required when the server needs Xray.
  final XrayBridge? xray;

  /// Android: our own package, excluded from the TUN when Xray dials out so
  /// its connections don't loop back into the tunnel.
  final String? selfPackage;

  /// Windows: the Xray process, routed direct for the same reason.
  final String xrayProcessName;
}

/// Authenticated SOCKS5 hop from sing-box to Xray-core on 127.0.0.1.
/// Port and credentials are random per session so other local apps can
/// neither find nor use it.
class XrayBridge {
  const XrayBridge({required this.port, required this.username, required this.password});

  final int port;
  final String username;
  final String password;
}

/// Rule sets shipped with the app (downloaded by scripts/fetch_core.*).
abstract final class RuleSets {
  static const geoipRu = 'geoip-ru';
  static const geositeRu = 'geosite-category-ru';
  static const geositeAds = 'geosite-category-ads-all';
  static const all = [geoipRu, geositeRu, geositeAds];
}

/// Builds a complete sing-box (1.12+) configuration.
abstract final class SingBoxConfigBuilder {
  static const proxyTag = 'proxy';
  static const directTag = 'direct';
  static const tunTag = 'tun-in';
  static const mixedTag = 'mixed-in';
  static const remoteDns = 'dns-remote';
  static const localDns = 'dns-local';

  static String buildJson({
    required ServerProfile server,
    required RoutingSettings routing,
    required AppSettings settings,
    required CoreOptions options,
  }) =>
      const JsonEncoder.withIndent('  ')
          .convert(build(server: server, routing: routing, settings: settings, options: options));

  static Map<String, Object?> build({
    required ServerProfile server,
    required RoutingSettings routing,
    required AppSettings settings,
    required CoreOptions options,
  }) {
    final rules = routing.mode == RoutingMode.rules;
    final usedSets = <String>{
      if (rules && routing.ruDirect) ...[RuleSets.geoipRu, RuleSets.geositeRu],
      if (rules && routing.blockAds) RuleSets.geositeAds,
    };
    final viaXray = server.outbound.requiresXray;
    final bridge = options.xray;
    if (viaXray && bridge == null) {
      throw ArgumentError('server ${server.id} needs Xray-core but no bridge was given');
    }
    final isWireGuard = !viaXray && server.protocol == ProxyProtocol.wireguard;
    final proxy = viaXray
        ? {
            'type': 'socks',
            'tag': proxyTag,
            'server': '127.0.0.1',
            'server_port': bridge!.port,
            'version': '5',
            'username': bridge.username,
            'password': bridge.password,
          }
        : outbound(server.outbound);

    return {
      'log': {'level': settings.logLevel.name, 'timestamp': true},
      'dns': _dns(routing, settings),
      'inbounds': [_inbound(routing, settings, options, excludeSelf: viaXray)],
      if (isWireGuard) 'endpoints': [proxy],
      'outbounds': [
        if (!isWireGuard) proxy,
        {'type': 'direct', 'tag': directTag},
      ],
      'route': {
        'rules': [
          {'action': 'sniff'},
          {'protocol': 'dns', 'action': 'hijack-dns'},
          if (viaXray && !options.android && options.capture == CaptureMode.tun)
            {
              'process_name': [options.xrayProcessName],
              'outbound': directTag,
            },
          // Without IPv6 the tunnel still captures v6 so it can't leak around it.
          if (!settings.ipv6) {'ip_version': 6, 'action': 'reject'},
          if (rules && routing.bypassLan) {'ip_is_private': true, 'outbound': directTag},
          if (rules && routing.blockAds)
            {
              'rule_set': [RuleSets.geositeAds],
              'action': 'reject',
            },
          if (rules && routing.ruDirect)
            {
              'rule_set': [RuleSets.geoipRu, RuleSets.geositeRu],
              'outbound': directTag,
            },
        ],
        'rule_set': [
          for (final tag in RuleSets.all)
            if (usedSets.contains(tag))
              {
                'type': 'local',
                'tag': tag,
                'format': 'binary',
                'path': '${options.ruleSetDir}/$tag.srs',
              },
        ],
        'final': routing.mode == RoutingMode.direct ? directTag : proxyTag,
        'auto_detect_interface': true,
        'default_domain_resolver': localDns,
      },
      'experimental': {
        'cache_file': {'enabled': true, if (options.cachePath != null) 'path': options.cachePath},
        if (options.clashApiPort != null)
          'clash_api': {
            'external_controller': '127.0.0.1:${options.clashApiPort}',
            'secret': options.clashApiSecret,
          },
      },
    };
  }

  static Map<String, Object?> _dns(RoutingSettings routing, AppSettings settings) {
    final rules = routing.mode == RoutingMode.rules;
    final viaProxy = routing.mode != RoutingMode.direct;
    return {
      'servers': [
        {
          ..._dnsServer(settings.dnsProtocol, settings.dnsServer),
          'tag': remoteDns,
          if (viaProxy) 'detour': proxyTag,
        },
        {'type': 'local', 'tag': localDns},
      ],
      'rules': [
        if (rules && routing.blockAds)
          {
            'rule_set': [RuleSets.geositeAds],
            'action': 'reject',
          },
        if (rules && routing.ruDirect)
          {
            'rule_set': [RuleSets.geositeRu],
            'server': localDns,
          },
      ],
      'final': remoteDns,
      'strategy': settings.ipv6 ? 'prefer_ipv4' : 'ipv4_only',
    };
  }

  /// `https://1.1.1.1/dns-query`, `tls://dns.google`, `8.8.8.8`, `udp://9.9.9.9:53`.
  static Map<String, Object?> _dnsServer(DnsProtocol protocol, String address) {
    var a = address.trim();
    for (final prefix in const ['https://', 'tls://', 'udp://']) {
      if (a.toLowerCase().startsWith(prefix)) a = a.substring(prefix.length);
    }
    var path = '';
    final slash = a.indexOf('/');
    if (slash >= 0) {
      path = a.substring(slash);
      a = a.substring(0, slash);
    }
    int? port;
    final colon = a.lastIndexOf(':');
    if (colon > 0 && !a.contains(']') && a.indexOf(':') == colon) {
      port = int.tryParse(a.substring(colon + 1));
      if (port != null) a = a.substring(0, colon);
    }
    final isIp = RegExp(r'^[\d.]+$').hasMatch(a) || a.contains(':');
    return {
      'type': switch (protocol) {
        DnsProtocol.doh => 'https',
        DnsProtocol.dot => 'tls',
        DnsProtocol.udp => 'udp',
      },
      'server': a,
      'server_port': ?port,
      if (protocol == DnsProtocol.doh && path.isNotEmpty && path != '/dns-query') 'path': path,
      // A resolver given by name needs another resolver to find it.
      if (!isIp) 'domain_resolver': localDns,
    };
  }

  static Map<String, Object?> _inbound(
    RoutingSettings routing,
    AppSettings settings,
    CoreOptions options, {
    bool excludeSelf = false,
  }) {
    if (options.capture == CaptureMode.systemProxy) {
      return {
        'type': 'mixed',
        'tag': mixedTag,
        'listen': '127.0.0.1',
        'listen_port': options.mixedPort,
        'set_system_proxy': true,
      };
    }
    final split =
        options.android && routing.splitMode != SplitTunnelMode.off && routing.splitApps.isNotEmpty;
    final include = split && routing.splitMode == SplitTunnelMode.include;
    final self = options.selfPackage;
    // An include list already leaves our app out; otherwise exclude it so
    // Xray's own connections bypass the tunnel.
    final apps = {
      if (split) ...routing.splitApps,
      if (options.android && excludeSelf && !include && self != null) self,
    }.toList()..sort();
    return {
      'type': 'tun',
      'tag': tunTag,
      if (!options.android) 'interface_name': 'AuroraTun',
      'address': ['172.19.0.1/30', 'fdfe:dcba:9876::1/126'],
      'mtu': settings.mtu,
      'auto_route': true,
      // Android: the VpnService owns routing. Windows: strict route is the kill switch.
      'strict_route': options.android || settings.killSwitch,
      'stack': 'mixed',
      if (include) 'include_package': apps,
      if (!include && apps.isNotEmpty) 'exclude_package': apps,
    };
  }

  /// A sing-box outbound (or, for WireGuard, an endpoint) tagged [proxyTag].
  static Map<String, Object?> outbound(OutboundConfig o, {String tag = proxyTag}) {
    final base = <String, Object?>{'tag': tag};
    switch (o.protocol) {
      case ProxyProtocol.vless:
        return {
          'type': 'vless',
          ...base,
          ..._server(o),
          'uuid': o.uuid,
          if (o.flow.isNotEmpty) 'flow': o.flow,
          'packet_encoding': 'xudp',
          ..._tlsAndTransport(o),
        };
      case ProxyProtocol.vmess:
        return {
          'type': 'vmess',
          ...base,
          ..._server(o),
          'uuid': o.uuid,
          'security': o.vmessSecurity,
          if (o.alterId != 0) 'alter_id': o.alterId,
          ..._tlsAndTransport(o),
        };
      case ProxyProtocol.trojan:
        return {
          'type': 'trojan',
          ...base,
          ..._server(o),
          'password': o.password,
          ..._tlsAndTransport(o),
        };
      case ProxyProtocol.shadowsocks:
        return {
          'type': 'shadowsocks',
          ...base,
          ..._server(o),
          'method': o.method,
          'password': o.password,
        };
      case ProxyProtocol.hysteria2:
        return {
          'type': 'hysteria2',
          ...base,
          ..._server(o),
          'password': o.password,
          if (o.upMbps > 0) 'up_mbps': o.upMbps,
          if (o.downMbps > 0) 'down_mbps': o.downMbps,
          if (o.obfsPassword.isNotEmpty) 'obfs': {'type': 'salamander', 'password': o.obfsPassword},
          'tls': _tls(o, forceEnabled: true),
        };
      case ProxyProtocol.tuic:
        return {
          'type': 'tuic',
          ...base,
          ..._server(o),
          'uuid': o.uuid,
          'password': o.password,
          if (o.congestionControl.isNotEmpty) 'congestion_control': o.congestionControl,
          if (o.udpRelayMode.isNotEmpty) 'udp_relay_mode': o.udpRelayMode,
          'tls': _tls(o, forceEnabled: true),
        };
      case ProxyProtocol.wireguard:
        return {
          'type': 'wireguard',
          ...base,
          'address': o.localAddresses,
          'private_key': o.privateKey,
          if (o.mtu > 0) 'mtu': o.mtu,
          'peers': [
            {
              'address': o.host,
              'port': o.port,
              'public_key': o.peerPublicKey,
              if (o.preSharedKey.isNotEmpty) 'pre_shared_key': o.preSharedKey,
              'allowed_ips': ['0.0.0.0/0', '::/0'],
              if (o.reserved.isNotEmpty) 'reserved': o.reserved,
            },
          ],
        };
    }
  }

  static Map<String, Object?> _server(OutboundConfig o) => {
    'server': o.host,
    'server_port': o.port,
  };

  static Map<String, Object?> _tlsAndTransport(OutboundConfig o) => {
    if (o.tls.enabled) 'tls': _tls(o),
    if (o.transport.type != TransportType.tcp) 'transport': _transport(o.transport),
  };

  static Map<String, Object?> _tls(OutboundConfig o, {bool forceEnabled = false}) {
    final t = o.tls;
    final sni = t.sni.isNotEmpty ? t.sni : (_isIp(o.host) ? '' : o.host);
    final reality = t.mode == TlsMode.reality;
    // Reality requires uTLS; default to Chrome when the link didn't say.
    final fp = t.fingerprint.isNotEmpty ? t.fingerprint : (reality ? 'chrome' : '');
    return {
      'enabled': forceEnabled || t.enabled,
      if (sni.isNotEmpty) 'server_name': sni,
      if (t.insecure) 'insecure': true,
      if (t.alpn.isNotEmpty) 'alpn': t.alpn,
      if (fp.isNotEmpty) 'utls': {'enabled': true, 'fingerprint': fp},
      if (reality)
        'reality': {
          'enabled': true,
          'public_key': t.realityPublicKey,
          if (t.realityShortId.isNotEmpty) 'short_id': t.realityShortId,
        },
    };
  }

  static Map<String, Object?> _transport(TransportConfig t) {
    switch (t.type) {
      case TransportType.ws:
        return {
          'type': 'ws',
          'path': t.path.isEmpty ? '/' : t.path,
          if (t.host.isNotEmpty) 'headers': {'Host': t.host},
        };
      case TransportType.grpc:
        return {'type': 'grpc', 'service_name': t.serviceName};
      case TransportType.h2:
        return {
          'type': 'http',
          if (t.host.isNotEmpty) 'host': t.host.split(',').map((h) => h.trim()).toList(),
          if (t.path.isNotEmpty) 'path': t.path,
        };
      case TransportType.httpupgrade:
        return {
          'type': 'httpupgrade',
          if (t.host.isNotEmpty) 'host': t.host,
          'path': t.path.isEmpty ? '/' : t.path,
        };
      case TransportType.xhttp:
        // XHTTP servers are routed to Xray through a SOCKS bridge (see build()).
        throw StateError('XHTTP is not a sing-box transport');
      case TransportType.tcp:
        return const {};
    }
  }

  static bool _isIp(String host) => RegExp(r'^[\d.]+$').hasMatch(host) || host.contains(':');
}
