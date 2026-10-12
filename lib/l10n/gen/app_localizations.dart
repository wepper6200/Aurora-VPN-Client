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

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

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

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
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
