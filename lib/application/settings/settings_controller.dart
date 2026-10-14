import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/settings/prefs_settings_repository.dart';
import '../../domain/settings/app_settings.dart';

/// Must be overridden in `main()` (and in tests) with a ready instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => PrefsSettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> _update(AppSettings next) async {
    if (next == state) return;
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  /// Applies an arbitrary change, e.g. `update((s) => s.copyWith(mtu: 1500))`.
  Future<void> update(AppSettings Function(AppSettings s) change) => _update(change(state));

  Future<void> setTheme(ThemePreference theme) => _update(state.copyWith(theme: theme));

  Future<void> setDesignStyle(DesignStyle style) => _update(state.copyWith(designStyle: style));

  Future<void> setLanguage(LanguagePreference language) =>
      _update(state.copyWith(language: language));

  Future<void> completeOnboarding() => _update(state.copyWith(onboardingDone: true));
}
