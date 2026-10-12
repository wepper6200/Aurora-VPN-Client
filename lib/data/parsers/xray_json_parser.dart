import 'dart:convert';

import '../../domain/servers/server_profile.dart';
import 'import_item.dart';

/// Reads Xray-core JSON: a single config or an array of configs (as panels
/// such as Remnawave/Marzban serve to Xray-based clients), one server each.
///
/// A server that sing-box can run on its own is converted to the regular
/// model. Anything relying on Xray-only features (XHTTP, VLESS encryption,
/// mux, fragment/sockopt tricks, chained outbounds, hysteria) keeps its
/// original outbound JSON and runs through Xray-core.
abstract final class XrayJsonParser {
  static const _proxyProtocols = {
    'vless',
    'vmess',
    'trojan',
    'shadowsocks',
    'wireguard',
    'hysteria',
  };

  static bool looksLikeXray(Object? doc) {
    Map<String, Object?>? first;
    if (doc is List && doc.isNotEmpty && doc.first is Map) {
      first = (doc.first as Map).cast<String, Object?>();
    } else if (doc is Map) {
      first = doc.cast<String, Object?>();
    }
    final outbounds = first?['outbounds'];
    return outbounds is List && outbounds.any((o) => o is Map && o.containsKey('protocol'));
  }

  static ParseOutcome parse(Object? doc) {
    final configs = switch (doc) {
      final List<Object?> l => l.whereType<Map<Object?, Object?>>().toList(),
      final Map<Object?, Object?> m => [m],
      _ => const <Map<Object?, Object?>>[],
    };
    final items = <ImportItem>[];
    final failures = <LinkParseException>[];
    for (var i = 0; i < configs.length; i++) {
      final config = configs[i].cast<String, Object?>();
      final remarks = '${config['remarks'] ?? ''}'.trim();
      try {
        final item = _config(config, remarks.isEmpty ? 'Server ${i + 1}' : remarks);
        if (item != null) items.add(item);
      } on LinkParseException catch (e) {
        failures.add(LinkParseException(e.reason, remarks));
      } on TypeError {
        failures.add(LinkParseException('malformed Xray config', remarks));
      }
    }
    return ParseOutcome(items: items, failures: failures);
  }

