import 'dart:convert';

import 'package:aurora_vpn/data/parsers/import_item.dart';
import 'package:aurora_vpn/data/parsers/link_parser.dart';
import 'package:aurora_vpn/data/parsers/link_serializer.dart';
import 'package:aurora_vpn/domain/servers/server_profile.dart';
import 'package:flutter_test/flutter_test.dart';

// All values below are synthetic.
const uuid = '9f1c2b3a-4d5e-4f60-8a7b-1c2d3e4f5a6b';
const pbk = 'SbVKOEMjK0sIlbwg4akyBg5mL5KZwwB-ed4eEE7YnRc';

ServerItem server(String link) => LinkParser.parse(link) as ServerItem;

void main() {
  group('vless', () {
    test('reality + tcp + vision', () {
      final s = server(
        'vless://$uuid@203.0.113.10:443?encryption=none&flow=xtls-rprx-vision&security=reality'
        '&sni=www.example.com&fp=chrome&pbk=$pbk&sid=6ba85179e30d4fc2&type=tcp'
        '#%F0%9F%87%A9%F0%9F%87%AA%20Frankfurt',
      );
      final o = s.outbound;
      expect(s.name, '🇩🇪 Frankfurt');
      expect(o.protocol, ProxyProtocol.vless);
      expect(o.host, '203.0.113.10');
      expect(o.port, 443);
      expect(o.uuid, uuid);
      expect(o.flow, 'xtls-rprx-vision');
      expect(o.transport.type, TransportType.tcp);
      expect(o.tls.mode, TlsMode.reality);
      expect(o.tls.sni, 'www.example.com');
      expect(o.tls.fingerprint, 'chrome');
      expect(o.tls.realityPublicKey, pbk);
      expect(o.tls.realityShortId, '6ba85179e30d4fc2');
    });

    test('ws + tls with host header and encoded path', () {
      final o = server(
        'vless://$uuid@cdn.example.com:443?security=tls&type=ws&host=edge.example.com'
        '&path=%2Fws%3Fed%3D2048&sni=edge.example.com&alpn=h2,http/1.1#WS',
      ).outbound;
      expect(
        o.transport,
        const TransportConfig(
          type: TransportType.ws,
          path: '/ws?ed=2048',
          host: 'edge.example.com',
        ),
      );
      expect(o.tls.alpn, ['h2', 'http/1.1']);
    });

    test('grpc service name', () {
      final o = server(
        'vless://$uuid@g.example.com:443?security=tls&type=grpc&serviceName=tun-svc#g',
      ).outbound;
      expect(o.transport.type, TransportType.grpc);
      expect(o.transport.serviceName, 'tun-svc');
    });

    test('h2 and httpupgrade', () {
      expect(
        server('vless://$uuid@h.example.com:443?security=tls&type=http&path=/h2&host=a.example.com')
            .outbound
            .transport
            .type,
        TransportType.h2,
      );
      final hu = server(
        'vless://$uuid@h.example.com:80?type=httpupgrade&path=/up&host=b.example.com',
      ).outbound;
      expect(hu.transport.type, TransportType.httpupgrade);
      expect(hu.tls.mode, TlsMode.none);
    });

    test('ipv6 host in brackets; name falls back to host', () {
      final s = server('vless://$uuid@[2001:db8::1]:8443?security=none');
      expect(s.outbound.host, '2001:db8::1');
      expect(s.outbound.port, 8443);
      expect(s.name, '2001:db8::1');
    });

    test('plus sign in path is kept literally', () {
      final o = server('vless://$uuid@a.example.com:443?type=ws&path=/a+b&security=tls').outbound;
      expect(o.transport.path, '/a+b');
    });

    test('unsupported transport and missing reality key are rejected', () {
      expect(
        () => LinkParser.parse('vless://$uuid@a.example.com:443?type=xhttp&security=tls'),
        throwsA(isA<LinkParseException>().having((e) => e.reason, 'reason', contains('xhttp'))),
      );
      expect(
        () => LinkParser.parse('vless://$uuid@a.example.com:443?security=reality'),
        throwsA(isA<LinkParseException>()),
      );
    });
  });

  group('vmess', () {
    String vmess(Map<String, Object> j) => 'vmess://${base64.encode(utf8.encode(jsonEncode(j)))}';

    test('ws + tls from base64 JSON', () {
      final s = server(
        vmess({
          'v': '2',
          'ps': 'Istanbul',
          'add': 'tr.example.net',
          'port': '2053',
          'id': uuid,
          'aid': '0',
          'scy': 'auto',
          'net': 'ws',
          'type': 'none',
          'host': 'cdn.example.net',
          'path': '/vm',
          'tls': 'tls',
          'sni': 'cdn.example.net',
        }),
      );
      expect(s.name, 'Istanbul');
      final o = s.outbound;
      expect(o.port, 2053);
      expect(
        o.transport,
        const TransportConfig(type: TransportType.ws, path: '/vm', host: 'cdn.example.net'),
      );
      expect(o.tls.mode, TlsMode.tls);
      expect(o.tls.sni, 'cdn.example.net');
    });

    test('grpc service name travels in path; numeric port; no tls', () {
      final o = server(
        vmess({
          'add': 'g.example.net',
          'port': 443,
          'id': uuid,
          'net': 'grpc',
          'path': 'svc',
          'tls': '',
        }),
      ).outbound;
      expect(o.transport.type, TransportType.grpc);
      expect(o.transport.serviceName, 'svc');
      expect(o.transport.path, '');
      expect(o.tls.mode, TlsMode.none);
    });

    test('url-safe base64 without padding', () {
      final raw = base64Url.encode(
        utf8.encode(jsonEncode({'add': 'u.example.net', 'port': '80', 'id': uuid})),
      );
      final o = server('vmess://${raw.replaceAll('=', '')}').outbound;
      expect(o.host, 'u.example.net');
    });

    test('garbage payload', () {
      expect(() => LinkParser.parse('vmess://not-base64!!'), throwsA(isA<LinkParseException>()));
    });
  });

  group('trojan', () {
    test('defaults to TLS; password with special characters', () {
      final s = server(
        'trojan://p%40ss%3Aw0rd@t.example.org:443?sni=t.example.org&type=ws&path=/tr#Trojan%20WS',
      );
      expect(s.name, 'Trojan WS');
      expect(s.outbound.password, 'p@ss:w0rd');
      expect(s.outbound.tls.mode, TlsMode.tls);
      expect(s.outbound.transport.type, TransportType.ws);
    });
  });

  group('shadowsocks', () {
    test('SIP002 base64 userinfo', () {
      final ui = base64Url.encode(utf8.encode('chacha20-ietf-poly1305:pa55')).replaceAll('=', '');
      final s = server('ss://$ui@ss.example.com:8388#SS');
      expect(s.outbound.method, 'chacha20-ietf-poly1305');
      expect(s.outbound.password, 'pa55');
      expect(s.outbound.port, 8388);
    });

    test('SIP022 percent-encoded 2022 cipher', () {
      final o = server('ss://2022-blake3-aes-256-gcm:YWJjZGVm%2BZ2hp%3D@ss.example.com:443#2022')
          .outbound;
      expect(o.method, '2022-blake3-aes-256-gcm');
      expect(o.password, 'YWJjZGVm+Z2hp=');
    });

    test('legacy fully-encoded form', () {
      final body = base64.encode(utf8.encode('aes-256-gcm:secret@legacy.example.com:8000'));
      final s = server('ss://$body#Legacy');
      expect(s.outbound.host, 'legacy.example.com');
      expect(s.outbound.port, 8000);
      expect(s.outbound.method, 'aes-256-gcm');
    });

    test('plugins are reported as unsupported', () {
      expect(
        () => LinkParser.parse(
          'ss://YWVzLTI1Ni1nY206cHc@p.example.com:443/?plugin=obfs-local%3Bobfs%3Dhttp#P',
        ),
        throwsA(isA<LinkParseException>()),
      );
    });
  });

  group('hysteria2', () {
    test('hy2 alias, obfs, insecure and port hopping', () {
      final o = server(
        'hy2://letmein@h2.example.com:443,20000-30000/?sni=h2.example.com&insecure=1'
        '&obfs=salamander&obfs-password=ob5#HY2',
      ).outbound;
      expect(o.protocol, ProxyProtocol.hysteria2);
      expect(o.port, 443);
      expect(o.password, 'letmein');
      expect(o.obfsPassword, 'ob5');
      expect(o.tls.insecure, isTrue);
      expect(o.tls.mode, TlsMode.tls);
    });
  });

  group('tuic', () {
    test('uuid:password with congestion control', () {
      final o = server(
        'tuic://$uuid:tp4ss@tuic.example.com:443?congestion_control=bbr&udp_relay_mode=native&alpn=h3&sni=tuic.example.com#T',
      ).outbound;
      expect(o.uuid, uuid);
      expect(o.password, 'tp4ss');
      expect(o.congestionControl, 'bbr');
      expect(o.udpRelayMode, 'native');
      expect(o.tls.alpn, ['h3']);
    });
  });

  group('wireguard', () {
    test('keys, addresses and reserved bytes', () {
      final o = server(
        'wireguard://cHJpdmF0ZWtleQ%3D%3D@wg.example.com:51820?publickey=cHVibGlja2V5&address=10.0.0.2,fd00::2'
        '&reserved=1,2,3&mtu=1280#WG',
      ).outbound;
      expect(o.privateKey, 'cHJpdmF0ZWtleQ==');
      expect(o.peerPublicKey, 'cHVibGlja2V5');
      expect(o.localAddresses, ['10.0.0.2/32', 'fd00::2/128']);
      expect(o.reserved, [1, 2, 3]);
      expect(o.mtu, 1280);
    });
  });

  group('happ', () {
    test('happ://add/ yields a subscription', () {
      final item = LinkParser.parse('happ://add/https%3A%2F%2Fsub.example.com%2Fs%2Fabc');
      expect(item, isA<SubscriptionItem>());
      expect((item as SubscriptionItem).url, 'https://sub.example.com/s/abc');
    });

    test('encrypted happ links are not supported', () {
      expect(() => LinkParser.parse('happ://crypt2/AAAA'), throwsA(isA<LinkParseException>()));
    });
  });

  test('invalid ports and missing parts', () {
    for (final bad in [
      'vless://$uuid@a.example.com:0',
      'vless://$uuid@a.example.com:70000',
      'vless://$uuid@a.example.com',
      'trojan://@a.example.com:443',
    ]) {
      expect(() => LinkParser.parse(bad), throwsA(isA<LinkParseException>()), reason: bad);
    }
  });

  group('share link round-trip', () {
    final samples = [
      'vless://$uuid@203.0.113.10:443?flow=xtls-rprx-vision&security=reality&sni=www.example.com&fp=chrome&pbk=$pbk&sid=ab12#R',
      'vless://$uuid@a.example.com:443?security=tls&type=grpc&serviceName=svc#G',
      'trojan://pw@t.example.org:443?type=ws&path=%2Fws&host=x.example.org#T',
      'ss://${base64Url.encode(utf8.encode('aes-128-gcm:pw')).replaceAll('=', '')}@s.example.com:8388#S',
      'ss://2022-blake3-aes-128-gcm:a2V5%2B%3D@s.example.com:443#S2',
      'hysteria2://pw@h.example.com:443/?sni=h.example.com&obfs=salamander&obfs-password=o#H',
      'tuic://$uuid:pw@t.example.com:443?congestion_control=cubic&alpn=h3#U',
      'wireguard://cHJpdg%3D%3D@w.example.com:51820?publickey=cHVi&address=10.0.0.2%2F32#W',
      'vmess://${base64.encode(utf8.encode(jsonEncode({'ps': 'V', 'add': 'v.example.com', 'port': '443', 'id': uuid, 'net': 'ws', 'path': '/v', 'tls': 'tls'})))}',
    ];
    for (final link in samples) {
      test(link.substring(0, link.indexOf('://')), () {
        final first = server(link);
        final again = server(LinkSerializer.toLink(first.name, first.outbound));
        expect(again.name, first.name);
        expect(again.outbound, first.outbound);
      });
    }
  });
}
