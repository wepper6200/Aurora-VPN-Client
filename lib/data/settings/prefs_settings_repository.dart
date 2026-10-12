import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/logs/log_entry.dart';
import '../../domain/settings/app_settings.dart';

/// Non-sensitive preferences in SharedPreferences. Secrets never go here.
class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _p = 'settings.';

  @override
  AppSettings load() {
    const d = AppSettings();
    return AppSettings(
      theme: _enum(ThemePreference.values, 'theme') ?? d.theme,
      language: _enum(LanguagePreference.values, 'language') ?? d.language,
      onboardingDone: _bool('onboardingDone') ?? d.onboardingDone,
      autoConnect: _bool('autoConnect') ?? d.autoConnect,
      launchAtStartup: _bool('launchAtStartup') ?? d.launchAtStartup,
      killSwitch: _bool('killSwitch') ?? d.killSwitch,
      windowsMode: _enum(WindowsTunnelMode.values, 'windowsMode') ?? d.windowsMode,
      dnsProtocol: _enum(DnsProtocol.values, 'dnsProtocol') ?? d.dnsProtocol,
      dnsServer: _prefs.getString('${_p}dnsServer') ?? d.dnsServer,
      mtu: _prefs.getInt('${_p}mtu') ?? d.mtu,
      ipv6: _bool('ipv6') ?? d.ipv6,
      logLevel: _enum(LogLevel.values, 'logLevel') ?? d.logLevel,
      autoUpdateSubscriptions: _bool('autoUpdateSubscriptions') ?? d.autoUpdateSubscriptions,
      sendHwid: _bool('sendHwid') ?? d.sendHwid,
    );
  }

  @override
  Future<void> save(AppSettings s) async {
    await Future.wait([
      _prefs.setString('${_p}theme', s.theme.name),
      _prefs.setString('${_p}language', s.language.name),
      _prefs.setBool('${_p}onboardingDone', s.onboardingDone),
      _prefs.setBool('${_p}autoConnect', s.autoConnect),
      _prefs.setBool('${_p}launchAtStartup', s.launchAtStartup),
      _prefs.setBool('${_p}killSwitch', s.killSwitch),
      _prefs.setString('${_p}windowsMode', s.windowsMode.name),
      _prefs.setString('${_p}dnsProtocol', s.dnsProtocol.name),
      _prefs.setString('${_p}dnsServer', s.dnsServer),
      _prefs.setInt('${_p}mtu', s.mtu),
      _prefs.setBool('${_p}ipv6', s.ipv6),
      _prefs.setString('${_p}logLevel', s.logLevel.name),
      _prefs.setBool('${_p}autoUpdateSubscriptions', s.autoUpdateSubscriptions),
      _prefs.setBool('${_p}sendHwid', s.sendHwid),
    ]);
  }

  bool? _bool(String key) => _prefs.getBool('$_p$key');

  T? _enum<T extends Enum>(List<T> values, String key) {
    final name = _prefs.getString('$_p$key');
    if (name == null) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
