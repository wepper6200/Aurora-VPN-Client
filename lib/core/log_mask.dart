/// Removes secrets from core log lines before they reach the UI, the
/// clipboard or an exported file.
abstract final class LogMask {
  static final _rules = <(RegExp, String Function(Match))>[
    // UUIDs (VLESS/VMess/TUIC user ids).
    (
      RegExp(r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b'),
      (m) => '${m[0]!.substring(0, 4)}****-****',
    ),
    // key=value / "key": "value" for credential-like keys.
    (
      RegExp(
        r'''("?(?:password|passwd|pass|psk|secret|token|private_key|privateKey|pre_shared_key|uuid|auth|obfs-password|public_key|short_id)"?\s*[:=]\s*"?)([^"\s,&;}]+)''',
        caseSensitive: false,
      ),
      (m) => '${m[1]}***',
    ),
    // Credentials in URLs: scheme://user:pass@host or scheme://secret@host.
    (RegExp(r'([a-z][a-z0-9+.-]*://)([^/@\s]+)@'), (m) => '${m[1]}***@'),
    // Long base64/hex blobs (keys, tokens) — 32+ chars, no dots so domains survive.
    (RegExp(r'\b[A-Za-z0-9+/_-]{32,}={0,2}'), (_) => '***'),
  ];

  static String apply(String line) {
    var out = line;
    for (final (re, replace) in _rules) {
      out = out.replaceAllMapped(re, replace);
    }
    return out;
  }
}
