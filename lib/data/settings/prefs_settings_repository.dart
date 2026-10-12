import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/settings/app_settings.dart';

/// Non-sensitive preferences in SharedPreferences. Secrets never go here.
class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kTheme = 'settings.theme';
  static const _kLanguage = 'settings.language';
  static const _kOnboarding = 'settings.onboardingDone';

  @override
  AppSettings load() {
    const d = AppSettings();
    return AppSettings(
      theme: _enum(ThemePreference.values, _prefs.getString(_kTheme)) ?? d.theme,
      language: _enum(LanguagePreference.values, _prefs.getString(_kLanguage)) ?? d.language,
      onboardingDone: _prefs.getBool(_kOnboarding) ?? d.onboardingDone,
    );
  }

  @override
  Future<void> save(AppSettings s) async {
    await _prefs.setString(_kTheme, s.theme.name);
    await _prefs.setString(_kLanguage, s.language.name);
    await _prefs.setBool(_kOnboarding, s.onboardingDone);
  }

  static T? _enum<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
