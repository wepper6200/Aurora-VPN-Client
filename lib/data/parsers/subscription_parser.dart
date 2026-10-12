import 'dart:convert';

import 'package:yaml/yaml.dart';

import '../../domain/subscriptions/subscription.dart';
import 'clash_yaml_parser.dart';
import 'import_item.dart';
import 'link_parser.dart';
import 'singbox_json_parser.dart';
import 'xray_json_parser.dart';

/// Detects the format of subscription bodies / pasted text and extracts
/// every importable item.
///
/// Supported: base64 link lists, plain link lists, Xray JSON, sing-box JSON, Clash YAML,
/// a single http(s) URL (as a subscription).
abstract final class SubscriptionParser {
  static ParseOutcome parse(String text) {
    final body = text.trim().replaceFirst('\uFEFF', '');
    if (body.isEmpty) return const ParseOutcome();

    // JSON: Xray (array of configs or one config; outbounds use "protocol")
    // or sing-box (outbounds use "type").
    if (body.startsWith('{') || body.startsWith('[')) {
      try {
        final json = jsonDecode(body);
        if (XrayJsonParser.looksLikeXray(json)) return XrayJsonParser.parse(json);
        if (json is Map && (json.containsKey('outbounds') || json.containsKey('endpoints'))) {
          return SingBoxJsonParser.parse(json.cast<String, Object?>());
        }
      } on FormatException {
        // fall through
      }
    }

    // Plain list of links (or a single URL).
    final plain = _lines(body);
    if (plain.items.isNotEmpty || plain.failures.isNotEmpty) return plain;

    // Base64-encoded list.
    final decoded = tryDecodeBase64(body);
    if (decoded != null) {
      final inner = _lines(decoded);
      if (inner.items.isNotEmpty || inner.failures.isNotEmpty) return inner;
    }

    // Clash YAML
    if (body.contains('proxies:')) {
      try {
        final doc = loadYaml(body);
        if (doc is YamlMap) return ClashYamlParser.parse(_plainMap(doc));
      } on YamlException {
        // fall through
      }
    }
    return const ParseOutcome();
  }

  static ParseOutcome _lines(String text) {
    final items = <ImportItem>[];
    final failures = <LinkParseException>[];
    for (final raw in const LineSplitter().convert(text)) {
      final line = raw.replaceAll('\uFEFF', '').trim();
      if (line.isEmpty) continue;
      if (LinkParser.looksLikeLink(line)) {
        try {
          items.add(LinkParser.parse(line));
        } on LinkParseException catch (e) {
          failures.add(e);
        }
      } else if (_isHttpUrl(line)) {
        items.add(SubscriptionItem(url: line));
      }
    }
    return ParseOutcome(items: items, failures: failures);
  }

  static bool _isHttpUrl(String s) {
    final uri = Uri.tryParse(s);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  /// YamlMap/YamlList → plain Map/List so parsers can use casts.
  static Map<String, Object?> _plainMap(YamlMap m) => {
    for (final e in m.entries) '${e.key}': _plain(e.value),
  };

  static Object? _plain(Object? v) => switch (v) {
    final YamlMap m => _plainMap(m),
    final YamlList l => [for (final e in l) _plain(e)],
    _ => v,
  };
}

/// Metadata from subscription response headers.
class SubscriptionMeta {
  const SubscriptionMeta({
    this.title,
    this.updateInterval,
    this.usage,
    this.supportUrl,
    this.webPageUrl,
  });

  final String? title;
  final Duration? updateInterval;
  final SubscriptionUsage? usage;
  final String? supportUrl;
  final String? webPageUrl;

  /// [headers] with lower-case keys (as `package:http` provides them).
  factory SubscriptionMeta.fromHeaders(Map<String, String> headers) {
    String? h(String k) {
      final v = headers[k]?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    return SubscriptionMeta(
      title: _title(h('profile-title')) ?? _filename(h('content-disposition')),
      updateInterval: switch (int.tryParse(h('profile-update-interval') ?? '')) {
        final int hours when hours > 0 => Duration(hours: hours),
        _ => null,
      },
      usage: parseUserInfo(h('subscription-userinfo')),
      supportUrl: h('support-url'),
      webPageUrl: h('profile-web-page-url'),
    );
  }

  /// `upload=1; download=2; total=3; expire=1700000000`
  static SubscriptionUsage? parseUserInfo(String? value) {
    if (value == null) return null;
    final m = <String, int>{};
    for (final part in value.split(';')) {
      final kv = part.split('=');
      if (kv.length != 2) continue;
      final n = num.tryParse(kv[1].trim());
      if (n != null) m[kv[0].trim().toLowerCase()] = n.toInt();
    }
    if (m.isEmpty) return null;
    final expire = m['expire'] ?? 0;
    return SubscriptionUsage(
      upload: m['upload'] ?? 0,
      download: m['download'] ?? 0,
      total: m['total'] ?? 0,
      expire: expire > 0 ? DateTime.fromMillisecondsSinceEpoch(expire * 1000, isUtc: true) : null,
    );
  }

  /// `profile-title` may be plain or `base64:<data>`.
  static String? _title(String? v) {
    if (v == null) return null;
    if (v.toLowerCase().startsWith('base64:')) return tryDecodeBase64(v.substring(7))?.trim();
    return v;
  }

  /// `attachment; filename*=UTF-8''My%20Sub` or `filename="My Sub"`.
  static String? _filename(String? v) {
    if (v == null) return null;
    final star = RegExp(r"filename\*\s*=\s*[^']*''([^;]+)", caseSensitive: false).firstMatch(v);
    if (star != null) return safeDecode(star.group(1)!.trim());
    final plain = RegExp(r'filename\s*=\s*"?([^";]+)"?', caseSensitive: false).firstMatch(v);
    return plain?.group(1)?.trim();
  }
}
