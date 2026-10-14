@Tags(['core'])
library;

import 'dart:io';

import 'package:aurora_vpn/data/singbox/config_builder.dart';
import 'package:aurora_vpn/domain/logs/log_entry.dart';
import 'package:aurora_vpn/domain/routing/routing_settings.dart';
import 'package:aurora_vpn/domain/servers/server_profile.dart';
import 'package:aurora_vpn/domain/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validates generated configs with the real core (`sing-box check`).
/// Needs `scripts/fetch_core.ps1` to have run; skipped otherwise.
void main() {
  final exe = File('third_party/core/windows/sing-box.exe').absolute;
  final rules = Directory('assets/rules').absolute.path.replaceAll(r'\', '/');
  final skip = Platform.isWindows && exe.existsSync() ? false : 'sing-box.exe not fetched';

  const uuid = '0f0e0d0c-0b0a-4908-8706-050403020100';
  // A syntactically valid X25519 public key (32 zero bytes, base64url).
  const pbk = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
  const wgKey = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';

  final outbounds = <String, OutboundConfig>{
    'vless-reality': const OutboundConfig(
      protocol: ProxyProtocol.vless,
      host: 'v.example.com',
      port: 443,
      uuid: uuid,
      flow: 'xtls-rprx-vision',
      tls: TlsConfig(
        mode: TlsMode.reality,
        sni: 'www.example.org',
        realityPublicKey: pbk,
        realityShortId: 'ab12',
      ),
    ),
    'vless-ws-tls': const OutboundConfig(
      protocol: ProxyProtocol.vless,
      host: 'v.example.com',
      port: 443,
      uuid: uuid,
      transport: TransportConfig(type: TransportType.ws, path: '/ws', host: 'cdn.example.com'),
      tls: TlsConfig(mode: TlsMode.tls, alpn: ['http/1.1'], fingerprint: 'firefox'),
    ),
    'vmess-grpc': const OutboundConfig(
      protocol: ProxyProtocol.vmess,
      host: '198.51.100.1',
      port: 443,
      uuid: uuid,
      transport: TransportConfig(type: TransportType.grpc, serviceName: 'svc'),
      tls: TlsConfig(mode: TlsMode.tls, sni: 'g.example.com'),
    ),
    'trojan-h2': const OutboundConfig(
      protocol: ProxyProtocol.trojan,
      host: 't.example.com',
      port: 443,
      password: 'pw',
      transport: TransportConfig(type: TransportType.h2, path: '/h2', host: 't.example.com'),
      tls: TlsConfig(mode: TlsMode.tls),
    ),
    'vless-httpupgrade': const OutboundConfig(
      protocol: ProxyProtocol.vless,
      host: 'u.example.com',
      port: 80,
      uuid: uuid,
      transport: TransportConfig(type: TransportType.httpupgrade, path: '/up'),
    ),
    'shadowsocks-2022': const OutboundConfig(
      protocol: ProxyProtocol.shadowsocks,
      host: 's.example.com',
      port: 8388,
      method: '2022-blake3-aes-128-gcm',
      password: 'AAAAAAAAAAAAAAAAAAAAAA==',
    ),
    'hysteria2': const OutboundConfig(
      protocol: ProxyProtocol.hysteria2,
      host: 'h.example.com',
      port: 443,
      password: 'pw',
      obfsPassword: 'ob',
      upMbps: 50,
      downMbps: 200,
    ),
    'tuic': const OutboundConfig(
      protocol: ProxyProtocol.tuic,
      host: 'q.example.com',
      port: 443,
      uuid: uuid,
      password: 'pw',
      congestionControl: 'bbr',
      tls: TlsConfig(mode: TlsMode.tls, alpn: ['h3']),
    ),
    'wireguard': const OutboundConfig(
      protocol: ProxyProtocol.wireguard,
      host: 'w.example.com',
      port: 51820,
      privateKey: wgKey,
      peerPublicKey: wgKey,
      localAddresses: ['10.0.0.2/32'],
      reserved: [1, 2, 3],
      mtu: 1280,
    ),
  };

  final scenarios = <String, (RoutingSettings, AppSettings, CoreOptions)>{
    'android-rules-all': (
      const RoutingSettings(
        ruDirect: true,
        blockAds: true,
        splitMode: SplitTunnelMode.exclude,
        splitApps: {'org.example.a'},
      ),
      const AppSettings(logLevel: LogLevel.debug),
      CoreOptions(capture: CaptureMode.tun, ruleSetDir: rules, android: true),
    ),
    'windows-proxy-global': (
      const RoutingSettings(mode: RoutingMode.global),
      const AppSettings(
        ipv6: true,
        dnsProtocol: DnsProtocol.dot,
        dnsServer: 'tls://dns.example.com',
      ),
      CoreOptions(
        capture: CaptureMode.systemProxy,
        ruleSetDir: rules,
        clashApiPort: 9090,
        clashApiSecret: 'x',
      ),
    ),
    'windows-tun-killswitch-direct': (
      const RoutingSettings(mode: RoutingMode.direct),
      const AppSettings(killSwitch: true, dnsProtocol: DnsProtocol.udp, dnsServer: '8.8.8.8'),
      CoreOptions(capture: CaptureMode.tun, ruleSetDir: rules),
    ),
  };

  final tmp = Directory.systemTemp.createTempSync('aurora-check');
  tearDownAll(() => tmp.deleteSync(recursive: true));

  Future<void> check(String name, String json) async {
    final file = File('${tmp.path}/$name.json')..writeAsStringSync(json);
    final r = await Process.run(exe.path, ['check', '-c', file.path]);
    expect(r.exitCode, 0, reason: '$name\n${r.stdout}\n${r.stderr}\n$json');
  }

  // Servers that run on Xray (Reality, XHTTP…) reach it through the SOCKS bridge.
  CoreOptions withBridge(CoreOptions o) => CoreOptions(
    capture: o.capture,
    ruleSetDir: o.ruleSetDir,
    android: o.android,
    mixedPort: o.mixedPort,
    clashApiPort: o.clashApiPort,
    clashApiSecret: o.clashApiSecret,
    cachePath: o.cachePath,
    selfPackage: o.android ? 'dev.aurora.aurora_vpn' : null,
    xray: const XrayBridge(port: 23456, username: 'u', password: 'p'),
  );

  for (final o in outbounds.entries) {
    test('outbound ${o.key}', () async {
      final (routing, settings, options) = scenarios['android-rules-all']!;
      await check(
        o.key,
        SingBoxConfigBuilder.buildJson(
          server: ServerProfile(id: o.key, name: o.key, outbound: o.value),
          routing: routing,
          settings: settings,
          options: o.value.requiresXray ? withBridge(options) : options,
        ),
      );
    }, skip: skip);
  }

  // The sing-box side of an Xray server: bridge outbound + self-exclusion.
  test('outbound vless-reality via the Xray bridge (windows)', () async {
    final (routing, settings, options) = scenarios['windows-tun-killswitch-direct']!;
    await check(
      'reality-bridge-windows',
      SingBoxConfigBuilder.buildJson(
        server: ServerProfile(id: 'r', name: 'r', outbound: outbounds['vless-reality']!),
        routing: routing,
        settings: settings,
        options: withBridge(options),
      ),
    );
  }, skip: skip);

  for (final s in scenarios.entries) {
    test('scenario ${s.key}', () async {
      final (routing, settings, options) = s.value;
      await check(
        s.key,
        SingBoxConfigBuilder.buildJson(
          // A server sing-box runs itself, so the whole config is exercised.
          server: ServerProfile(id: 's', name: 's', outbound: outbounds['vless-ws-tls']!),
          routing: routing,
          settings: settings,
          options: options,
        ),
      );
    }, skip: skip);
  }
}