  static ServerItem? _config(Map<String, Object?> config, String name) {
    final outbounds = (config['outbounds'] as List<Object?>? ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map((o) => o.cast<String, Object?>())
        .toList();
    final candidates = outbounds.where((o) => _proxyProtocols.contains(o['protocol'])).toList();
    if (candidates.isEmpty) return null;
    final proxy = candidates.firstWhere((o) => o['tag'] == 'proxy', orElse: () => candidates.first);

    final base = _outbound(proxy);
    if (base == null) return null;
    final xrayOnly = _needsXray(proxy);
    return ServerItem(
      name: name,
      outbound: xrayOnly ? base.withXray(_bundle(proxy, outbounds)) : base,
    );
  }

  /// The proxy outbound (tagged `proxy`) plus every outbound it chains
  /// through via `dialerProxy` / `proxySettings`.
  static String _bundle(Map<String, Object?> proxy, List<Map<String, Object?>> all) {
    final byTag = {for (final o in all) '${o['tag']}': o};
    final keep = <Map<String, Object?>>[];
    final seen = <String>{};
    void add(Map<String, Object?> o) {
      final tag = '${o['tag']}';
      if (!seen.add(tag)) return;
      keep.add(o);
      final dialer = ((o['streamSettings'] as Map?)?['sockopt'] as Map?)?['dialerProxy'];
      final chained = (o['proxySettings'] as Map?)?['tag'];
      for (final ref in [dialer, chained]) {
        if (ref is String && byTag[ref] != null) add(byTag[ref]!);
      }
    }

    add(proxy);
    keep[0] = {...keep[0], 'tag': 'proxy'};
    return jsonEncode({'outbounds': keep});
  }

  static bool _needsXray(Map<String, Object?> o) {
    final protocol = o['protocol'];
    if (protocol == 'hysteria') return true;
    final s = (o['settings'] as Map?)?.cast<String, Object?>() ?? const {};
    final user = _vlessUser(s);
    final encryption = '${user['encryption'] ?? s['encryption'] ?? 'none'}';
    if (protocol == 'vless' && encryption != 'none' && encryption.isNotEmpty) return true;
    if ((o['mux'] as Map?)?['enabled'] == true) return true;
    if (o['proxySettings'] != null) return true;
    final stream = (o['streamSettings'] as Map?)?.cast<String, Object?>() ?? const {};
    final network = '${stream['network'] ?? 'tcp'}';
    if (!const {
      'tcp',
      'raw',
      'ws',
      'websocket',
      'grpc',
      'httpupgrade',
      'h2',
      'http',
    }.contains(network)) {
      return true;
    }
    final sockopt = stream['sockopt'];
    if (sockopt is Map && sockopt.isNotEmpty) return true;
    if (stream['finalmask'] != null) return true;
    final header = ((stream['tcpSettings'] ?? stream['rawSettings']) as Map?)?['header'];
    if (header is Map && header['type'] != null && header['type'] != 'none') return true;
    return false;
  }

  static Map<String, Object?> _vlessUser(Map<String, Object?> s) {
    final vnext = s['vnext'];
    if (vnext is List && vnext.isNotEmpty) {
      final users = (vnext.first as Map)['users'];
      if (users is List && users.isNotEmpty && users.first is Map) {
        return (users.first as Map).cast<String, Object?>();
      }
    }
    return s;
  }

  /// Maps an Xray outbound onto the common model (used for display, latency
  /// tests and — when compatible — for running it on sing-box).
  static OutboundConfig? _outbound(Map<String, Object?> o) {
    final protocol = '${o['protocol']}';
    final s = (o['settings'] as Map?)?.cast<String, Object?>() ?? const {};
    String str(Object? v) => v == null ? '' : '$v';
    int port(Object? v) => int.tryParse(str(v)) ?? 0;

    switch (protocol) {
      case 'vless' || 'vmess':
        final vnext = (s['vnext'] as List?)?.firstOrNull as Map?;
        final host = str(vnext?['address'] ?? s['address']);
        final p = port(vnext?['port'] ?? s['port']);
        final user = _vlessUser(s);
        _requireEndpoint(host, p);
        return OutboundConfig(
          protocol: protocol == 'vless' ? ProxyProtocol.vless : ProxyProtocol.vmess,
          host: host,
          port: p,
          uuid: str(user['id']),
          flow: str(user['flow']),
          alterId: port(user['alterId']),
          vmessSecurity: str(user['security']).isEmpty ? 'auto' : str(user['security']),
          transport: _transport(o),
          tls: _tls(o),
        );
      case 'trojan' || 'shadowsocks':
        final server = (s['servers'] as List?)?.firstOrNull as Map? ?? s;
        final host = str(server['address']);
        final p = port(server['port']);
        _requireEndpoint(host, p);
        final ss = protocol == 'shadowsocks';
        return OutboundConfig(
          protocol: ss ? ProxyProtocol.shadowsocks : ProxyProtocol.trojan,
          host: host,
          port: p,
          password: str(server['password']),
          method: ss ? str(server['method']) : '',
          transport: ss ? const TransportConfig() : _transport(o),
          tls: ss ? const TlsConfig() : _tls(o),
        );
      case 'wireguard':
        final peer = (s['peers'] as List?)?.firstOrNull as Map? ?? const {};
        final endpoint = str(peer['endpoint']);
        final colon = endpoint.lastIndexOf(':');
        final host = colon > 0
            ? endpoint.substring(0, colon).replaceAll(RegExp(r'[\[\]]'), '')
            : endpoint;
        final p = colon > 0 ? port(endpoint.substring(colon + 1)) : 0;
        _requireEndpoint(host, p);
        return OutboundConfig(
          protocol: ProxyProtocol.wireguard,
          host: host,
          port: p,
          privateKey: str(s['secretKey']),
          peerPublicKey: str(peer['publicKey']),
          preSharedKey: str(peer['preSharedKey']),
          localAddresses: [
            for (final a in (s['address'] as List? ?? const []))
              '$a'.contains('/') ? '$a' : ('$a'.contains(':') ? '$a/128' : '$a/32'),
          ],
          reserved: [for (final r in (s['reserved'] as List? ?? const [])) port(r)],
          mtu: port(s['mtu']),
        );
      case 'hysteria':
        final host = str(s['address']);
        final p = port(s['port']);
        _requireEndpoint(host, p);
        return OutboundConfig(protocol: ProxyProtocol.hysteria2, host: host, port: p, tls: _tls(o));
    }
    return null;
  }

  static void _requireEndpoint(String host, int port) {
    if (host.isEmpty || port < 0 || port > 65535) {
      throw const LinkParseException('missing server address');
    }
  }

  static TransportConfig _transport(Map<String, Object?> o) {
    final stream = (o['streamSettings'] as Map?)?.cast<String, Object?>() ?? const {};
    final network = '${stream['network'] ?? 'tcp'}';
    final type = TransportType.parse(network);
    if (type == null) {
      // kcp etc.: displayable, runs through Xray via the raw outbound.
      return const TransportConfig();
    }
    Map<String, Object?> sub(List<String> keys) {
      for (final k in keys) {
        final v = stream[k];
        if (v is Map) return v.cast<String, Object?>();
      }
      return const {};
    }

    String str(Object? v) => v == null ? '' : '$v';
    switch (type) {
      case TransportType.ws:
        final ws = sub(['wsSettings']);
        final headers = (ws['headers'] as Map?) ?? const {};
        return TransportConfig(
          type: type,
          path: str(ws['path']),
          host: str(ws['host'] ?? headers['Host'] ?? headers['host']),
        );
      case TransportType.grpc:
        return TransportConfig(type: type, serviceName: str(sub(['grpcSettings'])['serviceName']));
      case TransportType.httpupgrade:
        final hu = sub(['httpupgradeSettings']);
        return TransportConfig(type: type, path: str(hu['path']), host: str(hu['host']));
      case TransportType.h2:
        final h = sub(['httpSettings']);
        final hosts = h['host'];
        return TransportConfig(
          type: type,
          path: str(h['path']),
          host: hosts is List ? hosts.join(',') : str(hosts),
        );
      case TransportType.xhttp:
        final x = sub(['xhttpSettings', 'splithttpSettings']);
        final extra = x['extra'];
        return TransportConfig(
          type: type,
          path: str(x['path']),
          host: str(x['host']),
          mode: str(x['mode']),
          extra: extra is Map ? jsonEncode(extra) : '',
        );
      case TransportType.tcp:
        return const TransportConfig();
    }
  }

  static TlsConfig _tls(Map<String, Object?> o) {
    final stream = (o['streamSettings'] as Map?)?.cast<String, Object?>() ?? const {};
    final security = '${stream['security'] ?? 'none'}';
    String str(Object? v) => v == null ? '' : '$v';
    switch (security) {
      case 'tls':
        final t = (stream['tlsSettings'] as Map?)?.cast<String, Object?>() ?? const {};
        final alpn = t['alpn'];
        return TlsConfig(
          mode: TlsMode.tls,
          sni: str(t['serverName']),
          alpn: alpn is List ? [for (final a in alpn) '$a'] : const [],
          fingerprint: str(t['fingerprint']),
          insecure: t['allowInsecure'] == true,
        );
      case 'reality':
        final r = (stream['realitySettings'] as Map?)?.cast<String, Object?>() ?? const {};
        return TlsConfig(
          mode: TlsMode.reality,
          sni: str(r['serverName']),
          fingerprint: str(r['fingerprint']),
          realityPublicKey: str(r['password'] ?? r['publicKey']),
          realityShortId: str(r['shortId']),
        );
    }
    return const TlsConfig();
  }
}

extension on OutboundConfig {
  OutboundConfig withXray(String raw) => OutboundConfig(
    protocol: protocol,
    host: host,
    port: port,
    uuid: uuid,
    password: password,
    method: method,
    flow: flow,
    alterId: alterId,
    vmessSecurity: vmessSecurity,
    transport: transport,
    tls: tls,
    privateKey: privateKey,
    peerPublicKey: peerPublicKey,
    preSharedKey: preSharedKey,
    localAddresses: localAddresses,
    reserved: reserved,
    mtu: mtu,
    xrayOutbound: raw,
  );
}
