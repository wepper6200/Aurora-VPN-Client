import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_page.dart';
import '../features/logs/logs_page.dart';
import '../features/routing/routing_page.dart';
import '../features/servers/servers_page.dart';
import '../features/settings/design_system_page.dart';
import '../features/settings/settings_page.dart';
import '../shell/app_shell.dart';
import '../shell/branch_container.dart';

abstract final class AppRoutes {
  static const home = '/home';
  static const servers = '/servers';
  static const routing = '/routing';
  static const logs = '/logs';
  static const settings = '/settings';
  static const designSystem = '/settings/design-system';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.home,
    routes: [
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
            routes: [GoRoute(path: AppRoutes.servers, builder: (_, _) => const ServersPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.routing, builder: (_, _) => const RoutingPage())],
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
