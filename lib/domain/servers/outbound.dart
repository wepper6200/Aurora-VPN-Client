import 'server_profile.dart';

/// Stream transport for VLESS / VMess / Trojan.
enum TransportType {
  tcp,
  ws,
  grpc,
  h2,
  httpupgrade,

  /// Xray's XHTTP (SplitHTTP); runs through Xray-core, not sing-box.
  xhttp;

  static TransportType? parse(String? s) => switch (s?.toLowerCase()) {
    null || '' || 'tcp' || 'raw' || 'none' => tcp,
    'ws' || 'websocket' => ws,
    'grpc' || 'gun' => grpc,
    'h2' || 'http' => h2,
    'httpupgrade' => httpupgrade,
    'xhttp' || 'splithttp' => xhttp,
    _ => null, // kcp, quic… are not supported
  };
}

class TransportConfig {
  const TransportConfig({
    this.type = TransportType.tcp,
    this.path = '',
    this.host = '',
    this.serviceName = '',
    this.mode = '',
    this.extra = '',
    this.headerType = '',
  });

  final TransportType type;

  /// Path (ws/httpupgrade/xhttp/h2, or the request path of the TCP HTTP header).
  final String path;

  /// Host header (ws/httpupgrade/xhttp/TCP HTTP header) or authority (h2).
  final String host;

  /// gRPC service name.
  final String serviceName;

  /// XHTTP mode: auto, packet-up, stream-up, stream-one.
  final String mode;

  /// XHTTP `extra` object as raw JSON (padding, xmux, downloadSettings…).
  final String extra;

  /// TCP header obfuscation: `http` disguises the stream as plain HTTP
  /// (`headerType=http`). Only Xray-core implements it.
  final String headerType;

  bool get httpObfs => type == TransportType.tcp && headerType == 'http';

  /// `headerType` from links / configs; anything but `http` means none.
  static String parseHeader(String? s) => s?.trim().toLowerCase() == 'http' ? 'http' : '';

  Map<String, Object?> toJson() => {
    'type': type.name,
    if (path.isNotEmpty) 'path': path,
    if (host.isNotEmpty) 'host': host,
    if (serviceName.isNotEmpty) 'serviceName': serviceName,
    if (mode.isNotEmpty) 'mode': mode,
    if (extra.isNotEmpty) 'extra': extra,
    if (headerType.isNotEmpty) 'header': headerType,
  };

  factory TransportConfig.fromJson(Map<String, Object?> j) => TransportConfig(
    type: TransportType.values.byName(j['type'] as String? ?? 'tcp'),
    path: j['path'] as String? ?? '',
    host: j['host'] as String? ?? '',
    serviceName: j['serviceName'] as String? ?? '',
    mode: j['mode'] as String? ?? '',
    extra: j['extra'] as String? ?? '',
    headerType: j['header'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) =>
      other is TransportConfig &&
      other.type == type &&
      other.path == path &&
      other.host == host &&
      other.serviceName == serviceName &&
      other.mode == mode &&
      other.extra == extra &&
      other.headerType == headerType;

  @override
  int get hashCode => Object.hash(type, path, host, serviceName, mode, extra, headerType);
}

enum TlsMode { none, tls, reality }

class TlsConfig {
  const TlsConfig({
    this.mode = TlsMode.none,
    this.sni = '',
    this.alpn = const [],
    this.fingerprint = '',
    this.insecure = false,
    this.realityPublicKey = '',
    this.realityShortId = '',
    this.realitySpiderX = '',
    this.realityMldsa65Verify = '',
  });

  final TlsMode mode;
  final String sni;
  final List<String> alpn;

  /// uTLS fingerprint (chrome, firefox…); empty disables uTLS.
  final String fingerprint;
  final bool insecure;
  final String realityPublicKey;
  final String realityShortId;

  /// Reality `spx`: the path the client "browses" to look like a real visit.
  final String realitySpiderX;

  /// Reality `pqv`: ML-DSA-65 public key for post-quantum server
  /// verification (newer Xray servers). Only Xray-core supports it.
  final String realityMldsa65Verify;

  bool get enabled => mode != TlsMode.none;

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    if (sni.isNotEmpty) 'sni': sni,
    if (alpn.isNotEmpty) 'alpn': alpn,
    if (fingerprint.isNotEmpty) 'fp': fingerprint,
    if (insecure) 'insecure': true,
    if (realityPublicKey.isNotEmpty) 'pbk': realityPublicKey,
    if (realityShortId.isNotEmpty) 'sid': realityShortId,
    if (realitySpiderX.isNotEmpty) 'spx': realitySpiderX,
    if (realityMldsa65Verify.isNotEmpty) 'pqv': realityMldsa65Verify,
  };

