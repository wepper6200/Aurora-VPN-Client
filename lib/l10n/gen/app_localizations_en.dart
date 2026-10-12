// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Aurora VPN';

  @override
  String get navHome => 'Home';

  @override
  String get navServers => 'Servers';

  @override
  String get navRouting => 'Routing';

  @override
  String get navLogs => 'Logs';

  @override
  String get navSettings => 'Settings';

  @override
  String get windowMinimize => 'Minimize';

  @override
  String get windowMaximize => 'Maximize';

  @override
  String get windowRestore => 'Restore';

  @override
  String get windowClose => 'Close';

  @override
  String get homeTitle => 'Aurora';

  @override
  String get homeSubtitle => 'Private, fast, yours.';

  @override
  String get homeNoServerTitle => 'No server selected';

  @override
  String get homeNoServerBody => 'Add a subscription or a config to start connecting.';

  @override
  String get serversTitle => 'Servers';

  @override
  String get serversEmptyTitle => 'No servers yet';

  @override
  String get serversEmptyBody =>
      'Add a subscription link, paste a config from the clipboard or scan a QR code.';

  @override
  String get serversAddSubscription => 'Add subscription';

  @override
  String get routingTitle => 'Routing';

  @override
  String get routingSubtitle => 'Choose what goes through the tunnel.';

  @override
  String get logsTitle => 'Logs';

  @override
  String get logsEmptyTitle => 'Nothing here yet';

  @override
  String get logsEmptyBody => 'Core logs will stream here once you connect.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsDesignSystem => 'Design system';

  @override
  String get settingsDesignSystemSubtitle => 'Components, colors and typography';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get dsTitle => 'Design system';

  @override
  String get dsColors => 'Colors';

  @override
  String get dsTypography => 'Typography';

  @override
  String get dsButtons => 'Buttons';

  @override
  String get dsCards => 'Cards';

  @override
  String get dsStatus => 'Status';

  @override
  String get dsFeedback => 'Loading & empty states';

  @override
  String get dsPrimaryAction => 'Connect';

  @override
  String get dsSecondaryAction => 'Import';

  @override
  String get dsAccentAction => 'Test latency';

  @override
  String get dsDangerAction => 'Delete';

  @override
  String get dsCardSolid => 'Solid card';

  @override
  String get dsCardElevated => 'Elevated card';

  @override
  String get dsCardGlass => 'Glass card';

  @override
  String get dsCardSelected => 'Selected card';

  @override
  String get dsCardBody => 'Rounded corners, soft shadow and a hairline border.';

  @override
  String get dsTypographySample => 'The quick brown fox';

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get statusConnecting => 'Connecting';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusError => 'Error';

  @override
  String get retry => 'Retry';
}
