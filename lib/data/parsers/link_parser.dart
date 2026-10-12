import 'dart:convert';

import '../../domain/servers/server_profile.dart';
import 'import_item.dart';

/// Parses share links: vless, vmess, trojan, ss, hysteria2/hy2, tuic,
/// wireguard/wg and happ://add/.
abstract final class LinkParser {
  static const schemes = {
    'vless',
    'vmess',
    'trojan',
    'ss',
    'hysteria2',
    'hy2',
    'tuic',
    'wireguard',
    'wg',
    'happ',
  };

  static bool looksLikeLink(String s) {
    final i = s.indexOf('://');
    return i > 0 && schemes.contains(s.substring(0, i).toLowerCase());
  }

  /// Parses one link. Throws [LinkParseException] if it's malformed or uses
  /// a feature sing-box can't handle.
  static ImportItem parse(String input) {
    final link = input.trim();
    final i = link.indexOf('://');
    if (i <= 0) throw LinkParseException('not a link', link);
    final scheme = link.substring(0, i).toLowerCase();
    try {
      return switch (scheme) {
        'vless' => _vless(_Parts.parse(link)),
        'vmess' => _vmess(link),
        'trojan' => _trojan(_Parts.parse(link)),
        'ss' => _shadowsocks(link),
        'hysteria2' || 'hy2' => _hysteria2(_Parts.parse(link)),
        'tuic' => _tuic(_Parts.parse(link)),
        'wireguard' || 'wg' => _wireguard(_Parts.parse(link)),
        'happ' => _happ(link),
        _ => throw LinkParseException('unsupported scheme: $scheme', link),
      };
    } on LinkParseException catch (e) {
      throw LinkParseException(e.reason, link);
    } on FormatException catch (e) {
      throw LinkParseException('malformed: ${e.message}', link);
    }
  }

  // --- protocols -----------------------------------------------------------

  static ServerItem _vless(_Parts p) {
    final q = p.query;
    final uuid = p.userInfo;
    if (uuid.isEmpty) throw const LinkParseException('missing uuid');
    final security = (q['security'] ?? 'none').toLowerCase();
    return ServerItem(
      name: p.nameOr(p.host),
      outbound: OutboundConfig(
        protocol: ProxyProtocol.vless,
        host: p.host,
        port: p.port,
        uuid: uuid,
        flow: q['flow'] ?? '',
        transport: _transportFromQuery(q),

        tls: _tls(security, q),
      ),
    );
  }

  static ServerItem _trojan(_Parts p) {
    final q = p.query;
    if (p.userInfo.isEmpty) throw const LinkParseException('missing password');
    // Trojan is TLS unless explicitly disabled.
    final security = (q['security'] ?? 'tls').toLowerCase();
    return ServerItem(
      name: p.nameOr(p.host),
      outbound: OutboundConfig(
        protocol: ProxyProtocol.trojan,
        host: p.host,
        port: p.port,
        password: p.userInfo,
        transport: _transportFromQuery(q),

        tls: _tls(security, q),
      ),
    );
  }

  static ServerItem _vmess(String link) {
    final body = link.substring('vmess://'.length).split('#').first;
    final decoded = tryDecodeBase64(body);
    if (decoded == null) throw const LinkParseException('vmess payload is not base64');
    final Object? json;
    try {
      json = jsonDecode(decoded);
    } on FormatException {
      throw const LinkParseException('vmess payload is not JSON');
    }
    if (json is! Map) throw const LinkParseException('vmess payload is not an object');
    final j = json.map((k, v) => MapEntry('$k', v == null ? '' : '$v'));
    final host = j['add'] ?? '';
    final port = int.tryParse(j['port'] ?? '') ?? 0;
    final uuid = j['id'] ?? '';
    if (host.isEmpty || port <= 0 || port > 65535 || uuid.isEmpty) {
      throw const LinkParseException('vmess: missing address, port or id');
    }
    final net = j['net'];
    final isGrpc = TransportType.parse(net) == TransportType.grpc;
    final tlsMode = (j['tls'] ?? '').toLowerCase();
    return ServerItem(
      name: (j['ps'] ?? '').isEmpty ? host : j['ps']!,
      outbound: OutboundConfig(
        protocol: ProxyProtocol.vmess,
        host: host,
        port: port,
        uuid: uuid,
        alterId: int.tryParse(j['aid'] ?? '') ?? 0,
        vmessSecurity: (j['scy'] ?? '').isEmpty ? 'auto' : j['scy']!,
        // In vmess JSON the gRPC service name travels in `path`.
        transport: _transport(
          net,
          path: isGrpc ? null : j['path'],
          host: j['host'],
          service: isGrpc ? j['path'] : null,
          mode: j['mode'],
        ),
        tls: _tls(tlsMode == 'tls' || tlsMode == 'reality' ? tlsMode : 'none', {
          'sni': j['sni'] ?? '',
          'alpn': j['alpn'] ?? '',
          'fp': j['fp'] ?? '',
          'pbk': j['pbk'] ?? '',
          'sid': j['sid'] ?? '',
          'allowInsecure': j['allowInsecure'] ?? '',
        }),
      ),
    );
  }