  factory TlsConfig.fromJson(Map<String, Object?> j) => TlsConfig(
    mode: TlsMode.values.byName(j['mode'] as String? ?? 'none'),
    sni: j['sni'] as String? ?? '',
    alpn: (j['alpn'] as List<Object?>? ?? const []).cast<String>(),
    fingerprint: j['fp'] as String? ?? '',
    insecure: j['insecure'] as bool? ?? false,
    realityPublicKey: j['pbk'] as String? ?? '',
    realityShortId: j['sid'] as String? ?? '',
    realitySpiderX: j['spx'] as String? ?? '',
    realityMldsa65Verify: j['pqv'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) =>
      other is TlsConfig &&
      other.mode == mode &&
      other.sni == sni &&
      _listEq(other.alpn, alpn) &&
      other.fingerprint == fingerprint &&
      other.insecure == insecure &&
      other.realityPublicKey == realityPublicKey &&
      other.realityShortId == realityShortId &&
      other.realitySpiderX == realitySpiderX &&
      other.realityMldsa65Verify == realityMldsa65Verify;

  @override
  int get hashCode => Object.hash(
    mode,
    sni,
    Object.hashAll(alpn),
    fingerprint,
    insecure,
    realityPublicKey,
    realityShortId,
    realitySpiderX,
    realityMldsa65Verify,
  );
}

/// Everything needed to build one sing-box outbound (or WireGuard endpoint).
///
/// A flat model rather than a class per protocol: link formats share most
/// fields, and one JSON shape keeps storage and the editor simple. Fields that
/// don't apply to [protocol] are left empty.
class OutboundConfig {
  const OutboundConfig({
    required this.protocol,
    required this.host,
    required this.port,
    this.uuid = '',
    this.password = '',
    this.method = '',
    this.flow = '',
    this.alterId = 0,
    this.vmessSecurity = 'auto',
    this.transport = const TransportConfig(),
    this.tls = const TlsConfig(),
    this.obfsPassword = '',
    this.upMbps = 0,
    this.downMbps = 0,
    this.congestionControl = '',
    this.udpRelayMode = '',
    this.privateKey = '',
    this.peerPublicKey = '',
    this.preSharedKey = '',
    this.localAddresses = const [],
    this.reserved = const [],
    this.mtu = 0,
    this.xrayOutbound = '',
  });

  final ProxyProtocol protocol;
  final String host;
  final int port;

  /// VLESS / VMess / TUIC user id.
  final String uuid;

  /// Trojan / Shadowsocks / Hysteria2 / TUIC password.
  final String password;

  /// Shadowsocks cipher.
  final String method;

  /// VLESS flow, e.g. `xtls-rprx-vision`.
  final String flow;
  final int alterId;
  final String vmessSecurity;
  final TransportConfig transport;
  final TlsConfig tls;

  /// Hysteria2 salamander obfuscation password.
  final String obfsPassword;
  final int upMbps;
  final int downMbps;

  /// TUIC congestion control (bbr, cubic, new_reno).
  final String congestionControl;

  /// TUIC UDP relay mode (native, quic).
  final String udpRelayMode;

  // WireGuard
  final String privateKey;
  final String peerPublicKey;
  final String preSharedKey;
  final List<String> localAddresses;
  final List<int> reserved;
  final int mtu;

  /// Original Xray outbound JSON for servers imported from Xray configs that
  /// use features only Xray-core has. Passed to Xray verbatim so nothing is
  /// lost in translation; empty for everything else.
  final String xrayOutbound;

  /// Runs through Xray-core (behind sing-box) instead of sing-box itself.
  ///
  /// Reality goes to Xray too: Reality servers are Xray servers, and newer
  /// ones use features sing-box's client lacks (post-quantum `pqv`, ML-KEM
  /// key shares), which sing-box reports as "reality verification failed".
  bool get requiresXray =>
      xrayOutbound.isNotEmpty ||
      transport.type == TransportType.xhttp ||
      transport.httpObfs ||
      tls.mode == TlsMode.reality;

  /// Short transport label for the UI.
  String get transportLabel => switch (protocol) {
    ProxyProtocol.hysteria2 || ProxyProtocol.tuic => 'quic',
    ProxyProtocol.wireguard => 'udp',
    ProxyProtocol.shadowsocks => 'tcp',
    _ => transport.type.name,
  };

  String get securityLabel => tls.mode.name;

