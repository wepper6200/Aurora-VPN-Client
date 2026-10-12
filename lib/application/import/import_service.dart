import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ids.dart';
import '../../data/parsers/import_item.dart';
import '../../data/parsers/subscription_parser.dart';
import '../../data/subscriptions/subscription_fetcher.dart';
import '../../domain/servers/server_profile.dart';
import '../di.dart';
import '../servers/servers_controller.dart';
import '../subscriptions/subscription_service.dart';

class ImportReport {
  const ImportReport({this.servers = 0, this.subscriptions = 0, this.failures = const []});

  final int servers;
  final int subscriptions;

  /// Human-readable reasons for items that couldn't be imported.
  final List<String> failures;

  int get total => servers + subscriptions;
  bool get isEmpty => total == 0;
}

final importServiceProvider = Provider<ImportService>(ImportService.new);

/// Imports whatever the user pasted, scanned or opened via a deep link:
/// subscription URLs, `happ://add/` links, share links, sing-box JSON or
/// Clash YAML.
class ImportService {
  ImportService(this._ref);

  final Ref _ref;

  Future<ImportReport> importText(String text) async {
    final outcome = SubscriptionParser.parse(text);
    final failures = [for (final f in outcome.failures) f.reason];

    var subs = 0;
    final existingUrls = {
      for (final s in _ref.read(subscriptionsProvider).value ?? const []) s.url,
    };
    for (final item in outcome.subscriptions) {
      if (existingUrls.contains(item.url)) continue;
      try {
        await _ref.read(subscriptionServiceProvider).add(url: item.url, name: item.name);
        subs++;
      } on SubscriptionFetchException catch (e) {
        failures.add(e.message);
      }
    }

    final servers = outcome.servers;
    if (servers.isNotEmpty) {
      final manualCount = (_ref.read(serversProvider).value ?? const [])
          .where((s) => s.subscriptionId == null)
          .length;
      await _ref.read(serverRepositoryProvider).upsertAll([
        for (var i = 0; i < servers.length; i++)
          ServerProfile(
            id: newId(),
            name: servers[i].name,
            outbound: servers[i].outbound,
            sortIndex: manualCount + i,
          ),
      ]);
    }
    return ImportReport(servers: servers.length, subscriptions: subs, failures: failures);
  }
}

/// Convenience for single parsed items (e.g. the editor's "paste link").
ServerItem? tryParseServer(String text) {
  final outcome = SubscriptionParser.parse(text);
  return outcome.servers.isEmpty ? null : outcome.servers.first;
}