  static ServerItem _shadowsocks(String link) {
    var body = link.substring('ss://'.length);
    var name = '';
    final hash = body.indexOf('#');
    if (hash >= 0) {
      name = safeDecode(body.substring(hash + 1)).trim();
      body = body.substring(0, hash);
    }
    final qi = body.indexOf('?');
    final query = qi >= 0 ? _parseQuery(body.substring(qi + 1)) : const <String, String>{};
    if (qi >= 0) body = body.substring(0, qi);
    if (body.endsWith('/')) body = body.substring(0, body.length - 1);
    if (query['plugin']?.isNotEmpty ?? false) {
      throw const LinkParseException('shadowsocks plugins are not supported');
    }

    String method;
    String password;
    String hostPort;
    if (!body.contains('@')) {
      // Legacy: base64(method:password@host:port)
      final decoded = tryDecodeBase64(body);
      if (decoded == null || !decoded.contains('@')) {
        throw const LinkParseException('ss: unrecognized format');
      }
      final at = decoded.lastIndexOf('@');
      final cred = decoded.substring(0, at);
      hostPort = decoded.substring(at + 1);
      final c = cred.indexOf(':');
      if (c < 0) throw const LinkParseException('ss: missing password');
      method = cred.substring(0, c);
      password = cred.substring(c + 1);
    } else {
      // SIP002: userinfo is base64(method:password) or percent-encoded (2022 ciphers).
      final at = body.lastIndexOf('@');
      final userInfo = body.substring(0, at);
      hostPort = body.substring(at + 1);
      final plain = safeDecode(userInfo);
      final cred = plain.contains(':') ? plain : (tryDecodeBase64(userInfo) ?? '');
      final c = cred.indexOf(':');
      if (c < 0) throw const LinkParseException('ss: missing method or password');
      method = cred.substring(0, c);
      password = cred.substring(c + 1);
    }
    final (host, port) = _hostPort(hostPort);
    if (method.isEmpty || password.isEmpty) throw const LinkParseException('ss: empty credentials');
    return ServerItem(
      name: name.isEmpty ? host : name,
      outbound: OutboundConfig(
        protocol: ProxyProtocol.shadowsocks,
        host: host,
        port: port,
        method: method.toLowerCase(),
        password: password,
      ),
    );
  }

  static ServerItem _hysteria2(_Parts p) {
    final q = p.query;
    final obfs = q['obfs'] ?? '';
    if (obfs.isNotEmpty && obfs != 'salamander') {
      throw LinkParseException('hysteria2: unsupported obfs "$obfs"');
    }
    return ServerItem(
      name: p.nameOr(p.host),
      outbound: OutboundConfig(
        protocol: ProxyProtocol.hysteria2,
        host: p.host,
        port: p.port,
        password: p.userInfo,
        obfsPassword: obfs.isEmpty ? '' : q['obfs-password'] ?? '',
        upMbps: _mbps(q['upmbps'] ?? q['up']),
        downMbps: _mbps(q['downmbps'] ?? q['down']),
        tls: TlsConfig(
          mode: TlsMode.tls,
          sni: q['sni'] ?? q['peer'] ?? '',
          alpn: _list(q['alpn']),
          insecure: _bool(q['insecure'] ?? q['allowInsecure']),
        ),
      ),
    );
  }

