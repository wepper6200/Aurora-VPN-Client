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
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get done => 'Готово';

  @override
  String get retry => 'Повторить';

  @override
  String get paste => 'Вставить';

  @override
  String get unknownError => 'Что-то пошло не так';

  @override
  String get statusDisconnected => 'Отключено';

  @override
  String get statusConnecting => 'Подключение';

  @override
  String get statusConnected => 'Подключено';

  @override
  String get statusDisconnecting => 'Отключение';

  @override
  String get statusError => 'Ошибка';

  @override
  String get homeTitle => 'Aurora';

  @override
  String get homeSubtitle => 'Приватно, быстро, под вашим контролем.';

  @override
  String get homeTapToConnect => 'Нажмите, чтобы подключиться';

  @override
  String get homeConnectingHint => 'Устанавливаем защищённый туннель…';

  @override
  String get homeErrorNoServer => 'Сначала выберите сервер';

  @override
  String get homeConnectA11y => 'Подключить';

  @override
  String get homeDisconnectA11y => 'Отключить';

  @override
  String get homeNoServerTitle => 'Сервер не выбран';

  @override
  String get homeNoServerBody => 'Добавьте подписку или конфиг, чтобы подключиться.';

  @override
  String get homeChooseServer => 'Выбрать сервер';

  @override
  String get homeDownload => 'Загрузка';

  @override
  String get homeUpload => 'Отдача';

  @override
  String get homeSessionTraffic => 'Трафик сессии';

  @override
  String get homeSubscription => 'Подписка';

  @override
  String subLeft(String amount) {
    return 'Осталось $amount';
  }

  @override
  String subUsedOf(String used, String total) {
    return '$used из $total';
  }

  @override
  String get subUnlimited => 'Безлимит';

  @override
  String subExpiresInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Осталось $days дней',
      few: 'Осталось $days дня',
      one: 'Остался $days день',
      zero: 'Истекает сегодня',
    );
    return '$_temp0';
  }

  @override
  String get subExpired => 'Истекла';

  @override
  String get subNoExpiry => 'Бессрочно';

  @override
  String get timeJustNow => 'только что';

  @override
  String timeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n минут назад',
      few: '$n минуты назад',
      one: '$n минуту назад',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n часов назад',
      few: '$n часа назад',
      one: '$n час назад',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n дней назад',
      few: '$n дня назад',
      one: '$n день назад',
    );
    return '$_temp0';
  }

  @override
  String hoursShort(int n) {
    return '$n ч';
  }

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
  String get serversAdd => 'Добавить';

  @override
  String get serversSearchHint => 'Поиск по имени, адресу или протоколу';

  @override
  String get serversFilterAll => 'Все';

  @override
  String get serversFilterFavorites => 'Избранное';

  @override
  String get serversSort => 'Сортировка';

  @override
  String get serversSortNone => 'По умолчанию';

  @override
  String get serversSortLatency => 'По задержке';

  @override
  String get serversSortName => 'По имени';

  @override
  String get serversTestLatency => 'Проверить задержку';

  @override
  String get serversManualGroup => 'Мои конфиги';

  @override
  String serversUpdated(String time) {
    return 'Обновлено $time';
  }

  @override
  String serversCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n серверов',
      few: '$n сервера',
      one: '$n сервер',
      zero: 'нет серверов',
    );
    return '$_temp0';
  }

  @override
  String get serversNothingFound => 'Ничего не найдено';

  @override
  String get serversNothingFoundBody => 'Попробуйте изменить запрос или фильтр.';

  @override
  String get serversEmptyGroup => 'В этой подписке пока нет серверов.';

  @override
  String get latencyTimeout => 'тайм-аут';

  @override
  String get actionEdit => 'Изменить';

  @override
  String get actionDelete => 'Удалить';

  @override
  String get actionUpdate => 'Обновить';

  @override
  String get actionCopyLink => 'Скопировать ссылку';

  @override
  String get actionFavorite => 'В избранное';

  @override
  String get actionUnfavorite => 'Убрать из избранного';

  @override
  String get copied => 'Скопировано в буфер обмена';

  @override
  String deleteConfirmTitle(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get deleteConfirmBody => 'Это действие нельзя отменить.';

  @override
  String get deleteSubscriptionBody => 'Все серверы этой подписки тоже будут удалены.';

  @override
  String get addSheetTitle => 'Добавить';

  @override
  String get addFromUrl => 'Подписка по ссылке';

  @override
  String get addFromUrlSub => 'URL подписки или профиля';

  @override
  String get addFromClipboard => 'Из буфера обмена';

  @override
  String get addFromClipboardSub => 'vless://, vmess://, trojan://, ss://, happ:// и другие';

  @override
  String get addScanQr => 'Сканировать QR-код';

  @override
  String get addScanQrSub => 'С помощью камеры устройства';

  @override
  String get addManual => 'Вручную';

  @override
  String get addManualSub => 'Указать параметры сервера';

  @override
  String get clipboardNoLinks => 'Поддерживаемые ссылки не найдены';

  @override
  String importResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировано $count элементов',
      few: 'Импортировано $count элемента',
      one: 'Импортирован $count элемент',
    );
    return '$_temp0';
  }

  @override
  String importPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Не удалось импортировать $count элементов',
      few: 'Не удалось импортировать $count элемента',
      one: 'Не удалось импортировать $count элемент',
    );
    return '$_temp0';
  }

  @override
  String subFetchError(String reason) {
    return 'Не удалось загрузить подписку: $reason';
  }

  @override
  String get subUpdated => 'Подписка обновлена';

  @override
  String get scanHint => 'Наведите камеру на QR-код';

  @override
  String get cameraDenied => 'Нет доступа к камере';

  @override
  String get clipboardEmpty => 'Буфер обмена пуст';

  @override
  String get subAddTitle => 'Новая подписка';

  @override
  String get subEditTitle => 'Подписка';

  @override
  String get subUrlLabel => 'Ссылка на подписку';

  @override
  String get subNameLabel => 'Название (необязательно)';

  @override
  String get subAutoUpdate => 'Автообновление';

  @override
  String get subAutoUpdateSub => 'Обновлять серверы в фоне';

  @override
  String get subUpdateInterval => 'Интервал обновления';

  @override
  String get subInvalidUrl => 'Введите корректную ссылку http(s)';

  @override
  String get editorNewTitle => 'Новый сервер';

  @override
  String get editorEditTitle => 'Редактирование';

  @override
  String get editorGeneral => 'Основное';

  @override
  String get editorName => 'Название';

  @override
  String get editorProtocol => 'Протокол';

  @override
  String get editorAddress => 'Адрес';

  @override
  String get editorPort => 'Порт';

  @override
  String get editorCredentials => 'Аутентификация';

  @override
  String get editorUuid => 'UUID';

  @override
  String get editorPassword => 'Пароль';

  @override
  String get editorMethod => 'Шифр';

  @override
  String get editorFlow => 'Flow';

  @override
  String get editorTransport => 'Транспорт';

  @override
  String get editorPath => 'Путь';

  @override
  String get editorHost => 'Заголовок Host';

  @override
  String get editorServiceName => 'Имя сервиса gRPC';

  @override
  String get editorSecurity => 'Защита';

  @override
  String get editorSni => 'SNI';

  @override
  String get editorFingerprint => 'Отпечаток uTLS';

  @override
  String get editorPublicKey => 'Публичный ключ Reality';

  @override
  String get editorShortId => 'Short ID Reality';

  @override
  String get editorAllowInsecure => 'Разрешить небезопасный TLS';

  @override
  String get editorSecurityNone => 'Нет';

  @override
  String get editorObfsPassword => 'Пароль обфускации (salamander)';

  @override
  String get editorPrivateKey => 'Приватный ключ';

  @override
  String get editorPeerPublicKey => 'Публичный ключ пира';

  @override
  String get editorLocalAddress => 'Локальный адрес';

  @override
  String get editorRequired => 'Обязательное поле';

  @override
  String get editorInvalidPort => 'Порт должен быть от 1 до 65535';

  @override
  String get routingTitle => 'Маршрутизация';

  @override
  String get routingSubtitle => 'Выберите, какой трафик идёт через туннель.';

  @override
  String get routingMode => 'Режим';

  @override
  String get routingGlobal => 'Глобальный';

  @override
  String get routingGlobalSub => 'Весь трафик идёт через VPN';

  @override
  String get routingRules => 'По правилам';

  @override
  String get routingRulesSub => 'Трафик распределяется пресетами ниже';

  @override
  String get routingDirect => 'Напрямую';

  @override
  String get routingDirectSub => 'Ядро работает, трафик идёт мимо прокси';

  @override
  String get routingPresets => 'Пресеты';

  @override
  String get presetBypassLan => 'Обход локальной сети';

  @override
  String get presetBypassLanSub => 'Частные диапазоны: 192.168.x.x, 10.x.x.x и др.';

  @override
  String get presetRuDirect => 'Российские сайты напрямую';

  @override
  String get presetRuDirectSub => 'geoip:ru и geosite:category-ru';

  @override
  String get presetBlockAds => 'Блокировать рекламу';

  @override
  String get presetBlockAdsSub => 'geosite:category-ads-all';

  @override
  String get presetsInactive => 'Пресеты работают только в режиме «По правилам».';

  @override
  String get routingSplit => 'Раздельное туннелирование';

  @override
  String get splitApps => 'Приложения';

  @override
  String get splitOffSub => 'Все приложения идут через VPN';

  @override
  String splitIncludeSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Только $n приложений через VPN',
      few: 'Только $n приложения через VPN',
      one: 'Только $n приложение через VPN',
      zero: 'Приложения не выбраны',
    );
    return '$_temp0';
  }

  @override
  String splitExcludeSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n приложений в обход VPN',
      few: '$n приложения в обход VPN',
      one: '$n приложение в обход VPN',
      zero: 'Исключений нет',
    );
    return '$_temp0';
  }

  @override
  String get splitAndroidOnly => 'Доступно в Android-версии';

  @override
  String get splitModeOff => 'Выключено';

  @override
  String get splitModeInclude => 'Только выбранные';

  @override
  String get splitModeExclude => 'Все, кроме выбранных';

  @override
  String get splitSearchHint => 'Поиск приложений';

  @override
  String get splitShowSystem => 'Показывать системные';

  @override
  String get splitNoApps => 'Приложения не найдены';

  @override
  String get logsTitle => 'Логи';

  @override
  String get logsEmptyTitle => 'Пока пусто';

  @override
  String get logsEmptyBody => 'Логи ядра появятся здесь после подключения.';

  @override
  String get logsAll => 'Все';

  @override
  String get logsPause => 'Пауза';

  @override
  String get logsResume => 'Продолжить';

  @override
  String get logsCopy => 'Копировать';

  @override
  String get logsExport => 'Экспорт';

  @override
  String get logsClear => 'Очистить';

  @override
  String get logsPaused => 'Поток приостановлен';

  @override
  String logsExported(String path) {
    return 'Сохранено: $path';
  }

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsConnection => 'Подключение';

  @override
  String get settingsAutoConnect => 'Автоподключение';

  @override
  String get settingsAutoConnectSub => 'Подключаться при запуске приложения';

  @override
  String get settingsLaunchAtStartup => 'Запуск вместе с Windows';

  @override
  String get settingsLaunchAtStartupSub => 'Стартовать свёрнутым в трей';

  @override
  String get settingsKillSwitch => 'Kill switch';

  @override
  String get settingsKillSwitchAndroidSub => 'Блокировать трафик без VPN — настраивается в системе';

  @override
  String get settingsKillSwitchWindowsSub => 'Блокировать трафик при обрыве туннеля (режим TUN)';

  @override
  String get settingsWindowsMode => 'Режим туннеля';

  @override
  String get modeProxy => 'Системный прокси';

  @override
  String get modeTun => 'TUN';

  @override
  String get modeTunHint => 'TUN перехватывает весь трафик и требует прав администратора.';

  @override
  String get settingsNetwork => 'Сеть';

  @override
  String get settingsDns => 'DNS';

  @override
  String get settingsMtu => 'MTU';

  @override
  String get settingsMtuHint => 'От 1280 до 9000';

  @override
  String get settingsIpv6 => 'IPv6';

  @override
  String get settingsIpv6Sub => 'Маршрутизировать IPv6-трафик';

  @override
  String get settingsSubscriptions => 'Подписки';

  @override
  String get settingsAutoUpdate => 'Автообновление подписок';

  @override
  String get settingsAutoUpdateSub => 'По интервалу, который задаёт каждая подписка';

  @override
  String get settingsLogging => 'Уровень логирования';

  @override
  String get settingsPrivacy => 'Конфиденциальность';

  @override
  String get privacyNote =>
      'Без телеметрии и аналитики. Подписки и конфиги не покидают это устройство.';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsLicenses => 'Лицензии';

  @override
  String get settingsLicensesSub => 'Открытые компоненты, включая sing-box (GPLv3)';

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
  String get onbSkip => 'Пропустить';

  @override
  String get onbNext => 'Далее';

  @override
  String get onbStart => 'Начать';

  @override
  String get onb1Title => 'Ваш VPN — ваши правила';

  @override
  String get onb1Body =>
      'Aurora — клиент для ваших подписок и конфигов. Мы не продаём серверы и не собираем данные.';

  @override
  String get onb2Title => 'Добавьте подписку';

  @override
  String get onb2Body =>
      'Вставьте ссылку, отсканируйте QR-код или откройте ссылку vless://, vmess://, happ:// — всё импортируется автоматически.';

  @override
  String get onb3Title => 'Тонкая настройка — по желанию';

  @override
  String get onb3Body =>
      'Маршрутизация по правилам, раздельное туннелирование по приложениям и kill switch — когда понадобятся.';

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
}
