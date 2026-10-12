import 'dart:convert';

import '../../domain/servers/server_profile.dart';

/// Something recognized in imported text.
sealed class ImportItem {
  const ImportItem();
}

/// A single proxy endpoint.
class ServerItem extends ImportItem {
  const ServerItem({required this.name, required this.outbound});

  final String name;
  final OutboundConfig outbound;

  @override
  String toString() =>
      'ServerItem($name, ${outbound.protocol.name}://${outbound.host}:${outbound.port})';
}

/// A subscription URL to fetch (plain http(s) or `happ://add/…`).
class SubscriptionItem extends ImportItem {
  const SubscriptionItem({required this.url, this.name});

  final String url;
  final String? name;
}

class LinkParseException implements Exception {
  const LinkParseException(this.reason, [this.input]);

  final String reason;
  final String? input;

  @override
  String toString() => 'LinkParseException: $reason';
}

/// Result of parsing a blob that may contain many items.
class ParseOutcome {
  const ParseOutcome({this.items = const [], this.failures = const []});

  final List<ImportItem> items;

  /// Lines that looked like links but couldn't be parsed.
  final List<LinkParseException> failures;

  List<ServerItem> get servers => items.whereType<ServerItem>().toList();
  List<SubscriptionItem> get subscriptions => items.whereType<SubscriptionItem>().toList();
  bool get isEmpty => items.isEmpty;
}

/// Lenient base64: standard or URL-safe alphabet, optional padding, embedded
/// whitespace. Returns `null` if [s] is not base64.
String? tryDecodeBase64(String s) {
  var t = s.replaceAll(RegExp(r'\s'), '');
  if (t.isEmpty || !RegExp(r'^[A-Za-z0-9+/_-]+=*$').hasMatch(t)) return null;
  t = t.replaceAll('-', '+').replaceAll('_', '/').replaceAll('=', '');
  final pad = t.length % 4;
  if (pad == 1) return null;
  if (pad != 0) t += '=' * (4 - pad);
  try {
    return utf8.decode(base64.decode(t));
  } on FormatException {
    return null;
  }
}

/// Percent-decoding that never throws (malformed escapes are kept as-is).
String safeDecode(String s) {
  try {
    return Uri.decodeComponent(s);
  } on ArgumentError {
    return s;
  } on FormatException {
    return s;
  }
}
