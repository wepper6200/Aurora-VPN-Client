import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/servers/server_profile.dart';
import '../parsers/import_item.dart';
import '../parsers/subscription_parser.dart';

class FetchedSubscription {
  const FetchedSubscription({required this.meta, required this.outcome});

  final SubscriptionMeta meta;
  final ParseOutcome outcome;
}

enum SubscriptionError {
  invalidUrl,
  network,
  http,
  tooLarge,

  /// The provider answered with a web page instead of a subscription.
  htmlPage,

  /// The provider only served a placeholder server ("client not supported",
  /// "update your app"…): it restricts which apps may use the subscription.
  clientNotSupported,

  /// Nothing recognizable in the response.
  unsupportedFormat,
}

class SubscriptionFetchException implements Exception {
  const SubscriptionFetchException(this.code, this.message, {this.detail});

  final SubscriptionError code;

  /// Technical description (logs, fallback text).
  final String message;

  /// Provider-supplied text, e.g. the placeholder server's name.
  final String? detail;

  @override
  String toString() => message;
}

/// Downloads and parses a subscription URL.
class SubscriptionFetcher {
  SubscriptionFetcher({http.Client? client, required this.userAgent, this.extraHeaders = _none})
    : _client = client ?? http.Client();

  static Future<Map<String, String>> _none() async => const {};

  final http.Client _client;

  /// Identifies the client honestly; panels pick the response format by UA
  /// and fall back to a base64 link list for unknown clients.
  final String userAgent;

  /// Additional headers per request (e.g. HWID for device-limited panels).
  final Future<Map<String, String>> Function() extraHeaders;

  static const timeout = Duration(seconds: 20);
  static const maxBytes = 8 * 1024 * 1024;

  Future<FetchedSubscription> fetch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      throw const SubscriptionFetchException(SubscriptionError.invalidUrl, 'invalid URL');
    }
    final extra = await extraHeaders();
    final http.Response res;
    try {
      res = await _client
          .get(uri, headers: {...extra, 'User-Agent': userAgent, 'Accept': '*/*'})
          .timeout(timeout);
    } on Exception catch (e) {
      throw SubscriptionFetchException(
        SubscriptionError.network,
        'network error: ${e.runtimeType}',
      );
    }
    if (res.statusCode != 200) {
      throw SubscriptionFetchException(SubscriptionError.http, 'HTTP ${res.statusCode}');
    }
    if (res.bodyBytes.length > maxBytes) {
      throw const SubscriptionFetchException(SubscriptionError.tooLarge, 'response too large');
    }

    final body = utf8.decode(res.bodyBytes, allowMalformed: true);
    final outcome = SubscriptionParser.parse(body);
    // A subscription must contain servers, not more subscription URLs.
    final servers = outcome.servers;
    if (servers.isEmpty && outcome.failures.isEmpty) {
      final html =
          (res.headers['content-type'] ?? '').contains('html') ||
          body.trimLeft().toLowerCase().startsWith('<!doctype html') ||
          body.trimLeft().toLowerCase().startsWith('<html');
      throw html
          ? const SubscriptionFetchException(SubscriptionError.htmlPage, 'got a web page')
          : const SubscriptionFetchException(
              SubscriptionError.unsupportedFormat,
              'no supported servers in the response',
            );
    }
    if (servers.isNotEmpty && servers.every((s) => isPlaceholder(s.outbound))) {
      throw SubscriptionFetchException(
        SubscriptionError.clientNotSupported,
        'provider returned only a placeholder server',
        detail: servers.first.name,
      );
    }
    return FetchedSubscription(
      meta: SubscriptionMeta.fromHeaders(res.headers),
      outcome: ParseOutcome(items: servers, failures: outcome.failures),
    );
  }

  /// Dummy entries panels serve to clients they don't support: unroutable
  /// address or a port no real server uses.
  static bool isPlaceholder(OutboundConfig outbound) {
    final host = outbound.host.toLowerCase();
    final port = outbound.port;
    return port <= 1 ||
        const {'0.0.0.0', '127.0.0.1', '::', '::1', 'localhost'}.contains(host) ||
        host.endsWith('.invalid');
  }

  void close() => _client.close();
}
