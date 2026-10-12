import 'dart:convert';

import 'package:http/http.dart' as http;

import '../parsers/import_item.dart';
import '../parsers/subscription_parser.dart';

class FetchedSubscription {
  const FetchedSubscription({required this.meta, required this.outcome});

  final SubscriptionMeta meta;
  final ParseOutcome outcome;
}

class SubscriptionFetchException implements Exception {
  const SubscriptionFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Downloads and parses a subscription URL.
class SubscriptionFetcher {
  SubscriptionFetcher({http.Client? client, required this.userAgent})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Identifies the client honestly; panels pick the response format by UA
  /// and fall back to a base64 link list for unknown clients.
  final String userAgent;

  static const timeout = Duration(seconds: 20);
  static const maxBytes = 8 * 1024 * 1024;

  Future<FetchedSubscription> fetch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      throw const SubscriptionFetchException('invalid URL');
    }
    final http.Response res;
    try {
      res = await _client
          .get(uri, headers: {'User-Agent': userAgent, 'Accept': '*/*'})
          .timeout(timeout);
    } on Exception catch (e) {
      throw SubscriptionFetchException('network error: ${e.runtimeType}');
    }
    if (res.statusCode != 200) throw SubscriptionFetchException('HTTP ${res.statusCode}');
    if (res.bodyBytes.length > maxBytes) {
      throw const SubscriptionFetchException('response too large');
    }

    final body = utf8.decode(res.bodyBytes, allowMalformed: true);
    final outcome = SubscriptionParser.parse(body);
    // A subscription must contain servers, not more subscription URLs.
    final servers = ParseOutcome(items: outcome.servers, failures: outcome.failures);
    if (servers.items.isEmpty && servers.failures.isEmpty) {
      throw const SubscriptionFetchException('no supported servers in the response');
    }
    return FetchedSubscription(meta: SubscriptionMeta.fromHeaders(res.headers), outcome: servers);
  }

  void close() => _client.close();
}
