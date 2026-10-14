import 'dart:convert';

import 'package:aurora_vpn/data/singbox/config_builder.dart';
import 'package:aurora_vpn/domain/logs/log_entry.dart';
import 'package:aurora_vpn/domain/routing/routing_settings.dart';
import 'package:aurora_vpn/domain/servers/server_profile.dart';
import 'package:aurora_vpn/domain/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

const uuid = '5c7e0a1b-2d3f-4a5b-8c9d-0e1f2a3b4c5d';

ServerProfile profile(OutboundConfig o) => ServerProfile(id: 'x', name: 'X', outbound: o);

Map<String, Object?> build(
  OutboundConfig o, {
  RoutingSettings routing = const RoutingSettings(),
  AppSettings settings = const AppSettings(),
  CoreOptions options = const CoreOptions(
    capture: CaptureMode.tun,
    ruleSetDir: '/rules',
    android: true,
  ),
}) {
  final config = SingBoxConfigBuilder.build(
    server: profile(o),
    routing: routing,
    settings: settings,
    options: options,
  );
  // Must always be plain JSON.
  return jsonDecode(jsonEncode(config)) as Map<String, Object?>;
}

Map<String, Object?> proxyOf(Map<String, Object?> config) {
  final all = [...?(config['outbounds'] as List?), ...?(config['endpoints'] as List?)];
  return all.cast<Map<String, Object?>>().singleWhere((o) => o['tag'] == 'proxy');
}

const vlessBase = OutboundConfig(
  protocol: ProxyProtocol.vless,
  host: 'v.example.com',
  port: 443,
  uuid: uuid,
);