  static ServerItem _tuic(_Parts p) {
    final q = p.query;
    final c = p.userInfo.indexOf(':');
    if (c <= 0) throw const LinkParseException('tuic: expected uuid:password');
    return ServerItem(
      name: p.nameOr(p.host),
      outbound: OutboundConfig(
        protocol: ProxyProtocol.tuic,
        host: p.host,
        port: p.port,
        uuid: p.userInfo.substring(0, c),
        password: p.userInfo.substring(c + 1),
        congestionControl: q['congestion_control'] ?? q['congestion-control'] ?? 'bbr',
        udpRelayMode: q['udp_relay_mode'] ?? q['udp-relay-mode'] ?? '',
        tls: TlsConfig(
          mode: TlsMode.tls,
          sni: q['sni'] ?? '',
          alpn: _list(q['alpn']).isEmpty ? const ['h3'] : _list(q['alpn']),
          insecure: _bool(q['allow_insecure'] ?? q['insecure'] ?? q['allowInsecure']),
        ),
      ),
    );
  }

  static ServerItem _wireguard(_Parts p) {
    final q = p.query;
    final publicKey = q['publickey'] ?? q['publicKey'] ?? q['public_key'] ?? '';
    final address = _list(q['address'] ?? q['ip']);
    if (p.userInfo.isEmpty || publicKey.isEmpty) {
      throw const LinkParseException('wireguard: missing keys');
    }
    if (address.isEmpty) throw const LinkParseException('wireguard: missing address');
    return ServerItem(
      name: p.nameOr(p.host),
      outbound: OutboundConfig(
        protocol: ProxyProtocol.wireguard,
        host: p.host,
        port: p.port,
        privateKey: p.userInfo,
        peerPublicKey: publicKey,
        preSharedKey: q['presharedkey'] ?? q['preSharedKey'] ?? q['psk'] ?? '',
        localAddresses: [for (final a in address) a.contains('/') ? a : _hostPrefix(a)],
        reserved: [for (final r in _list(q['reserved'])) int.tryParse(r) ?? 0],
        mtu: int.tryParse(q['mtu'] ?? '') ?? 0,
      ),
    );
  }

  static SubscriptionItem _happ(String link) {
    // happ://add/<url> — the URL may be raw or percent-encoded.
    const add = 'happ://add/';
    if (link.toLowerCase().startsWith(add)) {
      final url = safeDecode(link.substring(add.length)).trim();
      final uri = Uri.tryParse(url);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty) {
        return SubscriptionItem(url: url);
      }
      throw const LinkParseException('happ: invalid subscription URL');
    }
    // happ://crypt…/ links are encrypted with Happ's proprietary key.
    throw const LinkParseException('happ: only happ://add/ links are supported');
  }

  // --- shared pieces -------------------------------------------------------

  static TransportConfig _transport(
    String? type, {
    String? path,
    String? host,
    String? service,
    String? mode,
    String? extra,
  }) {
    final t = TransportType.parse(type);
    if (t == null) throw LinkParseException('transport "$type" is not supported');
    final isXhttp = t == TransportType.xhttp;
    return TransportConfig(
      type: t,
      path: path ?? '',
      host: host ?? '',
      serviceName: service ?? '',
      mode: isXhttp ? mode ?? '' : '',
      extra: isXhttp ? _jsonOrEmpty(extra) : '',
    );
  }

  /// Standard share-link transport params (`type`, `path`, `host`,
  /// `serviceName`, and for XHTTP `mode` + JSON `extra`).
  static TransportConfig _transportFromQuery(Map<String, String> q) => _transport(
    q['type'],
    path: q['path'],
    host: q['host'],
    service: q['serviceName'],
    mode: q['mode'],
    extra: q['extra'],
  );

  /// Keeps `extra` only if it is a JSON object (it is passed to Xray verbatim).
  static String _jsonOrEmpty(String? s) {
    if (s == null || s.trim().isEmpty) return '';
    try {
      return jsonDecode(s) is Map ? s.trim() : '';
    } on FormatException {
      throw const LinkParseException('xhttp: "extra" is not valid JSON');
    }
  }

  static TlsConfig _tls(String security, Map<String, String> q) {
    final mode = switch (security) {
      'tls' || 'xtls' => TlsMode.tls,
      'reality' => TlsMode.reality,
      '' || 'none' => TlsMode.none,
      _ => throw LinkParseException('security "$security" is not supported'),
    };
    if (mode == TlsMode.none) return const TlsConfig();
    final pbk = q['pbk'] ?? q['publicKey'] ?? '';
    if (mode == TlsMode.reality && pbk.isEmpty) {
      throw const LinkParseException('reality: missing public key');
    }
    return TlsConfig(
      mode: mode,
      sni: q['sni'] ?? q['peer'] ?? '',
      alpn: _list(q['alpn']),
      fingerprint: q['fp'] ?? '',
      insecure: _bool(q['allowInsecure'] ?? q['insecure'] ?? q['allow_insecure']),
      realityPublicKey: pbk,
      realityShortId: q['sid'] ?? q['shortId'] ?? '',
    );
  }

  static List<String> _list(String? s) =>
      (s ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  static bool _bool(String? s) => s == '1' || s?.toLowerCase() == 'true';

  /// "100", "100 Mbps", "100mbps" → 100.
  static int _mbps(String? s) => int.tryParse(RegExp(r'\d+').stringMatch(s ?? '') ?? '') ?? 0;

  static String _hostPrefix(String ip) => ip.contains(':') ? '$ip/128' : '$ip/32';
}

