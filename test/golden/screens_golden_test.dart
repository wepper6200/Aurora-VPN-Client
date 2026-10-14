@Tags(['golden'])
library;

import 'package:aurora_vpn/core/platform.dart';
import 'package:aurora_vpn/presentation/features/home/widgets/connect_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// Screen goldens (also serve as the stage screenshots).
/// Regenerate after intentional UI changes:
///   flutter test --update-goldens --tags golden
void main() {
  setUpAll(loadAppFonts);

  const phone = Size(412, 892);
  const tallPhone = Size(412, 1500);
  const window = Size(460, 800);
  const tallWindow = Size(460, 1500);

  Future<void> tab(WidgetTester tester, String label, {bool settle = true}) async {
    await tester.tap(find.text(label).last);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await pumpFor(tester, const Duration(milliseconds: 600));
    }
  }

  void golden(
    String name, {
    AppPlatform platform = AppPlatform.android,
    Size size = phone,
    String theme = 'dark',
    String style = 'material',
    Map<String, Object> prefs = const {},
    bool settle = true,
    Future<void> Function(WidgetTester tester)? setup,
  }) {
    testWidgets(name, (tester) async {
      await pumpApp(
        tester,
        platform: platform,
        size: size,
        fixedClock: true,
        prefs: {
          'settings.language': 'ru',
          'settings.theme': theme,
          'settings.designStyle': style,
          ...prefs,
        },
      );
      await setup?.call(tester);
      if (settle) await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
    });
  }

  // Onboarding
  golden('onboarding_style', prefs: {'settings.onboardingDone': false});
  golden('glass_onboarding_style', style: 'glass', prefs: {'settings.onboardingDone': false});
  golden(
    'onboarding_1',
    prefs: {'settings.onboardingDone': false},
    setup: (t) async {
      await t.tap(find.text('Далее'));
      await t.pumpAndSettle();
    },
  );
  golden(
    'onboarding_3_light',
    theme: 'light',
    prefs: {'settings.onboardingDone': false},
    setup: (t) async {
      for (var i = 0; i < 3; i++) {
        await t.tap(find.text('Далее'));
        await t.pumpAndSettle();
      }
    },
  );

  // Home
  golden('home_disconnected');
  golden('home_disconnected_light', theme: 'light');
  golden(
    'home_connecting',
    settle: false,
    setup: (t) async {
      await t.tap(find.byType(ConnectButton));
      await pumpFor(t, const Duration(milliseconds: 700));
    },
  );
  golden('glass_home_disconnected', style: 'glass');
  golden(
    'glass_home_connected',
    style: 'glass',
    settle: false,
    setup: (t) => connect(t, traffic: const Duration(seconds: 8)),
  );
  golden(
    'glass_home_connected_light',
    style: 'glass',
    theme: 'light',
    settle: false,
    setup: (t) => connect(t, traffic: const Duration(seconds: 8)),
  );
  golden(
    'glass_servers',
    style: 'glass',
    size: tallPhone,
    setup: (t) => tab(t, 'Серверы'),
  );
  golden(
    'glass_settings',
    style: 'glass',
    size: const Size(412, 2400),
    setup: (t) => tab(t, 'Настройки'),
  );
  golden(
    'glass_windows_home_connected',
    style: 'glass',
    platform: AppPlatform.windows,
    size: window,
    settle: false,
    setup: (t) => connect(t, traffic: const Duration(seconds: 8)),
  );
  golden(
    'home_connected',
    settle: false,
    setup: (t) => connect(t, traffic: const Duration(seconds: 8)),
  );
  golden(
    'home_connected_light',
    theme: 'light',
    settle: false,
    setup: (t) => connect(t, traffic: const Duration(seconds: 8)),
  );
  golden(
    'home_error',
    prefs: {'servers.selected': 's6'},
    setup: (t) => connect(t, traffic: Duration.zero),
  );
  golden(
    'windows_home_connected',
    platform: AppPlatform.windows,
    size: window,
    settle: false,
    setup: (t) => connect(t, traffic: const Duration(seconds: 8)),
  );

  // Servers
  golden('servers', size: tallPhone, setup: (t) => tab(t, 'Серверы'));
  golden('servers_light', theme: 'light', size: tallPhone, setup: (t) => tab(t, 'Серверы'));
  golden(
    'servers_latency',
    size: tallPhone,
    setup: (t) async {
      await tab(t, 'Серверы');
      await t.tap(find.byTooltip('Проверить задержку'));
      await pumpFor(t, const Duration(seconds: 3));
    },
  );
  golden(
    'servers_add_sheet',
    setup: (t) async {
      await tab(t, 'Серверы');
      await t.tap(find.byTooltip('Добавить'));
      await t.pumpAndSettle();
    },
  );
  golden(
    'subscription_editor',
    setup: (t) async {
      await tab(t, 'Серверы');
      await t.tap(find.byTooltip('Добавить'));
      await t.pumpAndSettle();
      await t.tap(find.text('Подписка по ссылке'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).first, 'https://sub.example.com/abc');
      FocusManager.instance.primaryFocus?.unfocus();
    },
  );
  golden(
    'server_editor',
    size: tallPhone,
    setup: (t) async {
      await tab(t, 'Серверы');
      await t.tap(find.byTooltip('Добавить'));
      await t.pumpAndSettle();
      await t.tap(find.text('Вручную'));
      await t.pumpAndSettle();
      await t.tap(find.text('Reality'));
      await t.pumpAndSettle();
    },
  );
  golden(
    'windows_servers',
    platform: AppPlatform.windows,
    size: tallWindow,
    setup: (t) => tab(t, 'Серверы'),
  );

  // Routing
  golden('routing', size: tallPhone, setup: (t) => tab(t, 'Маршруты'));
  golden('routing_light', theme: 'light', size: tallPhone, setup: (t) => tab(t, 'Маршруты'));
  golden(
    'split_apps',
    size: tallPhone,
    prefs: {
      'routing.splitMode': 'exclude',
      'routing.splitApps': ['org.example.bank', 'org.example.maps'],
    },
    setup: (t) async {
      await tab(t, 'Маршруты');
      await t.tap(find.text('Приложения'));
      await t.pumpAndSettle();
    },
  );

  // Logs
  golden(
    'logs',
    settle: false,
    setup: (t) async {
      await connect(t, traffic: const Duration(seconds: 12));
      await tab(t, 'Логи', settle: false);
    },
  );

  // Settings
  golden('settings', size: const Size(412, 2400), setup: (t) => tab(t, 'Настройки'));
  golden(
    'settings_light',
    theme: 'light',
    size: const Size(412, 2400),
    setup: (t) => tab(t, 'Настройки'),
  );
  golden(
    'windows_settings',
    platform: AppPlatform.windows,
    size: const Size(460, 2300),
    setup: (t) => tab(t, 'Настройки'),
  );

  golden(
    'design_system',
    size: const Size(412, 2000),
    settle: false,
    setup: (t) async {
      await tab(t, 'Настройки');
      await t.tap(find.text('Дизайн-система'));
      await pumpFor(t, const Duration(seconds: 2));
    },
  );
}
