enum ThemePreference { system, light, dark }

enum LanguagePreference {
  system(null),
  en('en'),
  ru('ru');

  const LanguagePreference(this.code);

  /// ISO language code, `null` means "follow the OS".
  final String? code;
}

/// User-facing preferences. Grows with later stages (DNS, MTU, autostart…).
class AppSettings {
  const AppSettings({
    this.theme = ThemePreference.dark,
    this.language = LanguagePreference.system,
    this.onboardingDone = false,
  });

  final ThemePreference theme;
  final LanguagePreference language;
  final bool onboardingDone;

  AppSettings copyWith({
    ThemePreference? theme,
    LanguagePreference? language,
    bool? onboardingDone,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.theme == theme &&
      other.language == language &&
      other.onboardingDone == onboardingDone;

  @override
  int get hashCode => Object.hash(theme, language, onboardingDone);
}

abstract interface class SettingsRepository {
  AppSettings load();
  Future<void> save(AppSettings settings);
}
