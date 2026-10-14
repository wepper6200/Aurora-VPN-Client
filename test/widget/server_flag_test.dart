import 'package:aurora_vpn/presentation/features/servers/widgets/server_widgets.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('leading flag emoji → country code and a clean display name', () {
    expect(flagCountryCode('🇪🇪 EST1'), 'EE');
    expect(flagCountryCode('🇩🇪Frankfurt'), 'DE');
    expect(flagCountryCode('Frankfurt'), isNull);
    expect(displayServerName('🇪🇪 EST1'), 'EST1');
    expect(displayServerName('Frankfurt'), 'Frankfurt');
    // A name that is only a flag keeps it.
    expect(displayServerName('🇪🇪'), '🇪🇪');
  });

  test('flag codes the avatar draws as images', () {
    expect(FlagCode.fromCountryCode('EE'), isNotNull);
  });
}
