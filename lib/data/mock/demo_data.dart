import 'package:clock/clock.dart';

import '../../domain/routing/routing_settings.dart';
import '../../domain/servers/server_profile.dart';
import '../../domain/subscriptions/subscription.dart';

/// Synthetic data for UI development and tests. Hosts use the reserved
/// `example.*` domains (RFC 2606) — there are no real servers here.
abstract final class DemoData {
  /// Evaluated once, relative to the current (or fake test) clock so that
  /// "updated 2 hours ago" stays stable.
  static final now = clock.now();

  static final subscriptions = [
    Subscription(
      id: 'sub-nebula',
      name: 'Nebula Cloud',
      url: 'https://sub.example.com/api/v1/client/subscribe?token=demo',
      updatedAt: now.subtract(const Duration(hours: 2)),
      usage: SubscriptionUsage(
        upload: 3 * _gb,
        download: 61 * _gb,
        total: 200 * _gb,
        expire: now.add(const Duration(days: 23)),
      ),
    ),
    Subscription(
      id: 'sub-orbit',
      name: 'Orbit Lab',
      url: 'https://panel.example.net/sub/demo',
      updatedAt: now.subtract(const Duration(days: 1)),
      updateInterval: const Duration(hours: 24),
      usage: SubscriptionUsage(download: 12 * _gb, expire: now.add(const Duration(days: 4))),
    ),
  ];

  static const _uuid = '00000000-0000-4000-8000-00000000d3e0';

  static const servers = [
    ServerProfile(
      id: 's1',
      subscriptionId: 'sub-nebula',
      name: 'Germany · Frankfurt',
      favorite: true,
      outbound: OutboundConfig(
        protocol: ProxyProtocol.vless,
        host: 'de1.example.com',
        port: 443,
        uuid: _uuid,
        flow: 'xtls-rprx-vision',
        tls: TlsConfig(
          mode: TlsMode.reality,
          sni: 'www.example.com',
          fingerprint: 'chrome',
          realityPublicKey: 'demo-public-key',
          realityShortId: '0123abcd',
        ),
      ),
    ),
    ServerProfile(
      id: 's2',
      subscriptionId: 'sub-nebula',
      name: 'Netherlands · Amsterdam',
      sortIndex: 1,
      outbound: OutboundConfig(
        protocol: ProxyProtocol.vless,
        host: 'nl1.example.com',
        port: 443,
        uuid: _uuid,
        transport: TransportConfig(type: TransportType.grpc, serviceName: 'grpc'),
        tls: TlsConfig(mode: TlsMode.tls, sni: 'nl1.example.com'),
      ),
    ),
    ServerProfile(
      id: 's3',
      subscriptionId: 'sub-nebula',
      name: 'Finland · Helsinki',
      sortIndex: 2,
      outbound: OutboundConfig(
        protocol: ProxyProtocol.hysteria2,
        host: 'fi1.example.com',
        port: 8443,
        password: 'demo-password',
        tls: TlsConfig(mode: TlsMode.tls, sni: 'fi1.example.com'),
      ),
    ),
    ServerProfile(
      id: 's4',
      subscriptionId: 'sub-nebula',
      name: 'United States · New York',
      sortIndex: 3,
      outbound: OutboundConfig(
        protocol: ProxyProtocol.trojan,
        host: 'us1.example.com',
        port: 443,
        password: 'demo-password',
        transport: TransportConfig(type: TransportType.ws, path: '/ws'),
        tls: TlsConfig(mode: TlsMode.tls),
      ),
    ),
    ServerProfile(
      id: 's5',
      subscriptionId: 'sub-orbit',
      name: 'Turkey · Istanbul',
      outbound: OutboundConfig(
        protocol: ProxyProtocol.vmess,
        host: 'tr.example.net',
        port: 2053,
        uuid: _uuid,
        transport: TransportConfig(type: TransportType.ws, path: '/vm'),
        tls: TlsConfig(mode: TlsMode.tls),
      ),
    ),
    ServerProfile(
      id: 's6',
      subscriptionId: 'sub-orbit',
      name: 'Kazakhstan · Almaty',
      sortIndex: 1,
      outbound: OutboundConfig(
        protocol: ProxyProtocol.shadowsocks,
        host: 'kz.example.net',
        port: 8388,
        method: 'chacha20-ietf-poly1305',
        password: 'demo-password',
      ),
    ),
    ServerProfile(
      id: 's7',
      name: 'Home router',
      outbound: OutboundConfig(
        protocol: ProxyProtocol.wireguard,
        host: 'home.example.org',
        port: 51820,
        privateKey: 'demo-private-key',
        peerPublicKey: 'demo-peer-key',
        localAddresses: ['10.7.0.2/32'],
      ),
    ),
  ];

  /// Latencies the mock core reports; `null` = unreachable.
  static const latencies = <String, int?>{
    's1': 48,
    's2': 63,
    's3': 112,
    's4': 187,
    's5': 245,
    's6': null,
    's7': 21,
  };

  static const apps = [
    InstalledApp(packageName: 'org.example.browser', label: 'Browser'),
    InstalledApp(packageName: 'org.example.chat', label: 'Chat'),
    InstalledApp(packageName: 'org.example.mail', label: 'Mail'),
    InstalledApp(packageName: 'org.example.maps', label: 'Maps'),
    InstalledApp(packageName: 'org.example.music', label: 'Music'),
    InstalledApp(packageName: 'org.example.bank', label: 'Bank'),
    InstalledApp(packageName: 'org.example.video', label: 'Video'),
    InstalledApp(packageName: 'org.example.news', label: 'News'),
    InstalledApp(packageName: 'android.example.settings', label: 'Settings', isSystem: true),
    InstalledApp(packageName: 'android.example.camera', label: 'Camera', isSystem: true),
  ];

  static const _gb = 1024 * 1024 * 1024;
}
