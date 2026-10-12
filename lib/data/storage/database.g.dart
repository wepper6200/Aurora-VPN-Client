// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, SubscriptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlEncMeta = const VerificationMeta('urlEnc');
  @override
  late final GeneratedColumn<String> urlEnc = GeneratedColumn<String>(
    'url_enc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updateIntervalMinutesMeta = const VerificationMeta(
    'updateIntervalMinutes',
  );
  @override
  late final GeneratedColumn<int> updateIntervalMinutes = GeneratedColumn<int>(
    'update_interval_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(720),
  );
  static const VerificationMeta _autoUpdateMeta = const VerificationMeta('autoUpdate');
  @override
  late final GeneratedColumn<bool> autoUpdate = GeneratedColumn<bool>(
    'auto_update',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("auto_update" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _uploadMeta = const VerificationMeta('upload');
  @override
  late final GeneratedColumn<int> upload = GeneratedColumn<int>(
    'upload',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _downloadMeta = const VerificationMeta('download');
  @override
  late final GeneratedColumn<int> download = GeneratedColumn<int>(
    'download',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hasUsageMeta = const VerificationMeta('hasUsage');
  @override
  late final GeneratedColumn<bool> hasUsage = GeneratedColumn<bool>(
    'has_usage',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("has_usage" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _expireMeta = const VerificationMeta('expire');
  @override
  late final GeneratedColumn<int> expire = GeneratedColumn<int>(
    'expire',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supportUrlMeta = const VerificationMeta('supportUrl');
  @override
  late final GeneratedColumn<String> supportUrl = GeneratedColumn<String>(
    'support_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    urlEnc,
    updatedAt,
    updateIntervalMinutes,
    autoUpdate,
    upload,
    download,
    total,
    hasUsage,
    expire,
    supportUrl,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubscriptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url_enc')) {
      context.handle(_urlEncMeta, urlEnc.isAcceptableOrUnknown(data['url_enc']!, _urlEncMeta));
    } else if (isInserting) {
      context.missing(_urlEncMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('update_interval_minutes')) {
      context.handle(
        _updateIntervalMinutesMeta,
        updateIntervalMinutes.isAcceptableOrUnknown(
          data['update_interval_minutes']!,
          _updateIntervalMinutesMeta,
        ),
      );
    }
    if (data.containsKey('auto_update')) {
      context.handle(
        _autoUpdateMeta,
        autoUpdate.isAcceptableOrUnknown(data['auto_update']!, _autoUpdateMeta),
      );
    }
    if (data.containsKey('upload')) {
      context.handle(_uploadMeta, upload.isAcceptableOrUnknown(data['upload']!, _uploadMeta));
    }
    if (data.containsKey('download')) {
      context.handle(
        _downloadMeta,
        download.isAcceptableOrUnknown(data['download']!, _downloadMeta),
      );
    }
    if (data.containsKey('total')) {
      context.handle(_totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    }
    if (data.containsKey('has_usage')) {
      context.handle(
        _hasUsageMeta,
        hasUsage.isAcceptableOrUnknown(data['has_usage']!, _hasUsageMeta),
      );
    }
    if (data.containsKey('expire')) {
      context.handle(_expireMeta, expire.isAcceptableOrUnknown(data['expire']!, _expireMeta));
    }
    if (data.containsKey('support_url')) {
      context.handle(
        _supportUrlMeta,
        supportUrl.isAcceptableOrUnknown(data['support_url']!, _supportUrlMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubscriptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubscriptionRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      urlEnc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url_enc'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      updateIntervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_interval_minutes'],
      )!,
      autoUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_update'],
      )!,
      upload: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}upload'],
      )!,
      download: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}download'],
      )!,
      total: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}total'])!,
      hasUsage: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_usage'],
      )!,
      expire: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}expire']),
      supportUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}support_url'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }
}

class SubscriptionRow extends DataClass implements Insertable<SubscriptionRow> {
  final String id;
  final String name;

