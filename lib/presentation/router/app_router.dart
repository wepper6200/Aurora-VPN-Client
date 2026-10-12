import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/settings/settings_controller.dart';
import '../features/home/home_page.dart';
import '../features/logs/logs_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/routing/routing_page.dart';
import '../features/routing/split_apps_page.dart';
import '../features/servers/scan_qr_page.dart';
import '../features/servers/server_editor_page.dart';
import '../features/servers/servers_page.dart';
import '../features/servers/subscription_editor_page.dart';
import '../features/settings/design_system_page.dart';
import '../features/settings/settings_page.dart';
import '../shell/app_shell.dart';
import '../shell/branch_container.dart';

abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const servers = '/servers';
  static const newSubscription = '/servers/subscription/new';
  static const newServer = '/servers/server/new';
  static const scanQr = '/servers/scan';
  static const routing = '/routing';
  static const splitApps = '/routing/apps';
  static const logs = '/logs';
  static const settings = '/settings';
  static const designSystem = '/settings/design-system';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      // Read (not watch): the router must not be rebuilt on settings changes.
      final done = ref.read(settingsProvider).onboardingDone;
      final atOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (!done && !atOnboarding) return AppRoutes.onboarding;
      if (done && atOnboarding) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingPage()),
      StatefulShellRoute(
        builder: (context, state, shell) => shell,
        navigatorContainerBuilder: (context, shell, children) => AppShell(
          shell: shell,
          body: AnimatedBranchContainer(currentIndex: shell.currentIndex, children: children),
        ),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.servers,
                builder: (_, _) => const ServersPage(),
                routes: [
                  GoRoute(
                    path: 'subscription/new',
                    builder: (_, s) =>
                        SubscriptionEditorPage(initialUrl: s.uri.queryParameters['url']),
                  ),
                  GoRoute(
                    path: 'subscription/:id',
                    builder: (_, s) => SubscriptionEditorPage(id: s.pathParameters['id']),
                  ),
                  GoRoute(path: 'server/new', builder: (_, _) => const ServerEditorPage()),
                  GoRoute(
                    path: 'server/:id',
                    builder: (_, s) => ServerEditorPage(id: s.pathParameters['id']),
                  ),
                  GoRoute(path: 'scan', builder: (_, _) => const ScanQrPage()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.routing,
                builder: (_, _) => const RoutingPage(),
                routes: [GoRoute(path: 'apps', builder: (_, _) => const SplitAppsPage())],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.logs, builder: (_, _) => const LogsPage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, _) => const SettingsPage(),
                routes: [
                  GoRoute(path: 'design-system', builder: (_, _) => const DesignSystemPage()),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
