import 'dart:convert';

import 'package:aurora_vpn/data/parsers/import_item.dart';
import 'package:aurora_vpn/data/parsers/link_parser.dart';
import 'package:aurora_vpn/data/parsers/link_serializer.dart';
import 'package:aurora_vpn/data/parsers/subscription_parser.dart';
import 'package:aurora_vpn/data/singbox/config_builder.dart';
import 'package:aurora_vpn/data/subscriptions/subscription_fetcher.dart';
import 'package:aurora_vpn/data/xray/xray_config_builder.dart';
import 'package:aurora_vpn/domain/routing/routing_settings.dart';
import 'package:aurora_vpn/domain/servers/server_profile.dart';
import 'package:aurora_vpn/domain/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Synthetic values only.
const uuid = '3c0f7a52-9a1e-4c5b-8f2d-6e7a8b9c0d1e';

Map<String, Object?> xrayConfig(String remarks, Map<String, Object?> proxy) => {
  'remarks': remarks,
  'dns': {
    'tag': 'dns-in',
    'servers': ['8.8.8.8'],
  },
  'inbounds': [
    {'protocol': 'socks', 'port': 10808},
  ],
  'outbounds': [
    {'tag': 'proxy', ...proxy},
    {'tag': 'direct', 'protocol': 'freedom'},
    {'tag': 'block', 'protocol': 'blackhole'},
  ],
};

Map<String, Object?> vless({
  String host = 'x.example.com',
  int port = 443,
  Map<String, Object?> stream = const {'network': 'tcp'},
  String flow = '',
}) => {
  'protocol': 'vless',
  'settings': {
    'vnext': [
      {
        'address': host,
        'port': port,
        'users': [
          {'id': uuid, 'encryption': 'none', 'flow': flow},
        ],
      },
    ],
  },
  'streamSettings': stream,
};