void main() {
  group('transports', () {
    test('tcp has no transport block', () {
      final p = proxyOf(build(vlessBase));
      expect(p.containsKey('transport'), isFalse);
      expect(p['packet_encoding'], 'xudp');
    });

    test('ws with path and Host header; empty path defaults to /', () {
      final p = proxyOf(
        build(
          vlessBase.copyWith(
            transport: const TransportConfig(
              type: TransportType.ws,
              path: '/ws',
              host: 'cdn.example.com',
            ),
          ),
        ),
      );
      expect(p['transport'], {
        'type': 'ws',
        'path': '/ws',
        'headers': {'Host': 'cdn.example.com'},
      });
      final bare = proxyOf(
        build(vlessBase.copyWith(transport: const TransportConfig(type: TransportType.ws))),
      );
      expect((bare['transport']! as Map)['path'], '/');
    });

    test('grpc', () {
      final p = proxyOf(
        build(
          vlessBase.copyWith(
            transport: const TransportConfig(type: TransportType.grpc, serviceName: 'svc'),
          ),
        ),
      );
      expect(p['transport'], {'type': 'grpc', 'service_name': 'svc'});
    });

    test('h2 maps to sing-box "http" with host list', () {
      final p = proxyOf(
        build(
          vlessBase.copyWith(
            transport: const TransportConfig(
              type: TransportType.h2,
              path: '/h2',
              host: 'a.example.com, b.example.com',
            ),
          ),
        ),
      );
      expect(p['transport'], {
        'type': 'http',
        'host': ['a.example.com', 'b.example.com'],
        'path': '/h2',
      });
    });

    test('httpupgrade', () {
      final p = proxyOf(
        build(
          vlessBase.copyWith(
            transport: const TransportConfig(
              type: TransportType.httpupgrade,
              path: '/up',
              host: 'u.example.com',
            ),
          ),
        ),
      );
      expect(p['transport'], {'type': 'httpupgrade', 'host': 'u.example.com', 'path': '/up'});
    });
  });

  group('tls', () {
    test('plain TLS: SNI defaults to the host name, alpn and uTLS', () {
      final p = proxyOf(
        build(
          vlessBase.copyWith(
            tls: const TlsConfig(mode: TlsMode.tls, alpn: ['h2'], fingerprint: 'chrome'),
          ),
        ),
      );
      expect(p['tls'], {
        'enabled': true,
        'server_name': 'v.example.com',
        'alpn': ['h2'],
        'utls': {'enabled': true, 'fingerprint': 'chrome'},
      });
    });

    test('no SNI is invented for IP addresses; insecure flag', () {
      final p = proxyOf(
        build(
          vlessBase.copyWith(
            host: '198.51.100.7',
            tls: const TlsConfig(mode: TlsMode.tls, insecure: true),
          ),
        ),
      );
      // A Chrome fingerprint is the default: Go's stock TLS hello gets throttled by DPI.
      expect(p['tls'], {
        'enabled': true,
        'insecure': true,
        'utls': {'enabled': true, 'fingerprint': 'chrome'},
      });
    });

    test('QUIC protocols get no uTLS fingerprint', () {
      final p = proxyOf(
        build(
          const OutboundConfig(
            protocol: ProxyProtocol.hysteria2,
            host: 'h.example.com',
            port: 443,
            password: 'secret',
          ),
        ),
      );
      expect((p['tls']! as Map).containsKey('utls'), isFalse);
    });

    test('reality forces uTLS and carries key + short id', () {
      // Reality runs through Xray in the app; the sing-box outbound shape is
      // still what imported sing-box configs and tools would get.
      final p = SingBoxConfigBuilder.outbound(
        vlessBase.copyWith(
          flow: 'xtls-rprx-vision',
          tls: const TlsConfig(
            mode: TlsMode.reality,
            sni: 'www.example.org',
            realityPublicKey: 'pk',
            realityShortId: 'ab',
          ),
        ),
      );
      expect(p['flow'], 'xtls-rprx-vision');
      expect(p['tls'], {
        'enabled': true,
        'server_name': 'www.example.org',
        'utls': {'enabled': true, 'fingerprint': 'chrome'},
        'reality': {'enabled': true, 'public_key': 'pk', 'short_id': 'ab'},
      });
    });

    test('no TLS block when security is none', () {
      expect(proxyOf(build(vlessBase)).containsKey('tls'), isFalse);
    });
  });

  group('protocols', () {
    test('vmess', () {
      final p = proxyOf(
        build(
          const OutboundConfig(
            protocol: ProxyProtocol.vmess,
            host: 'm.example.com',
            port: 8443,
            uuid: uuid,
            alterId: 1,
            vmessSecurity: 'aes-128-gcm',
            tls: TlsConfig(mode: TlsMode.tls),
          ),
        ),
      );
      expect(p['type'], 'vmess');
      expect(p['security'], 'aes-128-gcm');
      expect(p['alter_id'], 1);
      expect(p['server_port'], 8443);
    });

    test('trojan', () {
      final p = proxyOf(
        build(
          const OutboundConfig(
            protocol: ProxyProtocol.trojan,
            host: 't.example.com',
            port: 443,
            password: 'pw',
            tls: TlsConfig(mode: TlsMode.tls),
          ),
        ),
      );
      expect(p, containsPair('type', 'trojan'));
      expect(p, containsPair('password', 'pw'));
    });

    test('shadowsocks', () {
      final p = proxyOf(
        build(
          const OutboundConfig(
            protocol: ProxyProtocol.shadowsocks,
            host: 's.example.com',
            port: 8388,
            method: '2022-blake3-aes-128-gcm',
            password: 'a2V5',
          ),
        ),
      );
      expect(p, {
        'type': 'shadowsocks',
        'tag': 'proxy',
        'server': 's.example.com',
        'server_port': 8388,
        'method': '2022-blake3-aes-128-gcm',
        'password': 'a2V5',
      });
    });

    test('hysteria2 always enables TLS; salamander obfs; bandwidth', () {
      final p = proxyOf(
        build(
          const OutboundConfig(
            protocol: ProxyProtocol.hysteria2,
            host: 'h.example.com',
            port: 443,
            password: 'pw',
            obfsPassword: 'ob',
            upMbps: 50,
            downMbps: 200,
          ),
        ),
      );
      expect(p['obfs'], {'type': 'salamander', 'password': 'ob'});
      expect(p['up_mbps'], 50);
      expect((p['tls']! as Map)['enabled'], isTrue);
    });

    test('tuic', () {
      final p = proxyOf(
        build(
          const OutboundConfig(
            protocol: ProxyProtocol.tuic,
            host: 'u.example.com',
            port: 443,
            uuid: uuid,
            password: 'pw',
            congestionControl: 'bbr',
            tls: TlsConfig(mode: TlsMode.tls, alpn: ['h3']),
          ),
        ),
      );
      expect(p['congestion_control'], 'bbr');
      expect((p['tls']! as Map)['alpn'], ['h3']);
    });

    test('wireguard becomes an endpoint, not an outbound', () {
      final config = build(
        const OutboundConfig(
          protocol: ProxyProtocol.wireguard,
          host: 'w.example.com',
          port: 51820,
          privateKey: 'priv',
          peerPublicKey: 'pub',
          localAddresses: ['10.0.0.2/32'],
          reserved: [1, 2, 3],
          mtu: 1280,
        ),
      );
      expect((config['outbounds']! as List).map((o) => (o as Map)['tag']), ['direct']);
      final ep = proxyOf(config);
      expect(ep['type'], 'wireguard');
      expect(ep['address'], ['10.0.0.2/32']);
      expect(ep['mtu'], 1280);
      final peer = (ep['peers']! as List).single as Map;
      expect(peer['address'], 'w.example.com');
      expect(peer['reserved'], [1, 2, 3]);
      expect(peer['allowed_ips'], ['0.0.0.0/0', '::/0']);
    });
  });

  group('routing', () {
    List<Map<String, Object?>> rules(Map<String, Object?> c) =>
        ((c['route']! as Map)['rules']! as List).cast<Map<String, Object?>>();

    test('rules mode with every preset', () {
      final c = build(vlessBase, routing: const RoutingSettings(ruDirect: true, blockAds: true));
      final route = c['route']! as Map;
      expect(route['final'], 'proxy');
      expect(rules(c), [
        {'action': 'sniff'},
        {'protocol': 'dns', 'action': 'hijack-dns'},
        {'ip_version': 6, 'action': 'reject'},
        {'ip_is_private': true, 'outbound': 'direct'},
        {
          'rule_set': ['geosite-category-ads-all'],
          'action': 'reject',
        },
        {
          'rule_set': ['geoip-ru', 'geosite-category-ru'],
          'outbound': 'direct',
        },
      ]);
      final sets = (route['rule_set']! as List).cast<Map<String, Object?>>();
      expect(sets.map((s) => s['tag']), [
        'geoip-ru',
        'geosite-category-ru',
        'geosite-category-ads-all',
      ]);
      expect(sets.first, {
        'type': 'local',
        'tag': 'geoip-ru',
        'format': 'binary',
        'path': '/rules/geoip-ru.srs',
      });
    });

    test('global mode ignores presets; IPv6 enabled drops the v6 reject', () {
      final c = build(
        vlessBase,
        routing: const RoutingSettings(mode: RoutingMode.global, ruDirect: true, blockAds: true),
        settings: const AppSettings(ipv6: true),
      );
      expect(rules(c), [
        {'action': 'sniff'},
        {'protocol': 'dns', 'action': 'hijack-dns'},
      ]);
      expect((c['route']! as Map)['rule_set'], isEmpty);
      expect((c['dns']! as Map)['strategy'], 'prefer_ipv4');
    });

    test('direct mode routes everything direct and DNS skips the proxy', () {
      final c = build(vlessBase, routing: const RoutingSettings(mode: RoutingMode.direct));
      expect((c['route']! as Map)['final'], 'direct');
      final remote = ((c['dns']! as Map)['servers']! as List).first as Map;
      expect(remote.containsKey('detour'), isFalse);
    });
  });

  group('dns', () {
    Map<String, Object?> remote(AppSettings s) =>
        (((build(vlessBase, settings: s)['dns']! as Map)['servers']! as List).first as Map)
            .cast<String, Object?>();

    test('DoH by IP', () {
      expect(remote(const AppSettings()), {
        'type': 'https',
        'server': '1.1.1.1',
        'tag': 'dns-remote',
        'detour': 'proxy',
      });
    });

    test('DoH by name needs a resolver; custom path is kept', () {
      final r = remote(const AppSettings(dnsServer: 'https://dns.example.com/custom-query'));
      expect(r['server'], 'dns.example.com');
      expect(r['path'], '/custom-query');
      expect(r['domain_resolver'], 'dns-local');
    });

    test('DoT and UDP with port', () {
      expect(
        remote(const AppSettings(dnsProtocol: DnsProtocol.dot, dnsServer: 'tls://9.9.9.9'))['type'],
        'tls',
      );
      final udp = remote(
        const AppSettings(dnsProtocol: DnsProtocol.udp, dnsServer: '8.8.8.8:5353'),
      );
      expect(udp['type'], 'udp');
      expect(udp['server'], '8.8.8.8');
      expect(udp['server_port'], 5353);
    });

    test('RU preset sends Russian domains to the local resolver', () {
      final dns = build(vlessBase, routing: const RoutingSettings(ruDirect: true))['dns']! as Map;
      expect(dns['rules'], [
        {
          'rule_set': ['geosite-category-ru'],
          'server': 'dns-local',
        },
      ]);
      expect(dns['final'], 'dns-remote');
      expect(dns['strategy'], 'ipv4_only');
    });
  });

  group('inbounds', () {
    Map<String, Object?> inbound(Map<String, Object?> c) =>
        ((c['inbounds']! as List).single as Map).cast();

    test('android tun with MTU and per-app include list', () {
      final i = inbound(
        build(
          vlessBase,
          routing: const RoutingSettings(
            splitMode: SplitTunnelMode.include,
            splitApps: {'org.example.b', 'org.example.a'},
          ),
          settings: const AppSettings(mtu: 1500),
        ),
      );
      expect(i['type'], 'tun');
      expect(i['mtu'], 1500);
      expect(i['strict_route'], isTrue);
      expect(i['include_package'], ['org.example.a', 'org.example.b']);
      expect(i.containsKey('interface_name'), isFalse);
    });

    test('android exclude list; off mode adds nothing', () {
      expect(
        inbound(
          build(
            vlessBase,
            routing: const RoutingSettings(
              splitMode: SplitTunnelMode.exclude,
              splitApps: {'org.example.a'},
            ),
          ),
        )['exclude_package'],
        ['org.example.a'],
      );
      final off = inbound(
        build(vlessBase, routing: const RoutingSettings(splitApps: {'org.example.a'})),
      );
      expect(off.containsKey('include_package') || off.containsKey('exclude_package'), isFalse);
    });

    test('windows system proxy uses a mixed inbound and the Clash API', () {
      final c = build(
        vlessBase,
        options: const CoreOptions(
          capture: CaptureMode.systemProxy,
          ruleSetDir: 'C:/rules',
          clashApiPort: 9090,
          clashApiSecret: 's3cret',
        ),
      );
      expect(inbound(c), {
        'type': 'mixed',
        'tag': 'mixed-in',
        'listen': '127.0.0.1',
        'listen_port': 2080,
        'set_system_proxy': false,
      });
      expect((c['experimental']! as Map)['clash_api'], {
        'external_controller': '127.0.0.1:9090',
        'secret': 's3cret',
      });
    });

    test('windows TUN: strict route only with the kill switch', () {
      const opts = CoreOptions(capture: CaptureMode.tun, ruleSetDir: 'C:/rules');
      expect(inbound(build(vlessBase, options: opts))['strict_route'], isFalse);
      final ks = inbound(
        build(vlessBase, options: opts, settings: const AppSettings(killSwitch: true)),
      );
      expect(ks['strict_route'], isTrue);
      expect(ks['interface_name'], 'AuroraTun');
    });
  });

  test('log level follows settings', () {
    final c = build(vlessBase, settings: const AppSettings(logLevel: LogLevel.warn));
    expect((c['log']! as Map)['level'], 'warn');
  });
}
