import 'dart:convert';

import 'package:aurora_vpn/data/parsers/import_item.dart';
import 'package:aurora_vpn/data/parsers/subscription_parser.dart';
import 'package:aurora_vpn/domain/servers/server_profile.dart';
import 'package:flutter_test/flutter_test.dart';

// Synthetic fixtures modelled on real panel output.
const uuid = '2b7f3c1d-8e9a-4b0c-9d1e-3f4a5b6c7d8e';

final linkList = [
  'vless://$uuid@nl.example.com:443?security=reality&pbk=cHViS2V5&sid=01&sni=www.example.org&fp=chrome&flow=xtls-rprx-vision#NL',
  'trojan://pw@de.example.com:443?type=ws&path=%2Ft#DE',
  'hysteria2://pw@fi.example.com:443?sni=fi.example.com#FI',
  'vless://$uuid@bad.example.com:443?type=xhttp&security=tls#Broken',
].join('\r\n');

const singBoxJson =
    '''
{
  "log": {"level": "info"},
  "outbounds": [
    {"type": "selector", "tag": "select", "outbounds": ["vless-out", "ss-out"]},
    {"type": "vless", "tag": "vless-out", "server": "v.example.com", "server_port": 443,
     "uuid": "$uuid", "flow": "xtls-rprx-vision",
     "tls": {"enabled": true, "server_name": "www.example.org",
             "utls": {"enabled": true, "fingerprint": "firefox"},
             "reality": {"enabled": true, "public_key": "cHViS2V5", "short_id": "ab"}}},
    {"type": "vmess", "tag": "vmess-ws", "server": "m.example.com", "server_port": 8443,
     "uuid": "$uuid", "security": "auto",
     "transport": {"type": "ws", "path": "/vm", "headers": {"Host": "cdn.example.com"}},
     "tls": {"enabled": true}},
    {"type": "shadowsocks", "tag": "ss-out", "server": "s.example.com", "server_port": 8388,
     "method": "2022-blake3-aes-128-gcm", "password": "a2V5"},
    {"type": "tuic", "tag": "tuic-out", "server": "t.example.com", "server_port": 443,
     "uuid": "$uuid", "password": "pw", "congestion_control": "bbr",
     "tls": {"enabled": true, "alpn": ["h3"]}},
    {"type": "direct", "tag": "direct"}
  ],
  "endpoints": [
    {"type": "wireguard", "tag": "wg-ep", "address": ["10.0.0.2/32"], "private_key": "cHJpdg==",
     "peers": [{"address": "w.example.com", "port": 51820, "public_key": "cHVi",
                "allowed_ips": ["0.0.0.0/0"], "reserved": [0, 1, 2]}]}
  ]
}
''';

const clashYaml =
    '''
mixed-port: 7890
proxies:
  - name: "VLESS Reality"
    type: vless
    server: r.example.com
    port: 443
    uuid: $uuid
    network: tcp
    tls: true
    flow: xtls-rprx-vision
    servername: www.example.org
    client-fingerprint: chrome
    reality-opts:
      public-key: cHViS2V5
      short-id: abcd
  - name: VMess gRPC
    type: vmess
    server: g.example.com
    port: 443
    uuid: $uuid
    alterId: 0
    cipher: auto
    tls: true
    network: grpc
    grpc-opts:
      grpc-service-name: svc
  - {name: SS, type: ss, server: s.example.com, port: 8388, cipher: aes-256-gcm, password: pw}
  - name: Trojan WS
    type: trojan
    server: t.example.com
    port: 443
    password: pw
    network: ws
    sni: t.example.com
    ws-opts:
      path: /tr
      headers:
        Host: cdn.example.com
  - name: HY2
    type: hysteria2
    server: h.example.com
    port: 443
    password: pw
    obfs: salamander
    obfs-password: ob
    up: "50 Mbps"
    down: 200
  - name: Snell
    type: snell
    server: x.example.com
    port: 443
proxy-groups:
  - {name: Auto, type: url-test, proxies: [SS]}
''';