  OutboundConfig copyWith({
    String? host,
    int? port,
    String? uuid,
    String? password,
    String? method,
    String? flow,
    TransportConfig? transport,
    TlsConfig? tls,
  }) {
    return OutboundConfig(
      protocol: protocol,
      host: host ?? this.host,
      port: port ?? this.port,
      uuid: uuid ?? this.uuid,
      password: password ?? this.password,
      method: method ?? this.method,
      flow: flow ?? this.flow,
      alterId: alterId,
      vmessSecurity: vmessSecurity,
      transport: transport ?? this.transport,
      tls: tls ?? this.tls,
      obfsPassword: obfsPassword,
      upMbps: upMbps,
      downMbps: downMbps,
      congestionControl: congestionControl,
      udpRelayMode: udpRelayMode,
      privateKey: privateKey,
      peerPublicKey: peerPublicKey,
      preSharedKey: preSharedKey,
      localAddresses: localAddresses,
      reserved: reserved,
      mtu: mtu,
      xrayOutbound: xrayOutbound,
    );
  }

  Map<String, Object?> toJson() => {
    'protocol': protocol.name,
    'host': host,
    'port': port,
    if (uuid.isNotEmpty) 'uuid': uuid,
    if (password.isNotEmpty) 'password': password,
    if (method.isNotEmpty) 'method': method,
    if (flow.isNotEmpty) 'flow': flow,
    if (alterId != 0) 'alterId': alterId,
    if (vmessSecurity != 'auto') 'vmessSecurity': vmessSecurity,
    if (transport != const TransportConfig()) 'transport': transport.toJson(),
    if (tls != const TlsConfig()) 'tls': tls.toJson(),
    if (obfsPassword.isNotEmpty) 'obfsPassword': obfsPassword,
    if (upMbps != 0) 'upMbps': upMbps,
    if (downMbps != 0) 'downMbps': downMbps,
    if (congestionControl.isNotEmpty) 'cc': congestionControl,
    if (udpRelayMode.isNotEmpty) 'udpRelayMode': udpRelayMode,
    if (privateKey.isNotEmpty) 'privateKey': privateKey,
    if (peerPublicKey.isNotEmpty) 'peerPublicKey': peerPublicKey,
    if (preSharedKey.isNotEmpty) 'preSharedKey': preSharedKey,
    if (localAddresses.isNotEmpty) 'localAddresses': localAddresses,
    if (reserved.isNotEmpty) 'reserved': reserved,
    if (mtu != 0) 'mtu': mtu,
    if (xrayOutbound.isNotEmpty) 'xray': xrayOutbound,
  };

  factory OutboundConfig.fromJson(Map<String, Object?> j) => OutboundConfig(
    protocol: ProxyProtocol.values.byName(j['protocol']! as String),
    host: j['host']! as String,
    port: j['port']! as int,
    uuid: j['uuid'] as String? ?? '',
    password: j['password'] as String? ?? '',
    method: j['method'] as String? ?? '',
    flow: j['flow'] as String? ?? '',
    alterId: j['alterId'] as int? ?? 0,
    vmessSecurity: j['vmessSecurity'] as String? ?? 'auto',
    transport: j['transport'] == null
        ? const TransportConfig()
        : TransportConfig.fromJson((j['transport']! as Map).cast<String, Object?>()),
    tls: j['tls'] == null
        ? const TlsConfig()
        : TlsConfig.fromJson((j['tls']! as Map).cast<String, Object?>()),
    obfsPassword: j['obfsPassword'] as String? ?? '',
    upMbps: j['upMbps'] as int? ?? 0,
    downMbps: j['downMbps'] as int? ?? 0,
    congestionControl: j['cc'] as String? ?? '',
    udpRelayMode: j['udpRelayMode'] as String? ?? '',
    privateKey: j['privateKey'] as String? ?? '',
    peerPublicKey: j['peerPublicKey'] as String? ?? '',
    preSharedKey: j['preSharedKey'] as String? ?? '',
    localAddresses: (j['localAddresses'] as List<Object?>? ?? const []).cast<String>(),
    reserved: (j['reserved'] as List<Object?>? ?? const []).cast<int>(),
    mtu: j['mtu'] as int? ?? 0,
    xrayOutbound: j['xray'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) => other is OutboundConfig && _mapEq(other.toJson(), toJson());

  @override
  int get hashCode => Object.hashAll(toJson().entries.map((e) => Object.hash(e.key, '${e.value}')));
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEq(Map<String, Object?> a, Map<String, Object?> b) {
  if (a.length != b.length) return false;
  for (final k in a.keys) {
    if ('${a[k]}' != '${b[k]}') return false;
  }
  return true;
}
