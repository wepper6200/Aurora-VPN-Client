import '../logs/log_entry.dart';

enum ThemePreference { system, light, dark }

/// Visual language of the whole app, picked during onboarding.
enum DesignStyle { material, glass }

enum LanguagePreference {
  system(null),
  en('en'),
  ru('ru');

  const LanguagePreference(this.code);

  /// ISO language code, `null` means "follow the OS".
  final String? code;
}

/// How the Windows client captures traffic.
enum WindowsTunnelMode {
  /// Sets the system HTTP/SOCKS proxy; no admin rights needed.
  systemProxy,

  /// Wintun virtual adapter; captures all traffic, needs admin rights.
  tun,
}

enum DnsProtocol { doh, dot, udp }

/// User-facing preferences. Non-sensitive only — stored in SharedPreferences.
class AppSettings {
  const AppSettings({
    this.theme = ThemePreference.dark,
    this.designStyle = DesignStyle.material,
    this.language = LanguagePreference.system,
    this.onboardingDone = false,
    this.autoConnect = false,
    this.launchAtStartup = false,
    this.killSwitch = false,
    this.windowsMode = WindowsTunnelMode.systemProxy,
    this.dnsProtocol = DnsProtocol.doh,
    this.dnsServer = defaultDnsServer,
    this.mtu = 9000,
    this.ipv6 = false,
    this.logLevel = LogLevel.info,
    this.autoUpdateSubscriptions = true,
    this.sendHwid = true,
  });

  static const defaultDnsServer = 'https://1.1.1.1/dns-query';

  final ThemePreference theme;
  final DesignStyle designStyle;
  final LanguagePreference language;
  final bool onboardingDone;
  final bool autoConnect;
  final bool launchAtStartup;
  final bool killSwitch;
  final WindowsTunnelMode windowsMode;
  final DnsProtocol dnsProtocol;
  final String dnsServer;
  final int mtu;
  final bool ipv6;
  final LogLevel logLevel;
  final bool autoUpdateSubscriptions;

  /// Send this install's random device id with subscription requests, for
  /// providers that limit devices per subscription (Remnawave HWID).
  final bool sendHwid;

  AppSettings copyWith({
    ThemePreference? theme,
    DesignStyle? designStyle,
    LanguagePreference? language,
    bool? onboardingDone,
    bool? autoConnect,
    bool? launchAtStartup,
    bool? killSwitch,
    WindowsTunnelMode? windowsMode,
    DnsProtocol? dnsProtocol,
    String? dnsServer,
    int? mtu,
    bool? ipv6,
    LogLevel? logLevel,
    bool? autoUpdateSubscriptions,
    bool? sendHwid,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      designStyle: designStyle ?? this.designStyle,
      language: language ?? this.language,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      autoConnect: autoConnect ?? this.autoConnect,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      killSwitch: killSwitch ?? this.killSwitch,
      windowsMode: windowsMode ?? this.windowsMode,
      dnsProtocol: dnsProtocol ?? this.dnsProtocol,
      dnsServer: dnsServer ?? this.dnsServer,
      mtu: mtu ?? this.mtu,
      ipv6: ipv6 ?? this.ipv6,
      logLevel: logLevel ?? this.logLevel,
      autoUpdateSubscriptions: autoUpdateSubscriptions ?? this.autoUpdateSubscriptions,
      sendHwid: sendHwid ?? this.sendHwid,
    );
  }

  List<Object?> get _props => [
    theme,
    designStyle,
    language,
    onboardingDone,
    autoConnect,
    launchAtStartup,
    killSwitch,
    windowsMode,
    dnsProtocol,
    dnsServer,
    mtu,
    ipv6,
    logLevel,
    autoUpdateSubscriptions,
    sendHwid,
  ];

  @override
  bool operator ==(Object other) {
    if (other is! AppSettings) return false;
    final a = _props, b = other._props;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_props);
}

abstract interface class SettingsRepository {
  AppSettings load();
  Future<void> save(AppSettings settings);
}