void main() {
  test('plain link list (CRLF) collects servers and reports bad lines', () {
    final r = SubscriptionParser.parse(linkList);
    expect(r.servers.map((s) => s.name), ['NL', 'DE', 'FI']);
    expect(r.failures, hasLength(1));
    expect(r.failures.single.reason, contains('xhttp'));
  });

  test('base64-encoded link list, with line breaks inside the base64', () {
    final b64 = base64.encode(utf8.encode(linkList));
    final wrapped = [
      for (var i = 0; i < b64.length; i += 76) b64.substring(i, (i + 76).clamp(0, b64.length)),
    ].join('\n');
    final r = SubscriptionParser.parse(wrapped);
    expect(r.servers, hasLength(3));
  });

  test('sing-box JSON: skips groups/direct, reads endpoints', () {
    final r = SubscriptionParser.parse(singBoxJson);
    final byName = {for (final s in r.servers) s.name: s.outbound};
    expect(byName.keys, ['vless-out', 'vmess-ws', 'ss-out', 'tuic-out', 'wg-ep']);

    final v = byName['vless-out']!;
    expect(v.tls.mode, TlsMode.reality);
    expect(v.tls.fingerprint, 'firefox');
    expect(v.tls.realityShortId, 'ab');

    final m = byName['vmess-ws']!;
    expect(
      m.transport,
      const TransportConfig(type: TransportType.ws, path: '/vm', host: 'cdn.example.com'),
    );

    expect(byName['tuic-out']!.congestionControl, 'bbr');

    final wg = byName['wg-ep']!;
    expect(wg.protocol, ProxyProtocol.wireguard);
    expect(wg.host, 'w.example.com');
    expect(wg.reserved, [0, 1, 2]);
  });

  test('Clash YAML: maps proxies, rejects unsupported types', () {
    final r = SubscriptionParser.parse(clashYaml);
    final byName = {for (final s in r.servers) s.name: s.outbound};
    expect(byName.keys, ['VLESS Reality', 'VMess gRPC', 'SS', 'Trojan WS', 'HY2']);
    expect(r.failures.single.reason, contains('snell'));

    expect(byName['VLESS Reality']!.tls.mode, TlsMode.reality);
    expect(byName['VLESS Reality']!.tls.realityPublicKey, 'cHViS2V5');
    expect(byName['VMess gRPC']!.transport.serviceName, 'svc');
    expect(byName['SS']!.method, 'aes-256-gcm');
    expect(byName['Trojan WS']!.transport.host, 'cdn.example.com');
    expect(byName['Trojan WS']!.tls.mode, TlsMode.tls);
    final hy = byName['HY2']!;
    expect(hy.obfsPassword, 'ob');
    expect(hy.upMbps, 50);
    expect(hy.downMbps, 200);
  });

  test('a bare URL is a subscription; unrelated text yields nothing', () {
    final r = SubscriptionParser.parse('  https://sub.example.com/link/abc?flag=1  ');
    expect(r.subscriptions.single.url, 'https://sub.example.com/link/abc?flag=1');
    expect(SubscriptionParser.parse('hello world').isEmpty, isTrue);
    expect(SubscriptionParser.parse('').isEmpty, isTrue);
  });

  group('headers', () {
    test('userinfo, interval, base64 title, support url', () {
      final m = SubscriptionMeta.fromHeaders({
        'subscription-userinfo': 'upload=1024; download=2048; total=10737418240; expire=1798761600',
        'profile-update-interval': '24',
        'profile-title': 'base64:${base64.encode(utf8.encode('Мой VPN'))}',
        'support-url': 'https://t.example.com/support',
      });
      expect(m.title, 'Мой VPN');
      expect(m.updateInterval, const Duration(hours: 24));
      expect(m.usage!.used, 3072);
      expect(m.usage!.total, 10737418240);
      expect(m.usage!.expire, DateTime.fromMillisecondsSinceEpoch(1798761600000, isUtc: true));
      expect(m.supportUrl, 'https://t.example.com/support');
    });

    test('content-disposition fallback and missing values', () {
      final m = SubscriptionMeta.fromHeaders({
        'content-disposition': "attachment; filename*=UTF-8''My%20Sub",
        'subscription-userinfo': 'upload=0; download=0; total=0; expire=0',
      });
      expect(m.title, 'My Sub');
      expect(m.usage!.unlimited, isTrue);
      expect(m.usage!.expire, isNull);
      expect(m.updateInterval, isNull);
    });
  });

  test('tryDecodeBase64 is lenient but rejects non-base64', () {
    expect(tryDecodeBase64('aGVsbG8'), 'hello');
    expect(tryDecodeBase64('aGVs\nbG8='), 'hello');
    expect(tryDecodeBase64('not base64!'), isNull);
  });
}
