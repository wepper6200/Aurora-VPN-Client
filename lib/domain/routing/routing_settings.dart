enum RoutingMode { global, rules, direct }

enum SplitTunnelMode {
  /// Every app goes through the tunnel.
  off,

  /// Only the selected apps go through the tunnel.
  include,

  /// Every app except the selected ones goes through the tunnel.
  exclude,
}

class RoutingSettings {
  const RoutingSettings({
    this.mode = RoutingMode.rules,
    this.bypassLan = true,
    this.ruDirect = false,
    this.blockAds = false,
    this.splitMode = SplitTunnelMode.off,
    this.splitApps = const {},
  });

  final RoutingMode mode;
  final bool bypassLan;

  /// geoip:ru + geosite:category-ru go direct.
  final bool ruDirect;
  final bool blockAds;
  final SplitTunnelMode splitMode;

  /// Android package names.
  final Set<String> splitApps;

  RoutingSettings copyWith({
    RoutingMode? mode,
    bool? bypassLan,
    bool? ruDirect,
    bool? blockAds,
    SplitTunnelMode? splitMode,
    Set<String>? splitApps,
  }) {
    return RoutingSettings(
      mode: mode ?? this.mode,
      bypassLan: bypassLan ?? this.bypassLan,
      ruDirect: ruDirect ?? this.ruDirect,
      blockAds: blockAds ?? this.blockAds,
      splitMode: splitMode ?? this.splitMode,
      splitApps: splitApps ?? this.splitApps,
    );
  }
}

/// An app installed on the device (Android split tunneling).
class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.label,
    this.isSystem = false,
    this.icon,
  });

  final String packageName;
  final String label;
  final bool isSystem;

  /// PNG bytes, loaded lazily on Android.
  final List<int>? icon;
}
