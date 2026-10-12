import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../domain/servers/repositories.dart';
import '../../domain/servers/server_profile.dart';
import '../../domain/subscriptions/subscription.dart';
import 'database.dart';
import 'field_cipher.dart';

class DriftServerRepository implements ServerRepository {
  DriftServerRepository(this._db, this._cipher);

  final AppDatabase _db;
  final FieldCipher _cipher;

  /// id → (ciphertext, decoded) so unchanged rows aren't decrypted again on
  /// every table change.
  final _cache = <String, (String, OutboundConfig)>{};

  @override
  Stream<List<ServerProfile>> watch() {
    final q = _db.select(_db.servers)
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortIndex),
        (t) => OrderingTerm(expression: t.name),
      ]);
    return q.watch().asyncMap(_toProfiles);
  }

  Future<List<ServerProfile>> _toProfiles(List<ServerRow> rows) async {
    final out = <ServerProfile>[];
    for (final r in rows) {
      final cached = _cache[r.id];
      OutboundConfig outbound;
      if (cached != null && cached.$1 == r.configEnc) {
        outbound = cached.$2;
      } else {
        try {
          final json = jsonDecode(await _cipher.decrypt(r.configEnc)) as Map<String, Object?>;
          outbound = OutboundConfig.fromJson(json);
        } catch (_) {
          // Undecryptable (e.g. the key store was wiped): skip rather than crash.
          continue;
        }
        _cache[r.id] = (r.configEnc, outbound);
      }
      out.add(
        ServerProfile(
          id: r.id,
          name: r.name,
          outbound: outbound,
          subscriptionId: r.subscriptionId,
          favorite: r.favorite,
          sortIndex: r.sortIndex,
        ),
      );
    }
    return out;
  }

  Future<ServersCompanion> _toRow(ServerProfile p) async => ServersCompanion.insert(
    id: p.id,
    subscriptionId: Value(p.subscriptionId),
    name: p.name,
    protocol: p.protocol.name,
    host: p.host,
    port: p.port,
    favorite: Value(p.favorite),
    sortIndex: Value(p.sortIndex),
    configEnc: await _cipher.encrypt(jsonEncode(p.outbound.toJson())),
  );

  @override
  Future<void> upsert(ServerProfile profile) async {
    final row = await _toRow(profile);
    await _db.into(_db.servers).insertOnConflictUpdate(row);
  }

  @override
  Future<void> upsertAll(List<ServerProfile> profiles) async {
    final rows = [for (final p in profiles) await _toRow(p)];
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.servers, rows));
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.servers)..where((t) => t.id.equals(id))).go();
    _cache.remove(id);
  }

  @override
  Future<void> replaceForSubscription(String subscriptionId, List<ServerProfile> servers) async {
    final rows = [for (final p in servers) await _toRow(p)];
    await _db.transaction(() async {
      await (_db.delete(_db.servers)..where((t) => t.subscriptionId.equals(subscriptionId))).go();
      await _db.batch((b) => b.insertAll(_db.servers, rows));
    });
  }
}

class DriftSubscriptionRepository implements SubscriptionRepository {
  DriftSubscriptionRepository(this._db, this._cipher);

  final AppDatabase _db;
  final FieldCipher _cipher;
  final _urlCache = <String, (String, String)>{};

  @override
  Stream<List<Subscription>> watch() {
    final q = _db.select(_db.subscriptions)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return q.watch().asyncMap((rows) async {
      final out = <Subscription>[];
      for (final r in rows) {
        String url;
        final cached = _urlCache[r.id];
        if (cached != null && cached.$1 == r.urlEnc) {
          url = cached.$2;
        } else {
          try {
            url = await _cipher.decrypt(r.urlEnc);
          } catch (_) {
            continue;
          }
          _urlCache[r.id] = (r.urlEnc, url);
        }
        out.add(
          Subscription(
            id: r.id,
            name: r.name,
            url: url,
            updatedAt: r.updatedAt == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(r.updatedAt!, isUtc: true).toLocal(),
            updateInterval: Duration(minutes: r.updateIntervalMinutes),
            autoUpdate: r.autoUpdate,
            usage: !r.hasUsage
                ? null
                : SubscriptionUsage(
                    upload: r.upload,
                    download: r.download,
                    total: r.total,
                    expire: r.expire == null
                        ? null
                        : DateTime.fromMillisecondsSinceEpoch(r.expire!, isUtc: true).toLocal(),
                  ),
            supportUrl: r.supportUrl,
          ),
        );
      }
      return out;
    });
  }

  @override
  Future<void> upsert(Subscription s) async {
    final existing = await (_db.select(
      _db.subscriptions,
    )..where((t) => t.id.equals(s.id))).getSingleOrNull();
    final usage = s.usage;
    final row = SubscriptionsCompanion.insert(
      id: s.id,
      name: s.name,
      urlEnc: await _cipher.encrypt(s.url),
      updatedAt: Value(s.updatedAt?.millisecondsSinceEpoch),
      updateIntervalMinutes: Value(s.updateInterval.inMinutes),
      autoUpdate: Value(s.autoUpdate),
      upload: Value(usage?.upload ?? 0),
      download: Value(usage?.download ?? 0),
      total: Value(usage?.total ?? 0),
      hasUsage: Value(usage != null),
      expire: Value(usage?.expire?.millisecondsSinceEpoch),
      supportUrl: Value(s.supportUrl),
      createdAt: existing?.createdAt ?? clock.now().millisecondsSinceEpoch,
    );
    await _db.into(_db.subscriptions).insertOnConflictUpdate(row);
  }

  @override
  Future<void> delete(String id) async {
    // Servers go with it via ON DELETE CASCADE.
    await (_db.delete(_db.subscriptions)..where((t) => t.id.equals(id))).go();
    _urlCache.remove(id);
  }
}
