import 'package:aurora_vpn/application/vpn/vpn_controller.dart';
import 'package:aurora_vpn/domain/vpn/vpn_core.dart';
import 'package:aurora_vpn/presentation/features/home/widgets/connect_button.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  const en = {'settings.language': 'en'};

  testWidgets('home shows the selected server and subscription quota', (tester) async {
    await pumpApp(tester, prefs: en);

    // Falls back to the first favorite when nothing was selected.
    expect(find.text('Germany · Frankfurt'), findsOneWidget);
    expect(find.text('VLESS · Reality'), findsOneWidget);
    expect(find.text('Nebula Cloud'), findsOneWidget);
    expect(find.text('23 days left'), findsOneWidget);
  });

  testWidgets('connect → connected with live stats → disconnect', (tester) async {
    final container = await pumpApp(tester, prefs: en);

    await tester.tap(find.byType(ConnectButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(vpnStateProvider).status, VpnStatus.connecting);
    expect(find.text('Establishing a secure tunnel…'), findsOneWidget);

    await pumpFor(tester, const Duration(seconds: 4));
    expect(container.read(vpnStateProvider).status, VpnStatus.connected);
    expect(find.text('Connected'), findsWidgets);
    expect(find.textContaining(RegExp(r'^00:00:0\d$')), findsOneWidget);
    expect(container.read(speedHistoryProvider).down, isNotEmpty);
    expect(find.text('0 B/s'), findsNothing);

    await disconnect(tester);
    expect(container.read(vpnStateProvider).status, VpnStatus.disconnected);
    expect(find.text('Tap to connect'), findsOneWidget);
  });

  testWidgets('an unreachable server ends in the error state', (tester) async {
    final container = await pumpApp(tester, prefs: {...en, 'servers.selected': 's6'});

    await connect(tester, traffic: Duration.zero);
    await tester.pumpAndSettle();

    expect(container.read(vpnStateProvider).status, VpnStatus.error);
    expect(find.text('dial tcp: i/o timeout'), findsOneWidget);
  });
}
