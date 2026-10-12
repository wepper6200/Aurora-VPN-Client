import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('ru')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Aurora VPN'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navServers.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get navServers;

  /// No description provided for @navRouting.
  ///
  /// In en, this message translates to:
  /// **'Routing'**
  String get navRouting;

  /// No description provided for @navLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get navLogs;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @windowMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get windowMinimize;

  /// No description provided for @windowMaximize.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get windowMaximize;

  /// No description provided for @windowRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get windowRestore;

  /// No description provided for @windowClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get windowClose;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get unknownError;

  /// No description provided for @statusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get statusDisconnected;

  /// No description provided for @statusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get statusConnecting;

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// No description provided for @statusDisconnecting.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting'**
  String get statusDisconnecting;

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusError;

  /// No description provided for @trayConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get trayConnect;

  /// No description provided for @trayDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get trayDisconnect;

  /// No description provided for @trayShow.
  ///
  /// In en, this message translates to:
  /// **'Show window'**
  String get trayShow;

  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// No description provided for @errAdminRequired.
  ///
  /// In en, this message translates to:
  /// **'TUN mode needs administrator rights.'**
  String get errAdminRequired;

  /// No description provided for @restartAsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Restart as administrator'**
  String get restartAsAdmin;

  /// No description provided for @errCoreMissing.
  ///
  /// In en, this message translates to:
  /// **'Core files are missing. Please reinstall the app.'**
  String get errCoreMissing;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Private, fast, yours.'**
  String get homeSubtitle;

  /// No description provided for @homeTapToConnect.
  ///
  /// In en, this message translates to:
  /// **'Tap to connect'**
  String get homeTapToConnect;

  /// No description provided for @homeConnectingHint.
  ///
  /// In en, this message translates to:
  /// **'Establishing a secure tunnel…'**
  String get homeConnectingHint;

  /// No description provided for @homeErrorNoServer.
  ///
  /// In en, this message translates to:
  /// **'Choose a server first'**
  String get homeErrorNoServer;

  /// No description provided for @homeErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'VPN permission was not granted'**
  String get homeErrorPermission;

  /// No description provided for @homeConnectA11y.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get homeConnectA11y;

  /// No description provided for @homeDisconnectA11y.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get homeDisconnectA11y;

  /// No description provided for @homeIssueNotFound.
  ///
  /// In en, this message translates to:
  /// **'The server\'s address doesn\'t exist. Pick another server or update the subscription.'**
  String get homeIssueNotFound;

  /// No description provided for @homeIssueUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The server isn\'t responding. Try another server.'**
  String get homeIssueUnreachable;

  /// No description provided for @homeNoServerTitle.
  ///
  /// In en, this message translates to:
  /// **'No server selected'**
  String get homeNoServerTitle;

  /// No description provided for @homeNoServerBody.
  ///
  /// In en, this message translates to:
  /// **'Add a subscription or a config to start connecting.'**
  String get homeNoServerBody;

  /// No description provided for @homeChooseServer.
  ///
  /// In en, this message translates to:
  /// **'Choose server'**
  String get homeChooseServer;

  /// No description provided for @homeDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get homeDownload;

  /// No description provided for @homeUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get homeUpload;

  /// No description provided for @homeSessionTraffic.
  ///
  /// In en, this message translates to:
  /// **'Session traffic'**
  String get homeSessionTraffic;

  /// No description provided for @homeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get homeSubscription;

  /// No description provided for @subLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String subLeft(String amount);

  /// No description provided for @subUsedOf.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total}'**
  String subUsedOf(String used, String total);

  /// No description provided for @subUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get subUnlimited;

  /// No description provided for @subExpiresInDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Expires today} =1{1 day left} other{{days} days left}}'**
  String subExpiresInDays(int days);

  /// No description provided for @subExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get subExpired;

  /// No description provided for @subNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'No expiry'**
  String get subNoExpiry;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 minute ago} other{{n} minutes ago}}'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 hour ago} other{{n} hours ago}}'**
  String timeHoursAgo(int n);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day ago} other{{n} days ago}}'**
  String timeDaysAgo(int n);

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'{n} h'**
  String hoursShort(int n);

  /// No description provided for @serversTitle.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get serversTitle;

  /// No description provided for @serversEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No servers yet'**
  String get serversEmptyTitle;

  /// No description provided for @serversEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a subscription link, paste a config from the clipboard or scan a QR code.'**
  String get serversEmptyBody;

  /// No description provided for @serversAddSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get serversAddSubscription;

  /// No description provided for @serversAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get serversAdd;

  /// No description provided for @serversSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, address or protocol'**
  String get serversSearchHint;

  /// No description provided for @serversFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get serversFilterAll;

  /// No description provided for @serversFilterFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get serversFilterFavorites;

  /// No description provided for @serversSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get serversSort;

  /// No description provided for @serversSortNone.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get serversSortNone;

  /// No description provided for @serversSortLatency.
  ///
  /// In en, this message translates to:
  /// **'By latency'**
  String get serversSortLatency;

  /// No description provided for @serversSortName.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get serversSortName;

  /// No description provided for @serversTestLatency.
  ///
  /// In en, this message translates to:
  /// **'Test latency'**
  String get serversTestLatency;

  /// No description provided for @serversManualGroup.
  ///
  /// In en, this message translates to:
  /// **'My configs'**
  String get serversManualGroup;

  /// No description provided for @serversUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String serversUpdated(String time);

  /// No description provided for @serversCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{no servers} =1{1 server} other{{n} servers}}'**
  String serversCount(int n);

  /// No description provided for @serversNothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get serversNothingFound;

  /// No description provided for @serversNothingFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or filter.'**
  String get serversNothingFoundBody;

  /// No description provided for @serversEmptyGroup.
  ///
  /// In en, this message translates to:
  /// **'This subscription has no servers yet.'**
  String get serversEmptyGroup;

  /// No description provided for @latencyTimeout.
  ///
  /// In en, this message translates to:
  /// **'timeout'**
  String get latencyTimeout;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get actionUpdate;

  /// No description provided for @actionCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get actionCopyLink;

  /// No description provided for @actionFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get actionFavorite;

  /// No description provided for @actionUnfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get actionUnfavorite;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteConfirmTitle(String name);

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get deleteConfirmBody;

  /// No description provided for @deleteSubscriptionBody.
  ///
  /// In en, this message translates to:
  /// **'All servers from this subscription will be removed too.'**
  String get deleteSubscriptionBody;

  /// No description provided for @addSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addSheetTitle;

  /// No description provided for @addFromUrl.
  ///
  /// In en, this message translates to:
  /// **'Subscription link'**
  String get addFromUrl;

  /// No description provided for @addFromUrlSub.
  ///
  /// In en, this message translates to:
  /// **'Subscription or profile URL'**
  String get addFromUrlSub;

  /// No description provided for @addFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'From clipboard'**
  String get addFromClipboard;

  /// No description provided for @addFromClipboardSub.
  ///
  /// In en, this message translates to:
  /// **'vless://, vmess://, trojan://, ss://, happ:// and more'**
  String get addFromClipboardSub;

  /// No description provided for @addScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get addScanQr;

  /// No description provided for @addScanQrSub.
  ///
  /// In en, this message translates to:
  /// **'Use the device camera'**
  String get addScanQrSub;

  /// No description provided for @addManual.
  ///
  /// In en, this message translates to:
  /// **'Manually'**
  String get addManual;

  /// No description provided for @addManualSub.
  ///
  /// In en, this message translates to:
  /// **'Enter server parameters'**
  String get addManualSub;

  /// No description provided for @clipboardNoLinks.
  ///
  /// In en, this message translates to:
  /// **'No supported links found'**
  String get clipboardNoLinks;

  /// No description provided for @importResult.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 item} other{Imported {count} items}}'**
  String importResult(int count);

  /// No description provided for @importPartial.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item couldn\'t be imported} other{{count} items couldn\'t be imported}}'**
  String importPartial(int count);

  /// No description provided for @subFetchError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the subscription: {reason}'**
  String subFetchError(String reason);

  /// No description provided for @subErrClientNotSupported.
  ///
  /// In en, this message translates to:
  /// **'The provider doesn\'t allow this app to use the subscription. Ask their support which apps are supported.'**
  String get subErrClientNotSupported;

  /// No description provided for @subErrProviderSays.
  ///
  /// In en, this message translates to:
  /// **'Provider\'s message: “{text}”'**
  String subErrProviderSays(String text);

  /// No description provided for @subErrHtml.
  ///
  /// In en, this message translates to:
  /// **'The link opened a web page instead of a subscription. Check the link.'**
  String get subErrHtml;

  /// No description provided for @subErrFormat.
  ///
  /// In en, this message translates to:
  /// **'The subscription format wasn\'t recognized.'**
  String get subErrFormat;

  /// No description provided for @subErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the subscription server.'**
  String get subErrNetwork;

  /// No description provided for @subErrHttp.
  ///
  /// In en, this message translates to:
  /// **'The subscription server returned an error ({code}).'**
  String subErrHttp(String code);

  /// No description provided for @subErrTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The subscription is too large.'**
  String get subErrTooLarge;

  /// No description provided for @subUpdated.
  ///
  /// In en, this message translates to:
  /// **'Subscription updated'**
  String get subUpdated;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a QR code'**
  String get scanHint;

  /// No description provided for @cameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is denied'**
  String get cameraDenied;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'The clipboard is empty'**
  String get clipboardEmpty;

  /// No description provided for @subAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New subscription'**
  String get subAddTitle;

  /// No description provided for @subEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subEditTitle;

  /// No description provided for @subUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscription link'**
  String get subUrlLabel;

  /// No description provided for @subNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get subNameLabel;

  /// No description provided for @subAutoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Auto-update'**
  String get subAutoUpdate;

  /// No description provided for @subAutoUpdateSub.
  ///
  /// In en, this message translates to:
  /// **'Refresh servers in the background'**
  String get subAutoUpdateSub;

  /// No description provided for @subUpdateInterval.
  ///
  /// In en, this message translates to:
  /// **'Update interval'**
  String get subUpdateInterval;

  /// No description provided for @subInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid http(s) link'**
  String get subInvalidUrl;

  /// No description provided for @editorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New server'**
  String get editorNewTitle;

  /// No description provided for @editorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit server'**
  String get editorEditTitle;

  /// No description provided for @editorGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get editorGeneral;

  /// No description provided for @editorName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editorName;

  /// No description provided for @editorProtocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get editorProtocol;

  /// No description provided for @editorAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get editorAddress;

  /// No description provided for @editorPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get editorPort;

  /// No description provided for @editorCredentials.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get editorCredentials;

  /// No description provided for @editorUuid.
  ///
  /// In en, this message translates to:
  /// **'UUID'**
  String get editorUuid;

  /// No description provided for @editorPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get editorPassword;

  /// No description provided for @editorMethod.
  ///
  /// In en, this message translates to:
  /// **'Cipher'**
  String get editorMethod;

  /// No description provided for @editorFlow.
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get editorFlow;

  /// No description provided for @editorTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get editorTransport;

  /// No description provided for @editorPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get editorPath;

  /// No description provided for @editorHost.
  ///
  /// In en, this message translates to:
  /// **'Host header'**
  String get editorHost;

  /// No description provided for @editorServiceName.
  ///
  /// In en, this message translates to:
  /// **'gRPC service name'**
  String get editorServiceName;

  /// No description provided for @editorSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get editorSecurity;

  /// No description provided for @editorSni.
  ///
  /// In en, this message translates to:
  /// **'SNI'**
  String get editorSni;

  /// No description provided for @editorFingerprint.
  ///
  /// In en, this message translates to:
  /// **'uTLS fingerprint'**
  String get editorFingerprint;

  /// No description provided for @editorPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Reality public key'**
  String get editorPublicKey;

  /// No description provided for @editorShortId.
  ///
  /// In en, this message translates to:
  /// **'Reality short ID'**
  String get editorShortId;

  /// No description provided for @editorAllowInsecure.
  ///
  /// In en, this message translates to:
  /// **'Allow insecure TLS'**
  String get editorAllowInsecure;

  /// No description provided for @editorSecurityNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get editorSecurityNone;

  /// No description provided for @editorObfsPassword.
  ///
  /// In en, this message translates to:
  /// **'Obfuscation password (salamander)'**
  String get editorObfsPassword;

  /// No description provided for @editorPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Private key'**
  String get editorPrivateKey;

  /// No description provided for @editorPeerPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Peer public key'**
  String get editorPeerPublicKey;

  /// No description provided for @editorLocalAddress.
  ///
  /// In en, this message translates to:
  /// **'Local address'**
  String get editorLocalAddress;

  /// No description provided for @editorRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get editorRequired;

  /// No description provided for @editorInvalidPort.
  ///
  /// In en, this message translates to:
  /// **'Port must be 1–65535'**
  String get editorInvalidPort;

  /// No description provided for @routingTitle.
  ///
  /// In en, this message translates to:
  /// **'Routing'**
  String get routingTitle;

  /// No description provided for @routingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what goes through the tunnel.'**
  String get routingSubtitle;

  /// No description provided for @routingMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get routingMode;

  /// No description provided for @routingGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get routingGlobal;

  /// No description provided for @routingGlobalSub.
  ///
  /// In en, this message translates to:
  /// **'All traffic goes through the VPN'**
  String get routingGlobalSub;

  /// No description provided for @routingRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get routingRules;

  /// No description provided for @routingRulesSub.
  ///
  /// In en, this message translates to:
  /// **'Traffic is split by the presets below'**
  String get routingRulesSub;

  /// No description provided for @routingDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get routingDirect;

  /// No description provided for @routingDirectSub.
  ///
  /// In en, this message translates to:
  /// **'The core runs, traffic bypasses the proxy'**
  String get routingDirectSub;

  /// No description provided for @routingPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get routingPresets;

  /// No description provided for @presetBypassLan.
  ///
  /// In en, this message translates to:
  /// **'Bypass local network'**
  String get presetBypassLan;

  /// No description provided for @presetBypassLanSub.
  ///
  /// In en, this message translates to:
  /// **'Private ranges like 192.168.x.x and 10.x.x.x'**
  String get presetBypassLanSub;

  /// No description provided for @presetRuDirect.
  ///
  /// In en, this message translates to:
  /// **'Russian sites directly'**
  String get presetRuDirect;

  /// No description provided for @presetRuDirectSub.
  ///
  /// In en, this message translates to:
  /// **'geoip:ru and geosite:category-ru'**
  String get presetRuDirectSub;

  /// No description provided for @presetBlockAds.
  ///
  /// In en, this message translates to:
  /// **'Block ads'**
  String get presetBlockAds;

  /// No description provided for @presetBlockAdsSub.
  ///
  /// In en, this message translates to:
  /// **'geosite:category-ads-all'**
  String get presetBlockAdsSub;

  /// No description provided for @presetsInactive.
  ///
  /// In en, this message translates to:
  /// **'Presets apply in Rules mode only.'**
  String get presetsInactive;

  /// No description provided for @routingSplit.
  ///
  /// In en, this message translates to:
  /// **'Split tunneling'**
  String get routingSplit;

  /// No description provided for @splitApps.
  ///
  /// In en, this message translates to:
  /// **'Per-app routing'**
  String get splitApps;

  /// No description provided for @splitOffSub.
  ///
  /// In en, this message translates to:
  /// **'All apps use the VPN'**
  String get splitOffSub;

  /// No description provided for @splitIncludeSub.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No apps selected} =1{Only 1 app uses the VPN} other{Only {n} apps use the VPN}}'**
  String splitIncludeSub(int n);

  /// No description provided for @splitExcludeSub.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No apps excluded} =1{1 app bypasses the VPN} other{{n} apps bypass the VPN}}'**
  String splitExcludeSub(int n);

  /// No description provided for @splitAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Available on Android'**
  String get splitAndroidOnly;

  /// No description provided for @splitModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get splitModeOff;

  /// No description provided for @splitModeInclude.
  ///
  /// In en, this message translates to:
  /// **'Only selected'**
  String get splitModeInclude;

  /// No description provided for @splitModeExclude.
  ///
  /// In en, this message translates to:
  /// **'All except selected'**
  String get splitModeExclude;

  /// No description provided for @splitSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get splitSearchHint;

  /// No description provided for @splitShowSystem.
  ///
  /// In en, this message translates to:
  /// **'Show system apps'**
  String get splitShowSystem;

  /// No description provided for @splitNoApps.
  ///
  /// In en, this message translates to:
  /// **'No apps match'**
  String get splitNoApps;

  /// No description provided for @crashTitle.
  ///
  /// In en, this message translates to:
  /// **'The previous session ended with a crash:'**
  String get crashTitle;

  /// No description provided for @crashPrevious.
  ///
  /// In en, this message translates to:
  /// **'The app crashed last time. Details are in the Logs tab — please copy them for the developer.'**
  String get crashPrevious;

  /// No description provided for @logsTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logsTitle;

  /// No description provided for @logsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get logsEmptyTitle;

  /// No description provided for @logsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Core logs will stream here once you connect.'**
  String get logsEmptyBody;

  /// No description provided for @logsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get logsAll;

  /// No description provided for @logsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get logsPause;

  /// No description provided for @logsResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get logsResume;

  /// No description provided for @logsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get logsCopy;

  /// No description provided for @logsExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get logsExport;

  /// No description provided for @logsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export the logs'**
  String get logsExportFailed;

  /// No description provided for @logsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get logsClear;

  /// No description provided for @logsPaused.
  ///
  /// In en, this message translates to:
  /// **'Stream paused'**
  String get logsPaused;

  /// No description provided for @logsExported.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String logsExported(String path);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsConnection;

  /// No description provided for @settingsAutoConnect.
  ///
  /// In en, this message translates to:
  /// **'Auto-connect'**
  String get settingsAutoConnect;

  /// No description provided for @settingsAutoConnectSub.
  ///
  /// In en, this message translates to:
  /// **'Connect when the app starts'**
  String get settingsAutoConnectSub;

  /// No description provided for @settingsLaunchAtStartup.
  ///
  /// In en, this message translates to:
  /// **'Launch at startup'**
  String get settingsLaunchAtStartup;

  /// No description provided for @settingsLaunchAtStartupSub.
  ///
  /// In en, this message translates to:
  /// **'Start minimized to the tray'**
  String get settingsLaunchAtStartupSub;

  /// No description provided for @settingsKillSwitch.
  ///
  /// In en, this message translates to:
  /// **'Kill switch'**
  String get settingsKillSwitch;

  /// No description provided for @settingsKillSwitchAndroidSub.
  ///
  /// In en, this message translates to:
  /// **'Block traffic without VPN — set in system settings'**
  String get settingsKillSwitchAndroidSub;

  /// No description provided for @settingsKillSwitchWindowsSub.
  ///
  /// In en, this message translates to:
  /// **'Block traffic if the tunnel drops (TUN mode)'**
  String get settingsKillSwitchWindowsSub;

  /// No description provided for @settingsWindowsMode.
  ///
  /// In en, this message translates to:
  /// **'Tunnel mode'**
  String get settingsWindowsMode;

  /// No description provided for @modeProxy.
  ///
  /// In en, this message translates to:
  /// **'System proxy'**
  String get modeProxy;

  /// No description provided for @modeTun.
  ///
  /// In en, this message translates to:
  /// **'TUN'**
  String get modeTun;

  /// No description provided for @modeTunHint.
  ///
  /// In en, this message translates to:
  /// **'TUN captures all traffic and requires administrator rights.'**
  String get modeTunHint;

  /// No description provided for @settingsNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get settingsNetwork;

  /// No description provided for @settingsDns.
  ///
  /// In en, this message translates to:
  /// **'DNS'**
  String get settingsDns;

  /// No description provided for @settingsMtu.
  ///
  /// In en, this message translates to:
  /// **'MTU'**
  String get settingsMtu;

  /// No description provided for @settingsMtuHint.
  ///
  /// In en, this message translates to:
  /// **'From 1280 to 9000'**
  String get settingsMtuHint;

  /// No description provided for @settingsIpv6.
  ///
  /// In en, this message translates to:
  /// **'IPv6'**
  String get settingsIpv6;

  /// No description provided for @settingsIpv6Sub.
  ///
  /// In en, this message translates to:
  /// **'Route IPv6 traffic'**
  String get settingsIpv6Sub;

  /// No description provided for @settingsSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get settingsSubscriptions;

  /// No description provided for @settingsAutoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Auto-update subscriptions'**
  String get settingsAutoUpdate;

  /// No description provided for @settingsAutoUpdateSub.
  ///
  /// In en, this message translates to:
  /// **'Uses the interval provided by each subscription'**
  String get settingsAutoUpdateSub;

  /// No description provided for @settingsHwid.
  ///
  /// In en, this message translates to:
  /// **'Send device ID (HWID)'**
  String get settingsHwid;

  /// No description provided for @settingsHwidSub.
  ///
  /// In en, this message translates to:
  /// **'Needed by providers that limit devices per subscription. A random ID of this app install, not a hardware serial.'**
  String get settingsHwidSub;

  /// No description provided for @settingsLogging.
  ///
  /// In en, this message translates to:
  /// **'Log level'**
  String get settingsLogging;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'No telemetry or analytics. Subscriptions and configs never leave this device.'**
  String get privacyNote;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsLicensesSub.
  ///
  /// In en, this message translates to:
  /// **'Open-source components, including sing-box (GPLv3)'**
  String get settingsLicensesSub;

  /// No description provided for @settingsDesignSystem.
  ///
  /// In en, this message translates to:
  /// **'Design system'**
  String get settingsDesignSystem;

  /// No description provided for @settingsDesignSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Components, colors and typography'**
  String get settingsDesignSystemSubtitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// No description provided for @onbNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// No description provided for @onbStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onbStart;

  /// No description provided for @onb1Title.
  ///
  /// In en, this message translates to:
  /// **'Your VPN, your rules'**
  String get onb1Title;

  /// No description provided for @onb1Body.
  ///
  /// In en, this message translates to:
  /// **'Aurora is a client for your subscriptions and configs. We don\'t sell servers and we don\'t collect data.'**
  String get onb1Body;

  /// No description provided for @onb2Title.
  ///
  /// In en, this message translates to:
  /// **'Add a subscription'**
  String get onb2Title;

  /// No description provided for @onb2Body.
  ///
  /// In en, this message translates to:
  /// **'Paste a link, scan a QR code or open a vless://, vmess:// or happ:// link — everything is imported automatically.'**
  String get onb2Body;

  /// No description provided for @onb3Title.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune when you need'**
  String get onb3Title;

  /// No description provided for @onb3Body.
  ///
  /// In en, this message translates to:
  /// **'Rule-based routing, per-app split tunneling and a kill switch are there when you want them.'**
  String get onb3Body;

  /// No description provided for @dsTitle.
  ///
  /// In en, this message translates to:
  /// **'Design system'**
  String get dsTitle;

  /// No description provided for @dsColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get dsColors;

  /// No description provided for @dsTypography.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get dsTypography;

  /// No description provided for @dsButtons.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get dsButtons;

  /// No description provided for @dsCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get dsCards;

  /// No description provided for @dsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get dsStatus;

  /// No description provided for @dsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Loading & empty states'**
  String get dsFeedback;

  /// No description provided for @dsPrimaryAction.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get dsPrimaryAction;

  /// No description provided for @dsSecondaryAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get dsSecondaryAction;

  /// No description provided for @dsAccentAction.
  ///
  /// In en, this message translates to:
  /// **'Test latency'**
  String get dsAccentAction;

  /// No description provided for @dsDangerAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dsDangerAction;

  /// No description provided for @dsCardSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid card'**
  String get dsCardSolid;

  /// No description provided for @dsCardElevated.
  ///
  /// In en, this message translates to:
  /// **'Elevated card'**
  String get dsCardElevated;

  /// No description provided for @dsCardGlass.
  ///
  /// In en, this message translates to:
  /// **'Glass card'**
  String get dsCardGlass;

  /// No description provided for @dsCardSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected card'**
  String get dsCardSelected;

  /// No description provided for @dsCardBody.
  ///
  /// In en, this message translates to:
  /// **'Rounded corners, soft shadow and a hairline border.'**
  String get dsCardBody;

  /// No description provided for @dsTypographySample.
  ///
  /// In en, this message translates to:
  /// **'The quick brown fox'**
  String get dsTypographySample;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
