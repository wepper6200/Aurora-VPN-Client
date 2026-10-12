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
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get paste => 'Paste';

  @override
  String get unknownError => 'Something went wrong';

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get statusConnecting => 'Connecting';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusDisconnecting => 'Disconnecting';

  @override
  String get statusError => 'Error';

  @override
  String get homeTitle => 'Aurora';

  @override
  String get homeSubtitle => 'Private, fast, yours.';

  @override
  String get homeTapToConnect => 'Tap to connect';

  @override
  String get homeConnectingHint => 'Establishing a secure tunnel…';

  @override
  String get homeErrorNoServer => 'Choose a server first';

  @override
  String get homeErrorPermission => 'VPN permission was not granted';

  @override
  String get homeConnectA11y => 'Connect';

  @override
  String get homeDisconnectA11y => 'Disconnect';

  @override
  String get homeNoServerTitle => 'No server selected';

  @override
  String get homeNoServerBody => 'Add a subscription or a config to start connecting.';

  @override
  String get homeChooseServer => 'Choose server';

  @override
  String get homeDownload => 'Download';

  @override
  String get homeUpload => 'Upload';

  @override
  String get homeSessionTraffic => 'Session traffic';

  @override
  String get homeSubscription => 'Subscription';

  @override
  String subLeft(String amount) {
    return '$amount left';
  }

  @override
  String subUsedOf(String used, String total) {
    return '$used of $total';
  }

  @override
  String get subUnlimited => 'Unlimited';

  @override
  String subExpiresInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
      zero: 'Expires today',
    );
    return '$_temp0';
  }

  @override
  String get subExpired => 'Expired';

  @override
  String get subNoExpiry => 'No expiry';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String hoursShort(int n) {
    return '$n h';
  }

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
  String get serversAdd => 'Add';

  @override
  String get serversSearchHint => 'Search by name, address or protocol';

  @override
  String get serversFilterAll => 'All';

  @override
  String get serversFilterFavorites => 'Favorites';

  @override
  String get serversSort => 'Sort';

  @override
  String get serversSortNone => 'Default';

  @override
  String get serversSortLatency => 'By latency';

  @override
  String get serversSortName => 'By name';

  @override
  String get serversTestLatency => 'Test latency';

  @override
  String get serversManualGroup => 'My configs';

  @override
  String serversUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String serversCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n servers',
      one: '1 server',
      zero: 'no servers',
    );
    return '$_temp0';
  }

  @override
  String get serversNothingFound => 'Nothing found';

  @override
  String get serversNothingFoundBody => 'Try a different search or filter.';

  @override
  String get serversEmptyGroup => 'This subscription has no servers yet.';

  @override
  String get latencyTimeout => 'timeout';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionUpdate => 'Update';

  @override
  String get actionCopyLink => 'Copy link';

  @override
  String get actionFavorite => 'Add to favorites';

  @override
  String get actionUnfavorite => 'Remove from favorites';

  @override
  String get copied => 'Copied to clipboard';

  @override
  String deleteConfirmTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteConfirmBody => 'This can\'t be undone.';

  @override
  String get deleteSubscriptionBody => 'All servers from this subscription will be removed too.';

  @override
  String get addSheetTitle => 'Add';

  @override
  String get addFromUrl => 'Subscription link';

  @override
  String get addFromUrlSub => 'Subscription or profile URL';

  @override
  String get addFromClipboard => 'From clipboard';

  @override
  String get addFromClipboardSub => 'vless://, vmess://, trojan://, ss://, happ:// and more';

  @override
  String get addScanQr => 'Scan QR code';

  @override
  String get addScanQrSub => 'Use the device camera';

  @override
  String get addManual => 'Manually';

  @override
  String get addManualSub => 'Enter server parameters';

  @override
  String get clipboardNoLinks => 'No supported links found';

  @override
  String importResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count items',
      one: 'Imported 1 item',
    );
    return '$_temp0';
  }

  @override
  String importPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items couldn\'t be imported',
      one: '1 item couldn\'t be imported',
    );
    return '$_temp0';
  }

  @override
  String subFetchError(String reason) {
    return 'Couldn\'t load the subscription: $reason';
  }

  @override
  String get subErrClientNotSupported =>
      'The provider doesn\'t allow this app to use the subscription. Ask their support which apps are supported.';

  @override
  String subErrProviderSays(String text) {
    return 'Provider\'s message: “$text”';
  }

  @override
  String get subErrHtml => 'The link opened a web page instead of a subscription. Check the link.';

  @override
  String get subErrFormat => 'The subscription format wasn\'t recognized.';

  @override
  String get subErrNetwork => 'Can\'t reach the subscription server.';

  @override
  String subErrHttp(String code) {
    return 'The subscription server returned an error ($code).';
  }

  @override
  String get subErrTooLarge => 'The subscription is too large.';

  @override
  String get subUpdated => 'Subscription updated';

  @override
  String get scanHint => 'Point the camera at a QR code';

  @override
  String get cameraDenied => 'Camera access is denied';

  @override
  String get clipboardEmpty => 'The clipboard is empty';

  @override
  String get subAddTitle => 'New subscription';

  @override
  String get subEditTitle => 'Subscription';

  @override
  String get subUrlLabel => 'Subscription link';

  @override
  String get subNameLabel => 'Name (optional)';

  @override
  String get subAutoUpdate => 'Auto-update';

  @override
  String get subAutoUpdateSub => 'Refresh servers in the background';

  @override
  String get subUpdateInterval => 'Update interval';

  @override
  String get subInvalidUrl => 'Enter a valid http(s) link';

  @override
  String get editorNewTitle => 'New server';

  @override
  String get editorEditTitle => 'Edit server';

  @override
  String get editorGeneral => 'General';

  @override
  String get editorName => 'Name';

  @override
  String get editorProtocol => 'Protocol';

  @override
  String get editorAddress => 'Address';

  @override
  String get editorPort => 'Port';

  @override
  String get editorCredentials => 'Authentication';

  @override
  String get editorUuid => 'UUID';

  @override
  String get editorPassword => 'Password';

  @override
  String get editorMethod => 'Cipher';

  @override
  String get editorFlow => 'Flow';

  @override
  String get editorTransport => 'Transport';

  @override
  String get editorPath => 'Path';

  @override
  String get editorHost => 'Host header';

  @override
  String get editorServiceName => 'gRPC service name';

  @override
  String get editorSecurity => 'Security';

  @override
  String get editorSni => 'SNI';

  @override
  String get editorFingerprint => 'uTLS fingerprint';

  @override
  String get editorPublicKey => 'Reality public key';

  @override
  String get editorShortId => 'Reality short ID';

  @override
  String get editorAllowInsecure => 'Allow insecure TLS';

  @override
  String get editorSecurityNone => 'None';

  @override
  String get editorObfsPassword => 'Obfuscation password (salamander)';

  @override
  String get editorPrivateKey => 'Private key';

  @override
  String get editorPeerPublicKey => 'Peer public key';

  @override
  String get editorLocalAddress => 'Local address';

  @override
  String get editorRequired => 'Required';

  @override
  String get editorInvalidPort => 'Port must be 1–65535';

  @override
  String get routingTitle => 'Routing';

  @override
  String get routingSubtitle => 'Choose what goes through the tunnel.';

  @override
  String get routingMode => 'Mode';

  @override
  String get routingGlobal => 'Global';

  @override
  String get routingGlobalSub => 'All traffic goes through the VPN';

  @override
  String get routingRules => 'Rules';

  @override
  String get routingRulesSub => 'Traffic is split by the presets below';

  @override
  String get routingDirect => 'Direct';

  @override
  String get routingDirectSub => 'The core runs, traffic bypasses the proxy';

  @override
  String get routingPresets => 'Presets';

  @override
  String get presetBypassLan => 'Bypass local network';

  @override
  String get presetBypassLanSub => 'Private ranges like 192.168.x.x and 10.x.x.x';

  @override
  String get presetRuDirect => 'Russian sites directly';

  @override
  String get presetRuDirectSub => 'geoip:ru and geosite:category-ru';

  @override
  String get presetBlockAds => 'Block ads';

  @override
  String get presetBlockAdsSub => 'geosite:category-ads-all';

  @override
  String get presetsInactive => 'Presets apply in Rules mode only.';

  @override
  String get routingSplit => 'Split tunneling';

  @override
  String get splitApps => 'Per-app routing';

  @override
  String get splitOffSub => 'All apps use the VPN';

  @override
  String splitIncludeSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Only $n apps use the VPN',
      one: 'Only 1 app uses the VPN',
      zero: 'No apps selected',
    );
    return '$_temp0';
  }

  @override
  String splitExcludeSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n apps bypass the VPN',
      one: '1 app bypasses the VPN',
      zero: 'No apps excluded',
    );
    return '$_temp0';
  }

  @override
  String get splitAndroidOnly => 'Available on Android';

  @override
  String get splitModeOff => 'Off';

  @override
  String get splitModeInclude => 'Only selected';

  @override
  String get splitModeExclude => 'All except selected';

  @override
  String get splitSearchHint => 'Search apps';

  @override
  String get splitShowSystem => 'Show system apps';

  @override
  String get splitNoApps => 'No apps match';

  @override
  String get logsTitle => 'Logs';

  @override
  String get logsEmptyTitle => 'Nothing here yet';

  @override
  String get logsEmptyBody => 'Core logs will stream here once you connect.';

  @override
  String get logsAll => 'All';

  @override
  String get logsPause => 'Pause';

  @override
  String get logsResume => 'Resume';

  @override
  String get logsCopy => 'Copy';

  @override
  String get logsExport => 'Export';

  @override
  String get logsClear => 'Clear';

  @override
  String get logsPaused => 'Stream paused';

  @override
  String logsExported(String path) {
    return 'Saved to $path';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsConnection => 'Connection';

  @override
  String get settingsAutoConnect => 'Auto-connect';

  @override
  String get settingsAutoConnectSub => 'Connect when the app starts';

  @override
  String get settingsLaunchAtStartup => 'Launch at startup';

  @override
  String get settingsLaunchAtStartupSub => 'Start minimized to the tray';

  @override
  String get settingsKillSwitch => 'Kill switch';

  @override
  String get settingsKillSwitchAndroidSub => 'Block traffic without VPN — set in system settings';

  @override
  String get settingsKillSwitchWindowsSub => 'Block traffic if the tunnel drops (TUN mode)';

  @override
  String get settingsWindowsMode => 'Tunnel mode';

  @override
  String get modeProxy => 'System proxy';

  @override
  String get modeTun => 'TUN';

  @override
  String get modeTunHint => 'TUN captures all traffic and requires administrator rights.';

  @override
  String get settingsNetwork => 'Network';

  @override
  String get settingsDns => 'DNS';

  @override
  String get settingsMtu => 'MTU';

  @override
  String get settingsMtuHint => 'From 1280 to 9000';

  @override
  String get settingsIpv6 => 'IPv6';

  @override
  String get settingsIpv6Sub => 'Route IPv6 traffic';

  @override
  String get settingsSubscriptions => 'Subscriptions';

  @override
  String get settingsAutoUpdate => 'Auto-update subscriptions';

  @override
  String get settingsAutoUpdateSub => 'Uses the interval provided by each subscription';

  @override
  String get settingsLogging => 'Log level';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get privacyNote =>
      'No telemetry or analytics. Subscriptions and configs never leave this device.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicenses => 'Licenses';

  @override
  String get settingsLicensesSub => 'Open-source components, including sing-box (GPLv3)';

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
  String get onbSkip => 'Skip';

  @override
  String get onbNext => 'Next';

  @override
  String get onbStart => 'Get started';

  @override
  String get onb1Title => 'Your VPN, your rules';

  @override
  String get onb1Body =>
      'Aurora is a client for your subscriptions and configs. We don\'t sell servers and we don\'t collect data.';

  @override
  String get onb2Title => 'Add a subscription';

  @override
  String get onb2Body =>
      'Paste a link, scan a QR code or open a vless://, vmess:// or happ:// link — everything is imported automatically.';

  @override
  String get onb3Title => 'Fine-tune when you need';

  @override
  String get onb3Body =>
      'Rule-based routing, per-app split tunneling and a kill switch are there when you want them.';

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
}
