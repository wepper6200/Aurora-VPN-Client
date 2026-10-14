import 'dart:convert';

import 'package:aurora_vpn/data/parsers/clash_yaml_parser.dart';
import 'package:aurora_vpn/data/parsers/import_item.dart';
import 'package:aurora_vpn/data/parsers/link_parser.dart';
import 'package:aurora_vpn/data/parsers/link_serializer.dart';
import 'package:aurora_vpn/data/singbox/config_builder.dart';
import 'package:aurora_vpn/data/xray/xray_config_builder.dart';
import 'package:aurora_vpn/domain/servers/server_profile.dart';
import 'package:flutter_test/flutter_test.dart';

// Synthetic values only.
const uuid = '3c0f7a52-9a1e-4c5b-8f2d-6e7a8b9c0d1e';

ServerItem server(String link) => LinkParser.parse(link) as ServerItem;

void main() {
  group('TCP with HTTP header obfuscation', () {
    test('VLESS headerType=http is kept and routed through Xray', () {
      final s = server(
        'vless://$uuid@t.example.com:80?type=tcp&headerType=http&host=cdn.example.com&path=%2Fv',
      );
      final t = s.outbound.transport;
      expect(t.type, TransportType.tcp);
      expect(t.httpObfs, isTrue);
      expect(t.host, 'cdn.example.com');
      expect(s.outbound.requiresXray, isTrue);
    });

    test('plain TCP stays on sing-box', () {
      final s = server('vless://$uuid@t.example.com:443?type=tcp&headerType=none&security=tls');
      expect(s.outbound.transport.httpObfs, isFalse);
      expect(s.outbound.requiresXray, isFalse);
    });

    test('VMess JSON `type: http` is the TCP header', () {
      final json = {
        'v': '2',
        'ps': 'obfs',
        'add': 'm.example.com',
        'port': '8080',
        'id': uuid,
        'net': 'tcp',
        'type': 'http',
        'host': 'cdn.example.com',
        'path': '/',
      };
      final s = server('vmess://${base64.encode(utf8.encode(jsonEncode(json)))}');
      expect(s.outbound.transport.httpObfs, isTrue);
      expect(s.outbound.requiresXray, isTrue);
    });

    test('Clash `network: http` is TCP obfuscation, not HTTP/2', () {
      final items = ClashYamlParser.parse({
        'proxies': [
          {
            'name': 'obfs',
            'type': 'vmess',
            'server': 'm.example.com',
            'port': 8080,
            'uuid': uuid,
            'alterId': 0,
            'cipher': 'auto',
            'network': 'http',
            'http-opts': {
              'path': ['/a'],
              'headers': {
                'Host': ['cdn.example.com'],
              },
            },
          },
        ],
      });
      final t = items.servers.single.outbound.transport;
      expect(t.type, TransportType.tcp);
      expect(t.httpObfs, isTrue);
      expect(t.path, '/a');
      expect(t.host, 'cdn.example.com');
    });

    test('Xray gets a raw HTTP header', () {
      final s = server(
        'vless://$uuid@t.example.com:80?type=tcp&headerType=http&host=cdn.example.com&path=%2Fv',
      );
      final out = XrayConfigBuilder.outbound(s.outbound);
      final stream = out['streamSettings']! as Map;
      expect(stream['network'], 'raw');
      expect(stream['rawSettings'], {
        'header': {
          'type': 'http',
          'request': {
            'path': ['/v'],
            'headers': {
              'Host': ['cdn.example.com'],
            },
          },
        },
      });
    });

    test('share links keep the header', () {
      final s = server('vless://$uuid@t.example.com:80?type=tcp&headerType=http&host=h.example.com');
      final again = server(LinkSerializer.toLink(s.name, s.outbound));
      expect(again.outbound.transport.httpObfs, isTrue);
    });

    test('Reality keeps spx / pqv and runs on Xray', () {
      final s = server(
        'vless://$uuid@r.example.com:443?type=tcp&security=reality&sni=www.example.org'
        '&pbk=pk&sid=ab&spx=%2Fsearch&pqv=mldsa&flow=xtls-rprx-vision',
      );
      expect(s.outbound.requiresXray, isTrue);
      final stream = XrayConfigBuilder.outbound(s.outbound)['streamSettings']! as Map;
      expect(stream['realitySettings'], {
        'serverName': 'www.example.org',
        'fingerprint': 'chrome',
        'publicKey': 'pk',
        'shortId': 'ab',
        'spiderX': '/search',
        'mldsa65Verify': 'mldsa',
      });
      final again = server(LinkSerializer.toLink(s.name, s.outbound));
      expect(again.outbound.tls.realityMldsa65Verify, 'mldsa');
    });

    test('sing-box config sends obfuscated TCP through the Xray bridge', () {
      final s = server('vless://$uuid@t.example.com:80?type=tcp&headerType=http');
      expect(
        () => SingBoxConfigBuilder.outbound(s.outbound),
        returnsNormally,
        reason: 'the sing-box outbound itself is never used for it',
      );
      expect(s.outbound.requiresXray, isTrue);
    });
  });
}