/// `scheme://userinfo@host:port/path?query#fragment`, parsed leniently.
class _Parts {
  _Parts({
    required this.userInfo,
    required this.host,
    required this.port,
    required this.query,
    required this.fragment,
  });

  final String userInfo;
  final String host;
  final int port;
  final Map<String, String> query;
  final String fragment;

  String nameOr(String fallback) => fragment.isEmpty ? fallback : fragment;

  static _Parts parse(String link) {
    var rest = link.substring(link.indexOf('://') + 3);
    var fragment = '';
    final hash = rest.indexOf('#');
    if (hash >= 0) {
      fragment = safeDecode(rest.substring(hash + 1)).trim();
      rest = rest.substring(0, hash);
    }
    var query = const <String, String>{};
    final qi = rest.indexOf('?');
    if (qi >= 0) {
      query = _parseQuery(rest.substring(qi + 1));
      rest = rest.substring(0, qi);
    }
    // userinfo may contain '/', so the authority ends at the first '/' after '@'.
    final at = rest.lastIndexOf('@');
    final slash = rest.indexOf('/', at + 1);
    final authority = slash >= 0 ? rest.substring(0, slash) : rest;
    final userInfo = at >= 0 ? safeDecode(authority.substring(0, at)) : '';
    final (host, port) = _hostPort(authority.substring(at + 1));
    return _Parts(userInfo: userInfo, host: host, port: port, query: query, fragment: fragment);
  }
}

/// Splits `host:port`, handling `[ipv6]:port` and port ranges (`443,8000-9000`
/// takes the first port).
(String, int) _hostPort(String s) {
  String host;
  String portStr;
  if (s.startsWith('[')) {
    final end = s.indexOf(']');
    if (end < 0) throw const LinkParseException('malformed IPv6 address');
    host = s.substring(1, end);
    portStr = s.length > end + 2 ? s.substring(end + 2) : '';
  } else {
    final c = s.lastIndexOf(':');
    if (c < 0) throw const LinkParseException('missing port');
    host = s.substring(0, c);
    portStr = s.substring(c + 1);
  }
  final port = int.tryParse(RegExp(r'^\d+').stringMatch(portStr) ?? '');
  if (host.isEmpty) throw const LinkParseException('missing host');
  if (port == null || port < 1 || port > 65535) throw const LinkParseException('invalid port');
  return (host, port);
}

/// Query parsing that keeps '+' literal (it appears in keys and paths).
Map<String, String> _parseQuery(String q) {
  final out = <String, String>{};
  for (final pair in q.split('&')) {
    if (pair.isEmpty) continue;
    final e = pair.indexOf('=');
    final k = safeDecode(e < 0 ? pair : pair.substring(0, e));
    final v = e < 0 ? '' : safeDecode(pair.substring(e + 1));
    out.putIfAbsent(k, () => v);
  }
  return out;
}