  /// Encrypted (the URL usually embeds an access token).
  final String urlEnc;
  final int? updatedAt;
  final int updateIntervalMinutes;
  final bool autoUpdate;
  final int upload;
  final int download;
  final int total;
  final bool hasUsage;
  final int? expire;
  final String? supportUrl;
  final int createdAt;
  const SubscriptionRow({
    required this.id,
    required this.name,
    required this.urlEnc,
    this.updatedAt,
    required this.updateIntervalMinutes,
    required this.autoUpdate,
    required this.upload,
    required this.download,
    required this.total,
    required this.hasUsage,
    this.expire,
    this.supportUrl,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['url_enc'] = Variable<String>(urlEnc);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    map['update_interval_minutes'] = Variable<int>(updateIntervalMinutes);
    map['auto_update'] = Variable<bool>(autoUpdate);
    map['upload'] = Variable<int>(upload);
    map['download'] = Variable<int>(download);
    map['total'] = Variable<int>(total);
    map['has_usage'] = Variable<bool>(hasUsage);
    if (!nullToAbsent || expire != null) {
      map['expire'] = Variable<int>(expire);
    }
    if (!nullToAbsent || supportUrl != null) {
      map['support_url'] = Variable<String>(supportUrl);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      id: Value(id),
      name: Value(name),
      urlEnc: Value(urlEnc),
      updatedAt: updatedAt == null && nullToAbsent ? const Value.absent() : Value(updatedAt),
      updateIntervalMinutes: Value(updateIntervalMinutes),
      autoUpdate: Value(autoUpdate),
      upload: Value(upload),
      download: Value(download),
      total: Value(total),
      hasUsage: Value(hasUsage),
      expire: expire == null && nullToAbsent ? const Value.absent() : Value(expire),
      supportUrl: supportUrl == null && nullToAbsent ? const Value.absent() : Value(supportUrl),
      createdAt: Value(createdAt),
    );
  }

  factory SubscriptionRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubscriptionRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      urlEnc: serializer.fromJson<String>(json['urlEnc']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      updateIntervalMinutes: serializer.fromJson<int>(json['updateIntervalMinutes']),
      autoUpdate: serializer.fromJson<bool>(json['autoUpdate']),
      upload: serializer.fromJson<int>(json['upload']),
      download: serializer.fromJson<int>(json['download']),
      total: serializer.fromJson<int>(json['total']),
      hasUsage: serializer.fromJson<bool>(json['hasUsage']),
      expire: serializer.fromJson<int?>(json['expire']),
      supportUrl: serializer.fromJson<String?>(json['supportUrl']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'urlEnc': serializer.toJson<String>(urlEnc),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'updateIntervalMinutes': serializer.toJson<int>(updateIntervalMinutes),
      'autoUpdate': serializer.toJson<bool>(autoUpdate),
      'upload': serializer.toJson<int>(upload),
      'download': serializer.toJson<int>(download),
      'total': serializer.toJson<int>(total),
      'hasUsage': serializer.toJson<bool>(hasUsage),
      'expire': serializer.toJson<int?>(expire),
      'supportUrl': serializer.toJson<String?>(supportUrl),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SubscriptionRow copyWith({
    String? id,
    String? name,
    String? urlEnc,
    Value<int?> updatedAt = const Value.absent(),
    int? updateIntervalMinutes,
    bool? autoUpdate,
    int? upload,
    int? download,
    int? total,
    bool? hasUsage,
    Value<int?> expire = const Value.absent(),
    Value<String?> supportUrl = const Value.absent(),
    int? createdAt,
  }) => SubscriptionRow(
    id: id ?? this.id,
    name: name ?? this.name,
    urlEnc: urlEnc ?? this.urlEnc,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    updateIntervalMinutes: updateIntervalMinutes ?? this.updateIntervalMinutes,
    autoUpdate: autoUpdate ?? this.autoUpdate,
    upload: upload ?? this.upload,
    download: download ?? this.download,
    total: total ?? this.total,
    hasUsage: hasUsage ?? this.hasUsage,
    expire: expire.present ? expire.value : this.expire,
    supportUrl: supportUrl.present ? supportUrl.value : this.supportUrl,
    createdAt: createdAt ?? this.createdAt,
  );
  SubscriptionRow copyWithCompanion(SubscriptionsCompanion data) {
    return SubscriptionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      urlEnc: data.urlEnc.present ? data.urlEnc.value : this.urlEnc,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updateIntervalMinutes: data.updateIntervalMinutes.present
          ? data.updateIntervalMinutes.value
          : this.updateIntervalMinutes,
      autoUpdate: data.autoUpdate.present ? data.autoUpdate.value : this.autoUpdate,
      upload: data.upload.present ? data.upload.value : this.upload,
      download: data.download.present ? data.download.value : this.download,
      total: data.total.present ? data.total.value : this.total,
      hasUsage: data.hasUsage.present ? data.hasUsage.value : this.hasUsage,
      expire: data.expire.present ? data.expire.value : this.expire,
      supportUrl: data.supportUrl.present ? data.supportUrl.value : this.supportUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('urlEnc: $urlEnc, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updateIntervalMinutes: $updateIntervalMinutes, ')
          ..write('autoUpdate: $autoUpdate, ')
          ..write('upload: $upload, ')
          ..write('download: $download, ')
          ..write('total: $total, ')
          ..write('hasUsage: $hasUsage, ')
          ..write('expire: $expire, ')
          ..write('supportUrl: $supportUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    urlEnc,
    updatedAt,
    updateIntervalMinutes,
    autoUpdate,
    upload,
    download,
    total,
    hasUsage,
    expire,
    supportUrl,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubscriptionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.urlEnc == this.urlEnc &&
          other.updatedAt == this.updatedAt &&
          other.updateIntervalMinutes == this.updateIntervalMinutes &&
          other.autoUpdate == this.autoUpdate &&
          other.upload == this.upload &&
          other.download == this.download &&
          other.total == this.total &&
          other.hasUsage == this.hasUsage &&
          other.expire == this.expire &&
          other.supportUrl == this.supportUrl &&
          other.createdAt == this.createdAt);
}

class SubscriptionsCompanion extends UpdateCompanion<SubscriptionRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> urlEnc;
  final Value<int?> updatedAt;
  final Value<int> updateIntervalMinutes;
  final Value<bool> autoUpdate;
  final Value<int> upload;
  final Value<int> download;
  final Value<int> total;
  final Value<bool> hasUsage;
  final Value<int?> expire;
  final Value<String?> supportUrl;
  final Value<int> createdAt;
  final Value<int> rowid;
  const SubscriptionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.urlEnc = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updateIntervalMinutes = const Value.absent(),
    this.autoUpdate = const Value.absent(),
    this.upload = const Value.absent(),
    this.download = const Value.absent(),
    this.total = const Value.absent(),
    this.hasUsage = const Value.absent(),
    this.expire = const Value.absent(),
    this.supportUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    required String id,
    required String name,
    required String urlEnc,
    this.updatedAt = const Value.absent(),
    this.updateIntervalMinutes = const Value.absent(),
    this.autoUpdate = const Value.absent(),
    this.upload = const Value.absent(),
    this.download = const Value.absent(),
    this.total = const Value.absent(),
    this.hasUsage = const Value.absent(),
    this.expire = const Value.absent(),
    this.supportUrl = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       urlEnc = Value(urlEnc),
       createdAt = Value(createdAt);
  static Insertable<SubscriptionRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? urlEnc,
    Expression<int>? updatedAt,
    Expression<int>? updateIntervalMinutes,
    Expression<bool>? autoUpdate,
    Expression<int>? upload,
    Expression<int>? download,
    Expression<int>? total,
    Expression<bool>? hasUsage,
    Expression<int>? expire,
    Expression<String>? supportUrl,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (urlEnc != null) 'url_enc': urlEnc,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updateIntervalMinutes != null) 'update_interval_minutes': updateIntervalMinutes,
      if (autoUpdate != null) 'auto_update': autoUpdate,
      if (upload != null) 'upload': upload,
      if (download != null) 'download': download,
      if (total != null) 'total': total,
      if (hasUsage != null) 'has_usage': hasUsage,
      if (expire != null) 'expire': expire,
      if (supportUrl != null) 'support_url': supportUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubscriptionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? urlEnc,
    Value<int?>? updatedAt,
    Value<int>? updateIntervalMinutes,
    Value<bool>? autoUpdate,
    Value<int>? upload,
    Value<int>? download,
    Value<int>? total,
    Value<bool>? hasUsage,
    Value<int?>? expire,
    Value<String?>? supportUrl,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return SubscriptionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      urlEnc: urlEnc ?? this.urlEnc,
      updatedAt: updatedAt ?? this.updatedAt,
      updateIntervalMinutes: updateIntervalMinutes ?? this.updateIntervalMinutes,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      upload: upload ?? this.upload,
      download: download ?? this.download,
      total: total ?? this.total,
      hasUsage: hasUsage ?? this.hasUsage,
      expire: expire ?? this.expire,
      supportUrl: supportUrl ?? this.supportUrl,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (urlEnc.present) {
      map['url_enc'] = Variable<String>(urlEnc.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updateIntervalMinutes.present) {
      map['update_interval_minutes'] = Variable<int>(updateIntervalMinutes.value);
    }
    if (autoUpdate.present) {
      map['auto_update'] = Variable<bool>(autoUpdate.value);
    }
    if (upload.present) {
      map['upload'] = Variable<int>(upload.value);
    }
    if (download.present) {
      map['download'] = Variable<int>(download.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (hasUsage.present) {
      map['has_usage'] = Variable<bool>(hasUsage.value);
    }
    if (expire.present) {
      map['expire'] = Variable<int>(expire.value);
    }
    if (supportUrl.present) {
      map['support_url'] = Variable<String>(supportUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('urlEnc: $urlEnc, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updateIntervalMinutes: $updateIntervalMinutes, ')
          ..write('autoUpdate: $autoUpdate, ')
          ..write('upload: $upload, ')
          ..write('download: $download, ')
          ..write('total: $total, ')
          ..write('hasUsage: $hasUsage, ')
          ..write('expire: $expire, ')
          ..write('supportUrl: $supportUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ServersTable extends Servers with TableInfo<$ServersTable, ServerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subscriptionIdMeta = const VerificationMeta('subscriptionId');
  @override
  late final GeneratedColumn<String> subscriptionId = GeneratedColumn<String>(
    'subscription_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subscriptions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protocolMeta = const VerificationMeta('protocol');
  @override
  late final GeneratedColumn<String> protocol = GeneratedColumn<String>(
    'protocol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta('favorite');
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("favorite" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortIndexMeta = const VerificationMeta('sortIndex');
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
    'sort_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _configEncMeta = const VerificationMeta('configEnc');
  @override
  late final GeneratedColumn<String> configEnc = GeneratedColumn<String>(
    'config_enc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subscriptionId,
    name,
    protocol,
    host,
    port,
    favorite,
    sortIndex,
    configEnc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'servers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subscription_id')) {
      context.handle(
        _subscriptionIdMeta,
        subscriptionId.isAcceptableOrUnknown(data['subscription_id']!, _subscriptionIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('protocol')) {
      context.handle(
        _protocolMeta,
        protocol.isAcceptableOrUnknown(data['protocol']!, _protocolMeta),
      );
    } else if (isInserting) {
      context.missing(_protocolMeta);
    }
    if (data.containsKey('host')) {
      context.handle(_hostMeta, host.isAcceptableOrUnknown(data['host']!, _hostMeta));
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('port')) {
      context.handle(_portMeta, port.isAcceptableOrUnknown(data['port']!, _portMeta));
    } else if (isInserting) {
      context.missing(_portMeta);
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('sort_index')) {
      context.handle(
        _sortIndexMeta,
        sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta),
      );
    }
    if (data.containsKey('config_enc')) {
      context.handle(
        _configEncMeta,
        configEnc.isAcceptableOrUnknown(data['config_enc']!, _configEncMeta),
      );
    } else if (isInserting) {
      context.missing(_configEncMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      subscriptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subscription_id'],
      ),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      protocol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol'],
      )!,
      host: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}host'])!,
      port: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}port'])!,
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      sortIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_index'],
      )!,
      configEnc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_enc'],
      )!,
    );
  }

  @override
  $ServersTable createAlias(String alias) {
    return $ServersTable(attachedDatabase, alias);
  }
}

class ServerRow extends DataClass implements Insertable<ServerRow> {
  final String id;
  final String? subscriptionId;
  final String name;
  final String protocol;
  final String host;
  final int port;
  final bool favorite;
  final int sortIndex;

  /// Encrypted OutboundConfig JSON (credentials, keys, TLS params).
  final String configEnc;
  const ServerRow({
    required this.id,
    this.subscriptionId,
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    required this.favorite,
    required this.sortIndex,
    required this.configEnc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || subscriptionId != null) {
      map['subscription_id'] = Variable<String>(subscriptionId);
    }
    map['name'] = Variable<String>(name);
    map['protocol'] = Variable<String>(protocol);
    map['host'] = Variable<String>(host);
    map['port'] = Variable<int>(port);
    map['favorite'] = Variable<bool>(favorite);
    map['sort_index'] = Variable<int>(sortIndex);
    map['config_enc'] = Variable<String>(configEnc);
    return map;
  }

  ServersCompanion toCompanion(bool nullToAbsent) {
    return ServersCompanion(
      id: Value(id),
      subscriptionId: subscriptionId == null && nullToAbsent
          ? const Value.absent()
          : Value(subscriptionId),
      name: Value(name),
      protocol: Value(protocol),
      host: Value(host),
      port: Value(port),
      favorite: Value(favorite),
      sortIndex: Value(sortIndex),
      configEnc: Value(configEnc),
    );
  }

  factory ServerRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerRow(
      id: serializer.fromJson<String>(json['id']),
      subscriptionId: serializer.fromJson<String?>(json['subscriptionId']),
      name: serializer.fromJson<String>(json['name']),
      protocol: serializer.fromJson<String>(json['protocol']),
      host: serializer.fromJson<String>(json['host']),
      port: serializer.fromJson<int>(json['port']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
      configEnc: serializer.fromJson<String>(json['configEnc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subscriptionId': serializer.toJson<String?>(subscriptionId),
      'name': serializer.toJson<String>(name),
      'protocol': serializer.toJson<String>(protocol),
      'host': serializer.toJson<String>(host),
      'port': serializer.toJson<int>(port),
      'favorite': serializer.toJson<bool>(favorite),
      'sortIndex': serializer.toJson<int>(sortIndex),
      'configEnc': serializer.toJson<String>(configEnc),
    };
  }

  ServerRow copyWith({
    String? id,
    Value<String?> subscriptionId = const Value.absent(),
    String? name,
    String? protocol,
    String? host,
    int? port,
    bool? favorite,
    int? sortIndex,
    String? configEnc,
  }) => ServerRow(
    id: id ?? this.id,
    subscriptionId: subscriptionId.present ? subscriptionId.value : this.subscriptionId,
    name: name ?? this.name,
    protocol: protocol ?? this.protocol,
    host: host ?? this.host,
    port: port ?? this.port,
    favorite: favorite ?? this.favorite,
    sortIndex: sortIndex ?? this.sortIndex,
    configEnc: configEnc ?? this.configEnc,
  );
  ServerRow copyWithCompanion(ServersCompanion data) {
    return ServerRow(
      id: data.id.present ? data.id.value : this.id,
      subscriptionId: data.subscriptionId.present ? data.subscriptionId.value : this.subscriptionId,
      name: data.name.present ? data.name.value : this.name,
      protocol: data.protocol.present ? data.protocol.value : this.protocol,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
      configEnc: data.configEnc.present ? data.configEnc.value : this.configEnc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerRow(')
          ..write('id: $id, ')
          ..write('subscriptionId: $subscriptionId, ')
          ..write('name: $name, ')
          ..write('protocol: $protocol, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('favorite: $favorite, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('configEnc: $configEnc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, subscriptionId, name, protocol, host, port, favorite, sortIndex, configEnc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerRow &&
          other.id == this.id &&
          other.subscriptionId == this.subscriptionId &&
          other.name == this.name &&
          other.protocol == this.protocol &&
          other.host == this.host &&
          other.port == this.port &&
          other.favorite == this.favorite &&
          other.sortIndex == this.sortIndex &&
          other.configEnc == this.configEnc);
}

class ServersCompanion extends UpdateCompanion<ServerRow> {
  final Value<String> id;
  final Value<String?> subscriptionId;
  final Value<String> name;
  final Value<String> protocol;
  final Value<String> host;
  final Value<int> port;
  final Value<bool> favorite;
  final Value<int> sortIndex;
  final Value<String> configEnc;
  final Value<int> rowid;
  const ServersCompanion({
    this.id = const Value.absent(),
    this.subscriptionId = const Value.absent(),
    this.name = const Value.absent(),
    this.protocol = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.favorite = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.configEnc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServersCompanion.insert({
    required String id,
    this.subscriptionId = const Value.absent(),
    required String name,
    required String protocol,
    required String host,
    required int port,
    this.favorite = const Value.absent(),
    this.sortIndex = const Value.absent(),
    required String configEnc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       protocol = Value(protocol),
       host = Value(host),
       port = Value(port),
       configEnc = Value(configEnc);
  static Insertable<ServerRow> custom({
    Expression<String>? id,
    Expression<String>? subscriptionId,
    Expression<String>? name,
    Expression<String>? protocol,
    Expression<String>? host,
    Expression<int>? port,
    Expression<bool>? favorite,
    Expression<int>? sortIndex,
    Expression<String>? configEnc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subscriptionId != null) 'subscription_id': subscriptionId,
      if (name != null) 'name': name,
      if (protocol != null) 'protocol': protocol,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (favorite != null) 'favorite': favorite,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (configEnc != null) 'config_enc': configEnc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServersCompanion copyWith({
    Value<String>? id,
    Value<String?>? subscriptionId,
    Value<String>? name,
    Value<String>? protocol,
    Value<String>? host,
    Value<int>? port,
    Value<bool>? favorite,
    Value<int>? sortIndex,
    Value<String>? configEnc,
    Value<int>? rowid,
  }) {
    return ServersCompanion(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      host: host ?? this.host,
      port: port ?? this.port,
      favorite: favorite ?? this.favorite,
      sortIndex: sortIndex ?? this.sortIndex,
      configEnc: configEnc ?? this.configEnc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subscriptionId.present) {
      map['subscription_id'] = Variable<String>(subscriptionId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (protocol.present) {
      map['protocol'] = Variable<String>(protocol.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (configEnc.present) {
      map['config_enc'] = Variable<String>(configEnc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServersCompanion(')
          ..write('id: $id, ')
          ..write('subscriptionId: $subscriptionId, ')
          ..write('name: $name, ')
          ..write('protocol: $protocol, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('favorite: $favorite, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('configEnc: $configEnc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  late final $ServersTable servers = $ServersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [subscriptions, servers];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('subscriptions', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('servers', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SubscriptionsTableCreateCompanionBuilder = SubscriptionsCompanion Function({
  required String id,
  required String name,
  required String urlEnc,
  Value<int?> updatedAt,
  Value<int> updateIntervalMinutes,
  Value<bool> autoUpdate,
  Value<int> upload,
  Value<int> download,
  Value<int> total,
  Value<bool> hasUsage,
  Value<int?> expire,
  Value<String?> supportUrl,
  required int createdAt,
  Value<int> rowid,
});
typedef $$SubscriptionsTableUpdateCompanionBuilder = SubscriptionsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> urlEnc,
  Value<int?> updatedAt,
  Value<int> updateIntervalMinutes,
  Value<bool> autoUpdate,
  Value<int> upload,
  Value<int> download,
  Value<int> total,
  Value<bool> hasUsage,
  Value<int?> expire,
  Value<String?> supportUrl,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$SubscriptionsTableReferences
    extends BaseReferences<_$AppDatabase, $SubscriptionsTable, SubscriptionRow> {
  $$SubscriptionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ServersTable, List<ServerRow>> _serversRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.servers,
        aliasName: 'subscriptions__id__servers__subscription_id',
      );

  $$ServersTableProcessedTableManager get serversRefs {
    final manager = $$ServersTableTableManager(
      $_db,
      $_db.servers,
    ).filter((f) => f.subscriptionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_serversRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SubscriptionsTableFilterComposer extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get urlEnc =>
      $composableBuilder(column: $table.urlEnc, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updateIntervalMinutes => $composableBuilder(
    column: $table.updateIntervalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoUpdate =>
      $composableBuilder(column: $table.autoUpdate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get upload =>
      $composableBuilder(column: $table.upload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get download =>
      $composableBuilder(column: $table.download, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasUsage =>
      $composableBuilder(column: $table.hasUsage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expire =>
      $composableBuilder(column: $table.expire, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supportUrl =>
      $composableBuilder(column: $table.supportUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> serversRefs(Expression<bool> Function($$ServersTableFilterComposer f) f) {
    final $$ServersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.servers,
      getReferencedColumn: (t) => t.subscriptionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ServersTableFilterComposer(
            $db: $db,
            $table: $db.servers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubscriptionsTableOrderingComposer extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get urlEnc =>
      $composableBuilder(column: $table.urlEnc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updateIntervalMinutes => $composableBuilder(
    column: $table.updateIntervalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoUpdate =>
      $composableBuilder(column: $table.autoUpdate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get upload =>
      $composableBuilder(column: $table.upload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get download =>
      $composableBuilder(column: $table.download, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasUsage =>
      $composableBuilder(column: $table.hasUsage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expire =>
      $composableBuilder(column: $table.expire, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supportUrl =>
      $composableBuilder(column: $table.supportUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SubscriptionsTableAnnotationComposer extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get urlEnc =>
      $composableBuilder(column: $table.urlEnc, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get updateIntervalMinutes =>
      $composableBuilder(column: $table.updateIntervalMinutes, builder: (column) => column);

  GeneratedColumn<bool> get autoUpdate =>
      $composableBuilder(column: $table.autoUpdate, builder: (column) => column);

  GeneratedColumn<int> get upload =>
      $composableBuilder(column: $table.upload, builder: (column) => column);

  GeneratedColumn<int> get download =>
      $composableBuilder(column: $table.download, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<bool> get hasUsage =>
      $composableBuilder(column: $table.hasUsage, builder: (column) => column);

  GeneratedColumn<int> get expire =>
      $composableBuilder(column: $table.expire, builder: (column) => column);

  GeneratedColumn<String> get supportUrl =>
      $composableBuilder(column: $table.supportUrl, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> serversRefs<T extends Object>(
    Expression<T> Function($$ServersTableAnnotationComposer a) f,
  ) {
    final $$ServersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.servers,
      getReferencedColumn: (t) => t.subscriptionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ServersTableAnnotationComposer(
            $db: $db,
            $table: $db.servers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubscriptionsTable,
          SubscriptionRow,
          $$SubscriptionsTableFilterComposer,
          $$SubscriptionsTableOrderingComposer,
          $$SubscriptionsTableAnnotationComposer,
          $$SubscriptionsTableCreateCompanionBuilder,
          $$SubscriptionsTableUpdateCompanionBuilder,
          (SubscriptionRow, $$SubscriptionsTableReferences),
          SubscriptionRow,
          PrefetchHooks Function({bool serversRefs})
        > {
  $$SubscriptionsTableTableManager(_$AppDatabase db, $SubscriptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> urlEnc = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int> updateIntervalMinutes = const Value.absent(),
                Value<bool> autoUpdate = const Value.absent(),
                Value<int> upload = const Value.absent(),
                Value<int> download = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<bool> hasUsage = const Value.absent(),
                Value<int?> expire = const Value.absent(),
                Value<String?> supportUrl = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsCompanion(
                id: id,
                name: name,
                urlEnc: urlEnc,
                updatedAt: updatedAt,
                updateIntervalMinutes: updateIntervalMinutes,
                autoUpdate: autoUpdate,
                upload: upload,
                download: download,
                total: total,
                hasUsage: hasUsage,
                expire: expire,
                supportUrl: supportUrl,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String urlEnc,
                Value<int?> updatedAt = const Value.absent(),
                Value<int> updateIntervalMinutes = const Value.absent(),
                Value<bool> autoUpdate = const Value.absent(),
                Value<int> upload = const Value.absent(),
                Value<int> download = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<bool> hasUsage = const Value.absent(),
                Value<int?> expire = const Value.absent(),
                Value<String?> supportUrl = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsCompanion.insert(
                id: id,
                name: name,
                urlEnc: urlEnc,
                updatedAt: updatedAt,
                updateIntervalMinutes: updateIntervalMinutes,
                autoUpdate: autoUpdate,
                upload: upload,
                download: download,
                total: total,
                hasUsage: hasUsage,
                expire: expire,
                supportUrl: supportUrl,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubscriptionsTable, SubscriptionRow>(table),
                  $$SubscriptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({serversRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (serversRefs) db.servers],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (serversRefs)
                    await $_getPrefetchedData<SubscriptionRow, $SubscriptionsTable, ServerRow>(
                      currentTable: table,
                      referencedTable: $$SubscriptionsTableReferences._serversRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SubscriptionsTableReferences(db, table, p0).serversRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.subscriptionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubscriptionsTable,
      SubscriptionRow,
      $$SubscriptionsTableFilterComposer,
      $$SubscriptionsTableOrderingComposer,
      $$SubscriptionsTableAnnotationComposer,
      $$SubscriptionsTableCreateCompanionBuilder,
      $$SubscriptionsTableUpdateCompanionBuilder,
      (SubscriptionRow, $$SubscriptionsTableReferences),
      SubscriptionRow,
      PrefetchHooks Function({bool serversRefs})
    >;
typedef $$ServersTableCreateCompanionBuilder = ServersCompanion Function({
  required String id,
  Value<String?> subscriptionId,
  required String name,
  required String protocol,
  required String host,
  required int port,
  Value<bool> favorite,
  Value<int> sortIndex,
  required String configEnc,
  Value<int> rowid,
});
typedef $$ServersTableUpdateCompanionBuilder = ServersCompanion Function({
  Value<String> id,
  Value<String?> subscriptionId,
  Value<String> name,
  Value<String> protocol,
  Value<String> host,
  Value<int> port,
  Value<bool> favorite,
  Value<int> sortIndex,
  Value<String> configEnc,
  Value<int> rowid,
});

final class $$ServersTableReferences
    extends BaseReferences<_$AppDatabase, $ServersTable, ServerRow> {
  $$ServersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SubscriptionsTable _subscriptionIdTable(_$AppDatabase db) =>
      db.subscriptions.createAlias('servers__subscription_id__subscriptions__id');

  $$SubscriptionsTableProcessedTableManager? get subscriptionId {
    final $_column = $_itemColumn<String>('subscription_id');
    if ($_column == null) return null;
    final manager = $$SubscriptionsTableTableManager(
      $_db,
      $_db.subscriptions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subscriptionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ServersTableFilterComposer extends Composer<_$AppDatabase, $ServersTable> {
  $$ServersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get protocol =>
      $composableBuilder(column: $table.protocol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get configEnc =>
      $composableBuilder(column: $table.configEnc, builder: (column) => ColumnFilters(column));

  $$SubscriptionsTableFilterComposer get subscriptionId {
    final $$SubscriptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subscriptionId,
      referencedTable: $db.subscriptions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SubscriptionsTableFilterComposer(
            $db: $db,
            $table: $db.subscriptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServersTableOrderingComposer extends Composer<_$AppDatabase, $ServersTable> {
  $$ServersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get protocol =>
      $composableBuilder(column: $table.protocol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get configEnc =>
      $composableBuilder(column: $table.configEnc, builder: (column) => ColumnOrderings(column));

  $$SubscriptionsTableOrderingComposer get subscriptionId {
    final $$SubscriptionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subscriptionId,
      referencedTable: $db.subscriptions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SubscriptionsTableOrderingComposer(
            $db: $db,
            $table: $db.subscriptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServersTableAnnotationComposer extends Composer<_$AppDatabase, $ServersTable> {
  $$ServersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get protocol =>
      $composableBuilder(column: $table.protocol, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  GeneratedColumn<String> get configEnc =>
      $composableBuilder(column: $table.configEnc, builder: (column) => column);

  $$SubscriptionsTableAnnotationComposer get subscriptionId {
    final $$SubscriptionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subscriptionId,
      referencedTable: $db.subscriptions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SubscriptionsTableAnnotationComposer(
            $db: $db,
            $table: $db.subscriptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ServersTable,
          ServerRow,
          $$ServersTableFilterComposer,
          $$ServersTableOrderingComposer,
          $$ServersTableAnnotationComposer,
          $$ServersTableCreateCompanionBuilder,
          $$ServersTableUpdateCompanionBuilder,
          (ServerRow, $$ServersTableReferences),
          ServerRow,
          PrefetchHooks Function({bool subscriptionId})
        > {
  $$ServersTableTableManager(_$AppDatabase db, $ServersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ServersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ServersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> subscriptionId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> protocol = const Value.absent(),
                Value<String> host = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<int> sortIndex = const Value.absent(),
                Value<String> configEnc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServersCompanion(
                id: id,
                subscriptionId: subscriptionId,
                name: name,
                protocol: protocol,
                host: host,
                port: port,
                favorite: favorite,
                sortIndex: sortIndex,
                configEnc: configEnc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> subscriptionId = const Value.absent(),
                required String name,
                required String protocol,
                required String host,
                required int port,
                Value<bool> favorite = const Value.absent(),
                Value<int> sortIndex = const Value.absent(),
                required String configEnc,
                Value<int> rowid = const Value.absent(),
              }) => ServersCompanion.insert(
                id: id,
                subscriptionId: subscriptionId,
                name: name,
                protocol: protocol,
                host: host,
                port: port,
                favorite: favorite,
                sortIndex: sortIndex,
                configEnc: configEnc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ServersTable, ServerRow>(table),
                  $$ServersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({subscriptionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (subscriptionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.subscriptionId,
                        referencedTable: $$ServersTableReferences._subscriptionIdTable(db),
                        referencedColumn: $$ServersTableReferences._subscriptionIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ServersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ServersTable,
      ServerRow,
      $$ServersTableFilterComposer,
      $$ServersTableOrderingComposer,
      $$ServersTableAnnotationComposer,
      $$ServersTableCreateCompanionBuilder,
      $$ServersTableUpdateCompanionBuilder,
      (ServerRow, $$ServersTableReferences),
      ServerRow,
      PrefetchHooks Function({bool subscriptionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db, _db.subscriptions);
  $$ServersTableTableManager get servers => $$ServersTableTableManager(_db, _db.servers);
}