void main() {
  group('Xray JSON subscriptions', () {
    test('array of configs: reality → model, xhttp → Xray with outbound kept', () {
      final body = jsonEncode([
        xrayConfig(
          '🇩🇪 Reality',
          vless(
            flow: 'xtls-rprx-vision',
            stream: {
              'network': 'tcp',
              'security': 'reality',
              'realitySettings': {
                'serverName': 'www.example.org',
                'fingerprint': 'chrome',
                'password': 'cHViS2V5',
                'shortId': 'ab',
              },
            },
          ),
        ),
        xrayConfig(
          '🇳🇱 XHTTP',
          vless(
            stream: {
              'network': 'xhttp',
              'security': 'tls',
              'tlsSettings': {'serverName': 'cdn.example.com', 'fingerprint': 'chrome'},
              'xhttpSettings': {
                'path': '/x',
                'mode': 'packet-up',
                'extra': {'xPaddingBytes': '100-1000'},
              },
            },
          ),
        ),
      ]);

      final r = SubscriptionParser.parse(body);
      expect(r.servers.map((s) => s.name), ['🇩🇪 Reality', '🇳🇱 XHTTP']);

      final reality = r.servers[0].outbound;
      // Mapped onto the model (no raw outbound kept), and run on Xray like
      // every Reality server.
      expect(reality.xrayOutbound, isEmpty);
      expect(reality.requiresXray, isTrue);
      expect(reality.tls.mode, TlsMode.reality);
      expect(reality.tls.realityPublicKey, 'cHViS2V5');
      expect(reality.flow, 'xtls-rprx-vision');

      final xhttp = r.servers[1].outbound;
      expect(xhttp.requiresXray, isTrue);
      expect(xhttp.transport.type, TransportType.xhttp);
      expect(xhttp.transport.mode, 'packet-up');
      final kept = (jsonDecode(xhttp.xrayOutbound) as Map)['outbounds'] as List;
      expect(kept.single, containsPair('tag', 'proxy'));
      // Xray-only settings survive verbatim.
      expect((((kept.single as Map)['streamSettings'] as Map)['xhttpSettings'] as Map)['extra'], {
        'xPaddingBytes': '100-1000',
      });
    });

    test('flattened settings, mux and dialerProxy chains go to Xray with the chain', () {
      final config = xrayConfig('Chained', {
        'protocol': 'trojan',
        'settings': {'address': 't.example.com', 'port': 443, 'password': 'pw'},
        'mux': {'enabled': true},
        'streamSettings': {
          'network': 'ws',
          'security': 'tls',
          'wsSettings': {'path': '/ws'},
          'sockopt': {'dialerProxy': 'frag'},
        },
      });
      (config['outbounds']! as List).add({
        'tag': 'frag',
        'protocol': 'freedom',
        'settings': {
          'fragment': {'packets': 'tlshello', 'length': '100-200'},
        },
      });
      final s = SubscriptionParser.parse(jsonEncode(config)).servers.single.outbound;
      expect(s.protocol, ProxyProtocol.trojan);
      expect(s.host, 't.example.com');
      expect(s.requiresXray, isTrue);
      final tags = [
        for (final o in (jsonDecode(s.xrayOutbound) as Map)['outbounds'] as List) (o as Map)['tag'],
      ];
      expect(tags, ['proxy', 'frag']);
    });

    test('VLESS post-quantum encryption needs Xray', () {
      final o = vless();
      (((o['settings']! as Map)['vnext'] as List).first['users'] as List).first['encryption'] =
          'mlkem768x25519plus.native.0rtt.AAAA';
      final s = SubscriptionParser.parse(jsonEncode([xrayConfig('PQ', o)])).servers.single.outbound;
      expect(s.requiresXray, isTrue);
    });

    test('sing-box JSON is still told apart from Xray JSON', () {
      final r = SubscriptionParser.parse(
        jsonEncode({
          'outbounds': [
            {
              'type': 'trojan',
              'tag': 't',
              'server': 's.example.com',
              'server_port': 443,
              'password': 'p',
            },
          ],
        }),
      );
      expect(r.servers.single.outbound.requiresXray, isFalse);
    });
  });

  group('provider placeholders', () {
    Future<SubscriptionFetchException> fetchError(String body, {String type = 'text/plain'}) async {
      final f = SubscriptionFetcher(
        userAgent: 't',
        client: MockClient(
          (_) async => http.Response.bytes(utf8.encode(body), 200, headers: {'content-type': type}),
        ),
      );
      try {
        await f.fetch('https://sub.example.com/s/x');
      } on SubscriptionFetchException catch (e) {
        return e;
      }
      fail('expected an error');
    }

    test('"client not supported" stub (Xray JSON, port 1) is reported as such', () async {
      final e = await fetchError(
        jsonEncode([xrayConfig('Клиент не поддерживается', vless(port: 1))]),
      );
      expect(e.code, SubscriptionError.clientNotSupported);
      expect(e.detail, 'Клиент не поддерживается');
    });

    test('stub link list at 0.0.0.0', () async {
      const link = 'vless://$uuid@0.0.0.0:443?security=none#Update%20your%20app';
      final e = await fetchError(base64.encode(utf8.encode(link)));
      expect(e.code, SubscriptionError.clientNotSupported);
      expect(e.detail, 'Update your app');
    });

    test('a web page is not a subscription', () async {
      final e = await fetchError('<!DOCTYPE html><html><body>Hi</body></html>', type: 'text/html');
      expect(e.code, SubscriptionError.htmlPage);
    });

    test('unknown text', () async {
      expect((await fetchError('hello')).code, SubscriptionError.unsupportedFormat);
    });

    test('a real server next to a stub is fine', () {
      final r = SubscriptionParser.parse(
        jsonEncode([xrayConfig('stub', vless(port: 1)), xrayConfig('real', vless())]),
      );
      expect(r.servers.where((s) => !SubscriptionFetcher.isPlaceholder(s.outbound)), hasLength(1));
    });
  });

  group('XHTTP share links', () {
    test('mode and extra are parsed and round-trip', () {
      final extra = Uri.encodeComponent('{"xPaddingBytes":"100-1000"}');
      final link =
          'vless://$uuid@x.example.com:443?type=xhttp&path=%2Fx&host=cdn.example.com&mode=stream-up'
          '&extra=$extra&security=tls&sni=cdn.example.com&fp=chrome#XH';
      final s = LinkParser.parse(link) as ServerItem;
      expect(s.outbound.transport.type, TransportType.xhttp);
      expect(s.outbound.transport.mode, 'stream-up');
      expect(jsonDecode(s.outbound.transport.extra), {'xPaddingBytes': '100-1000'});
      expect(s.outbound.requiresXray, isTrue);
      final again = LinkParser.parse(LinkSerializer.toLink(s.name, s.outbound)) as ServerItem;
      expect(again.outbound, s.outbound);
    });

    test('broken extra is rejected', () {
      expect(
        () => LinkParser.parse('vless://$uuid@x.example.com:443?type=xhttp&extra=%7Bnope'),
        throwsA(isA<LinkParseException>()),
      );
    });
  });

  group('hybrid config', () {
    const bridge = XrayBridge(port: 23456, username: 'u', password: 'p');
    const xhttpServer = OutboundConfig(
      protocol: ProxyProtocol.vless,
      host: 'x.example.com',
      port: 443,
      uuid: uuid,
      transport: TransportConfig(type: TransportType.xhttp, path: '/x', mode: 'auto'),
      tls: TlsConfig(
        mode: TlsMode.reality,
        sni: 'www.example.org',
        realityPublicKey: 'pk',
        realityShortId: 'ab',
      ),
    );

    test('sing-box forwards to the authenticated SOCKS bridge and excludes itself on Android', () {
      final c = SingBoxConfigBuilder.build(
        server: const ServerProfile(id: 'x', name: 'x', outbound: xhttpServer),
        routing: const RoutingSettings(),
        settings: const AppSettings(),
        options: const CoreOptions(
          capture: CaptureMode.tun,
          ruleSetDir: '/r',
          android: true,
          xray: bridge,
          selfPackage: 'dev.aurora.aurora_vpn',
        ),
      );
      final proxy = (c['outbounds']! as List).first as Map;
      expect(proxy, {
        'type': 'socks',
        'tag': 'proxy',
        'server': '127.0.0.1',
        'server_port': 23456,
        'version': '5',
        'username': 'u',
        'password': 'p',
      });
      final tun = (c['inbounds']! as List).single as Map;
      expect(tun['exclude_package'], ['dev.aurora.aurora_vpn']);
    });

    test('Windows TUN routes the Xray process direct', () {
      final c = SingBoxConfigBuilder.build(
        server: const ServerProfile(id: 'x', name: 'x', outbound: xhttpServer),
        routing: const RoutingSettings(),
        settings: const AppSettings(),
        options: const CoreOptions(capture: CaptureMode.tun, ruleSetDir: '/r', xray: bridge),
      );
      final rules = ((c['route']! as Map)['rules']! as List).cast<Map<String, Object?>>();
      expect(
        rules,
        anyElement(
          equals({
            'process_name': ['xray.exe'],
            'outbound': 'direct',
          }),
        ),
      );
    });

    test('without a bridge the builder refuses', () {
      expect(
        () => SingBoxConfigBuilder.build(
          server: const ServerProfile(id: 'x', name: 'x', outbound: xhttpServer),
          routing: const RoutingSettings(),
          settings: const AppSettings(),
          options: const CoreOptions(capture: CaptureMode.tun, ruleSetDir: '/r'),
        ),
        throwsArgumentError,
      );
    });

    test('Xray config: password-protected SOCKS inbound + generated outbound', () {
      final x = XrayConfigBuilder.build(server: xhttpServer, bridge: bridge);
      final inbound = (x['inbounds']! as List).single as Map;
      expect(inbound['listen'], '127.0.0.1');
      expect(inbound['port'], 23456);
      expect((inbound['settings'] as Map)['auth'], 'password');
      final out = (x['outbounds']! as List).first as Map;
      final stream = out['streamSettings'] as Map;
      expect(stream['network'], 'xhttp');
      expect(stream['security'], 'reality');
      expect(stream['realitySettings'], {
        'serverName': 'www.example.org',
        'fingerprint': 'chrome',
        'publicKey': 'pk',
        'shortId': 'ab',
      });
      expect(stream['xhttpSettings'], {'path': '/x', 'mode': 'auto'});
    });
  });
}
