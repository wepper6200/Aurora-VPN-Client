// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Aurora VPN';

  @override
  String get navHome => 'Главная';

  @override
  String get navServers => 'Серверы';

  @override
  String get navRouting => 'Маршруты';

  @override
  String get navLogs => 'Логи';

  @override
  String get navSettings => 'Настройки';

  @override
  String get windowMinimize => 'Свернуть';

  @override
  String get windowMaximize => 'Развернуть';

  @override
  String get windowRestore => 'Восстановить';

  @override
  String get windowClose => 'Закрыть';

  @override
  String get homeTitle => 'Aurora';

  @override
  String get homeSubtitle => 'Приватно, быстро, под вашим контролем.';

  @override
  String get homeNoServerTitle => 'Сервер не выбран';

  @override
  String get homeNoServerBody => 'Добавьте подписку или конфиг, чтобы подключиться.';

  @override
  String get serversTitle => 'Серверы';

  @override
  String get serversEmptyTitle => 'Серверов пока нет';

  @override
  String get serversEmptyBody =>
      'Добавьте ссылку на подписку, вставьте конфиг из буфера обмена или отсканируйте QR-код.';

  @override
  String get serversAddSubscription => 'Добавить подписку';

  @override
  String get routingTitle => 'Маршрутизация';

  @override
  String get routingSubtitle => 'Выберите, какой трафик идёт через туннель.';

  @override
  String get logsTitle => 'Логи';

  @override
  String get logsEmptyTitle => 'Пока пусто';

  @override
  String get logsEmptyBody => 'Логи ядра появятся здесь после подключения.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsDesignSystem => 'Дизайн-система';

  @override
  String get settingsDesignSystemSubtitle => 'Компоненты, цвета и типографика';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get languageSystem => 'Системный';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get dsTitle => 'Дизайн-система';

  @override
  String get dsColors => 'Цвета';

  @override
  String get dsTypography => 'Типографика';

  @override
  String get dsButtons => 'Кнопки';

  @override
  String get dsCards => 'Карточки';

  @override
  String get dsStatus => 'Статусы';

  @override
  String get dsFeedback => 'Загрузка и пустые состояния';

  @override
  String get dsPrimaryAction => 'Подключить';

  @override
  String get dsSecondaryAction => 'Импорт';

  @override
  String get dsAccentAction => 'Тест задержки';

  @override
  String get dsDangerAction => 'Удалить';

  @override
  String get dsCardSolid => 'Обычная карточка';

  @override
  String get dsCardElevated => 'Приподнятая карточка';

  @override
  String get dsCardGlass => 'Стеклянная карточка';

  @override
  String get dsCardSelected => 'Выбранная карточка';

  @override
  String get dsCardBody => 'Скруглённые углы, мягкая тень и тонкая обводка.';

  @override
  String get dsTypographySample => 'Съешь же ещё этих мягких булок';

  @override
  String get statusDisconnected => 'Отключено';

  @override
  String get statusConnecting => 'Подключение';

  @override
  String get statusConnected => 'Подключено';

  @override
  String get statusError => 'Ошибка';

  @override
  String get retry => 'Повторить';
}
