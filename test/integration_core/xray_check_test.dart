@Tags(['core'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:aurora_vpn/data/parsers/subscription_parser.dart';
import 'package:aurora_vpn/data/singbox/config_builder.dart';
import 'package:aurora_vpn/data/xray/xray_config_builder.dart';
import 'package:aurora_vpn/domain/routing/routing_settings.dart';
import 'package:aurora_vpn/domain/servers/server_profile.dart';
import 'package:aurora_vpn/domain/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validates generated Xray configs with the real `xray run -test`, and the
/// matching sing-box side with `sing-box check`. Skipped unless fetch_core ran.
void main() {
  final xray = File('third_party/core/windows/xray.exe').absolute;
  final singbox = File('third_party/core/windows/sing-box.exe').absolute;
  final skip = Platform.isWindows && xray.existsSync() && singbox.existsSync()
      ? false
      : 'core binaries not fetched';
  const uuid = '0f0e0d0c-0b0a-4908-8706-050403020100';
  const pbk = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
  const bridge = XrayBridge(port: 23456, username: 'u', password: 'p');
  final tmp = Directory.systemTemp.createTempSync('aurora-xray');
  tearDownAll(() => tmp.deleteSync(recursive: true));

  Future<void> run(File exe, List<String> args, String name, String json) async {
    final f = File('${tmp.path}/$name.json')..writeAsStringSync(json);
    final r = await Process.run(exe.path, [...args, f.path]);
    expect(r.exitCode, 0, reason: '$name\n${r.stdout}\n${r.stderr}\n$json');
  }

  final servers = <String, OutboundConfig>{
    'xhttp-reality': const OutboundConfig(
      protocol: ProxyProtocol.vless,
      host: 'x.example.com',
      port: 443,
      uuid: uuid,
      transport: TransportConfig(type: TransportType.xhttp, path: '/x', mode: 'auto'),
      tls: TlsConfig(
        mode: TlsMode.reality,
        sni: 'www.example.org',
        realityPublicKey: pbk,
        realityShortId: 'ab',
      ),
    ),
    'tcp-reality-vision': const OutboundConfig(
      protocol: ProxyProtocol.vless,
      host: 'r.example.com',
      port: 443,
      uuid: uuid,
      flow: 'xtls-rprx-vision',
      tls: TlsConfig(
        mode: TlsMode.reality,
        sni: 'www.example.org',
        realityPublicKey: pbk,
        realityShortId: 'ab',
        realitySpiderX: '/search',
      ),
    ),
    'tcp-http-obfs': const OutboundConfig(
      protocol: ProxyProtocol.vmess,
      host: 'm.example.com',
      port: 8080,
      uuid: uuid,
      transport: TransportConfig(headerType: 'http', path: '/a', host: 'cdn.example.com'),
    ),
    'xhttp-tls-extra': const OutboundConfig(
      protocol: ProxyProtocol.vless,
      host: 'x.example.com',
      port: 443,
      uuid: uuid,
      transport: TransportConfig(
        type: TransportType.xhttp,
        path: '/x',
        host: 'cdn.example.com',
        mode: 'packet-up',
        extra: '{"xPaddingBytes":"100-1000"}',
      ),
      tls: TlsConfig(mode: TlsMode.tls, fingerprint: 'chrome', alpn: ['h2']),
    ),
  };

  // An imported Xray config with a fragment chain (kept verbatim).
  final imported = SubscriptionParser.parse(
    jsonEncode([
      {
        'remarks': 'chained',
        'outbounds': [
          {
            'tag': 'proxy',
            'protocol': 'vless',
            'settings': {
              'vnext': [
                {
                  'address': 'v.example.com',
                  'port': 443,
                  'users': [
                    {'id': uuid, 'encryption': 'none'},
                  ],
                },
              ],
            },
            'streamSettings': {
              'network': 'ws',
              'security': 'tls',
              'wsSettings': {'path': '/ws'},
              'sockopt': {'dialerProxy': 'frag'},
            },
          },
          {
            'tag': 'frag',
            'protocol': 'freedom',
            'settings': {
              'fragment': {'packets': 'tlshello', 'length': '100-200', 'interval': '10-20'},
            },
          },
        ],
      },
    ]),
  ).servers.single.outbound;
  servers['imported-chain'] = imported;

  for (final s in servers.entries) {
    test('xray ${s.key}', () async {
      await run(
        xray,
        ['run', '-test', '-c'],
        s.key,
        XrayConfigBuilder.buildJson(server: s.value, bridge: bridge),
      );
    }, skip: skip);

    test('sing-box side of ${s.key}', () async {
      await run(
        singbox,
        ['check', '-c'],
        'sb-${s.key}',
        SingBoxConfigBuilder.buildJson(
          server: ServerProfile(id: s.key, name: s.key, outbound: s.value),
          routing: const RoutingSettings(),
          settings: const AppSettings(),
          options: CoreOptions(
            capture: CaptureMode.tun,
            ruleSetDir: Directory('assets/rules').absolute.path.replaceAll(r'\', '/'),
            xray: bridge,
          ),
        ),
      );
    }, skip: skip);
  }
}
