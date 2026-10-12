import 'package:aurora_vpn/data/storage/database.dart';
import 'package:aurora_vpn/data/storage/drift_repositories.dart';
import 'package:aurora_vpn/data/storage/field_cipher.dart';
import 'package:aurora_vpn/domain/servers/server_profile.dart';
import 'package:aurora_vpn/domain/subscriptions/subscription.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const secretUuid = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';

ServerProfile srv(String id, {String? sub, int sort = 0, bool fav = false}) => ServerProfile(
  id: id,
  name: 'Server $id',
  subscriptionId: sub,
  sortIndex: sort,
  favorite: fav,
  outbound: const OutboundConfig(
    protocol: ProxyProtocol.vless,
    host: 'v.example.com',
    port: 443,
    uuid: secretUuid,
    tls: TlsConfig(mode: TlsMode.reality, realityPublicKey: 'pk'),
  ),
);

void main() {
  group('FieldCipher', () {
    test('round-trips and uses a fresh nonce each time', () async {
      final c = await FieldCipher.open(MemoryKeyStore());
      final a = await c.encrypt('secret');
      final b = await c.encrypt('secret');
      expect(a, isNot(b));
      expect(await c.decrypt(a), 'secret');
    });

    test('the key persists in the key store', () async {
      final store = MemoryKeyStore();
      final enc = await (await FieldCipher.open(store)).encrypt('x');
      expect(await (await FieldCipher.open(store)).decrypt(enc), 'x');
    });

    test('tampering or a different key is detected', () async {
      final c = await FieldCipher.open(MemoryKeyStore());
      final enc = await c.encrypt('secret');
      final other = await FieldCipher.open(MemoryKeyStore());
      await expectLater(other.decrypt(enc), throwsA(anything));
      final bytes = enc.codeUnits.toList();
      bytes[bytes.length - 6] = bytes[bytes.length - 6] == 65 ? 66 : 65;
      await expectLater(c.decrypt(String.fromCharCodes(bytes)), throwsA(anything));
    });
  });

  group('drift repositories', () {
    late AppDatabase db;
    late FieldCipher cipher;
    late DriftServerRepository servers;
    late DriftSubscriptionRepository subs;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      cipher = await FieldCipher.open(MemoryKeyStore());
      servers = DriftServerRepository(db, cipher);
      subs = DriftSubscriptionRepository(db, cipher);
    });
    tearDown(() => db.close());

    test('credentials and subscription URLs are encrypted at rest', () async {
      await subs.upsert(
        const Subscription(id: 's', name: 'S', url: 'https://sub.example.com/?token=T0P'),
      );
      await servers.upsert(srv('a', sub: 's'));

      final rawServer = await db.select(db.servers).getSingle();
      expect(rawServer.configEnc, isNot(contains(secretUuid)));
      expect(rawServer.host, 'v.example.com');
      final rawSub = await db.select(db.subscriptions).getSingle();
      expect(rawSub.urlEnc, isNot(contains('T0P')));

      final loaded = (await servers.watch().first).single;
      expect(loaded.outbound.uuid, secretUuid);
      expect(loaded.outbound.tls.mode, TlsMode.reality);
      expect((await subs.watch().first).single.url, 'https://sub.example.com/?token=T0P');
    });

    test('subscription fields round-trip', () async {
      final expire = DateTime.utc(2027, 3, 2);
      await subs.upsert(
        Subscription(
          id: 's',
          name: 'S',
          url: 'https://x.example.com',
          updatedAt: DateTime.utc(2026, 10, 1, 12),
          updateInterval: const Duration(hours: 6),
          autoUpdate: false,
          usage: SubscriptionUsage(upload: 1, download: 2, total: 30, expire: expire),
          supportUrl: 'https://help.example.com',
        ),
      );
      final s = (await subs.watch().first).single;
      expect(s.updateInterval, const Duration(hours: 6));
      expect(s.autoUpdate, isFalse);
      expect(s.usage!.used, 3);
      expect(s.usage!.expire!.toUtc(), expire);
      expect(s.updatedAt!.toUtc(), DateTime.utc(2026, 10, 1, 12));
      expect(s.supportUrl, 'https://help.example.com');
    });

    test('replaceForSubscription swaps only that subscription, ordered by sortIndex', () async {
      await subs.upsert(const Subscription(id: 's1', name: '1', url: 'https://1.example.com'));
      await subs.upsert(const Subscription(id: 's2', name: '2', url: 'https://2.example.com'));
      await servers.upsertAll([srv('a', sub: 's1'), srv('b', sub: 's2'), srv('m')]);

      await servers.replaceForSubscription('s1', [
        srv('c', sub: 's1', sort: 1),
        srv('d', sub: 's1'),
      ]);
      final ids = (await servers.watch().first).map((s) => s.id).toList();
      expect(ids.toSet(), {'b', 'm', 'c', 'd'});
      expect(ids.indexOf('d'), lessThan(ids.indexOf('c')));
    });

    test('deleting a subscription cascades to its servers', () async {
      await subs.upsert(const Subscription(id: 's1', name: '1', url: 'https://1.example.com'));
      await servers.upsertAll([srv('a', sub: 's1'), srv('m')]);
      await subs.delete('s1');
      expect((await servers.watch().first).map((s) => s.id), ['m']);
    });

    test('rows that cannot be decrypted are skipped, not fatal', () async {
      await servers.upsert(srv('a'));
      await (db.update(
        db.servers,
      )..where((t) => t.id.equals('a'))).write(const ServersCompanion(configEnc: Value('garbage')));
      final fresh = DriftServerRepository(db, cipher);
      expect(await fresh.watch().first, isEmpty);
    });

    test('watch emits on every change', () async {
      final emissions = <int>[];
      final sub = servers.watch().listen((l) => emissions.add(l.length));
      await pumpEventQueue();
      await servers.upsert(srv('a'));
      await pumpEventQueue();
      await servers.upsert(srv('b', fav: true));
      await pumpEventQueue();
      await servers.delete('a');
      await pumpEventQueue();
      await sub.cancel();
      expect(emissions, [0, 1, 2, 1]);
    });
  });
}
