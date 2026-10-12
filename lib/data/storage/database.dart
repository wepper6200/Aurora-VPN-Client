import 'package:drift/drift.dart';

part 'database.g.dart';

@DataClassName('SubscriptionRow')
class Subscriptions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Encrypted (the URL usually embeds an access token).
  TextColumn get urlEnc => text()();
  IntColumn get updatedAt => integer().nullable()();
  IntColumn get updateIntervalMinutes => integer().withDefault(const Constant(720))();
  BoolColumn get autoUpdate => boolean().withDefault(const Constant(true))();
  IntColumn get upload => integer().withDefault(const Constant(0))();
  IntColumn get download => integer().withDefault(const Constant(0))();
  IntColumn get total => integer().withDefault(const Constant(0))();
  BoolColumn get hasUsage => boolean().withDefault(const Constant(false))();
  IntColumn get expire => integer().nullable()();
  TextColumn get supportUrl => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ServerRow')
class Servers extends Table {
  TextColumn get id => text()();
  TextColumn get subscriptionId =>
      text().nullable().references(Subscriptions, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get protocol => text()();
  TextColumn get host => text()();
  IntColumn get port => integer()();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();

  /// Encrypted OutboundConfig JSON (credentials, keys, TLS params).
  TextColumn get configEnc => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Subscriptions, Servers])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
