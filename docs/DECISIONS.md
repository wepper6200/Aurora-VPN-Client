# Технические решения

Журнал решений, принятых по умолчанию. Новые записи добавляются в конец.

## Этап 1 — каркас и дизайн-система

### Название и идентификаторы
- Рабочее название **Aurora VPN** (бирюзово-фиолетовый градиент напоминает полярное сияние).
- Dart-пакет `aurora_vpn`, Android `applicationId` `dev.aurora.aurora_vpn`. Всё переименовывается в одном месте до первого релиза.

### Тулчейн
- Flutter **3.47.7** stable (Dart 3.13.5). Все инструменты лежат portable-версиями в `D:\dev`
  (Flutter, JDK 17 Microsoft Build, Go 1.27.2, MinGit, Android cmdline-tools), кэши pub, Gradle и Go тоже там.
  `scripts/dev_env.ps1` настраивает PATH для текущей сессии. Корень можно переопределить через `AURORA_TOOLS`.
- Аналитика Flutter и Dart отключена (`flutter config --no-analytics`, `dart --disable-analytics`).

### Зависимости
| Задача | Выбор | Почему |
|---|---|---|
| State | `flutter_riverpod` 3.x, без кодогенерации | Явные `Notifier`/`Provider`, меньше build_runner-магии |
| Навигация | `go_router` 18, `StatefulShellRoute` | Каждая вкладка хранит свой стек |
| Иконки | **Lucide** (`lucide_icons_flutter`) | `phosphor_flutter` 2.1.0 (последний релиз 05.2024) не компилируется на Flutter 3.47: `IconData` стал `final`. У Lucide есть начертания 100–600 |
| Шрифт | Manrope, вариативный TTF из google/fonts (OFL), лежит локально | Стили явно задают ось `wght` через `fontVariations` |
| Настройки | `shared_preferences` за интерфейсом `SettingsRepository` | Только нечувствительные данные; секреты пойдут в secure storage (этап 3) |
| БД (этап 3) | drift (SQLite) | Isar 3 фактически не поддерживается и плохо работает с AGP 8 |
| Окно Windows | `window_manager` | Кастомная заголовочная панель, минимальный размер 420×720 |

### Архитектура
```
lib/
  core/           платформа, l10n-расширения
  domain/         сущности и интерфейсы репозиториев (без Flutter)
  data/           реализации репозиториев, парсеры, платформенные адаптеры
  application/    контроллеры и use cases (Riverpod Notifier)
  presentation/   theme/, widgets/ (дизайн-система), shell/, router/, features/<screen>/
  l10n/           ARB-файлы; сгенерированный код в l10n/gen
```

### Навигация
- Пять вкладок на всех платформах: Главная, Серверы, Маршруты, Логи, Настройки.
  Material 3 допускает 5 пунктов в нижней панели, а единая структура упрощает deep-link и тесты.
- Windows всегда использует `NavigationRail`. Android переключается на rail при ширине ≥ 840 dp (планшеты).
- Вкладки переключаются кросс-фейдом с небольшим сдвигом (`AnimatedBranchContainer`).
  Неактивные ветки остаются смонтированными, их тикеры отключены.

### Дизайн-система
- Токены: радиусы 8–28, шкала отступов кратна 4, длительности 150/260/420 мс.
- `AppColors` (ThemeExtension) хранит градиенты, стеклянные поверхности и цвета статусов подключения. По умолчанию тёмная тема.
- Компоненты: `AppCard` (solid / elevated / glass / selected с градиентной обводкой), `GradientButton`, `SoftButton`,
  `AppIconButton`, `Pressable`, `StatusPill`, `IconBadge`, `SectionHeader`, `EmptyState`, `Skeleton`,
  `StaggeredEntrance`, `SettingsGroup`/`SettingsTile`, `PageScaffold`, `AppBackground`.
- Свечение фона рисуется радиальными градиентами, без blur-фильтров: дёшево и без перерастеризации при прокрутке.
- Живая витрина компонентов: Настройки → Дизайн-система.

### Тесты
- Golden-тесты (`test/golden`, тег `golden`) с реальными шрифтами, загружаемыми из FontManifest.
  Регенерация: `flutter test --update-goldens --tags golden`.
  Рендеринг шрифтов зависит от ОС, поэтому в CI golden-тесты запускаются только на Windows-раннере.

## Этап 2 — UI на моках

### Слои и моки
- Домен: `ServerProfile`, `Subscription`/`SubscriptionUsage`, `VpnState`/`TrafficSample`, `LogEntry`,
  `RoutingSettings`, `InstalledApp` и интерфейсы `ServerRepository`, `SubscriptionRepository`,
  `InstalledAppsSource`, `VpnCoreController`.
- Композиция в `lib/application/di.dart`. Пока подключены in-memory репозитории и `MockVpnCoreController`
  (реалистичные переходы состояний, трафик, логи, URL-тест). Этапы 3–5 подменят только этот файл.
- Демо-данные (`data/mock/demo_data.dart`) используют только зарезервированные домены `example.*` (RFC 2606).
  На этапе 3 они уходят из продакшен-пути и остаются только в тестах. Реальных серверов в коде нет.

### Поведение
- Выбранный сервер хранится в prefs. Если ничего не выбрано, берётся первый из избранного, затем первый вообще.
- Тест задержки идёт параллельно, пулом из 8 воркеров. Сортировка по задержке ставит недоступные в конец.
- Логи — кольцевой буфер на 2000 строк. Провайдер логов активен с запуска приложения
  (иначе строки до первого открытия вкладки терялись — найдено тестом).
- Время берётся из одного источника `nowProvider` (`package:clock`), поэтому таймер сессии и время логов
  детерминированы в тестах.
- Kill switch на Android открывает системные настройки always-on VPN (подключается на этапе 6).
  На Windows это переключатель, который работает в режиме TUN.
- Раздельное туннелирование по приложениям — только Android. На Windows пункт виден, но помечен «Доступно в Android-версии».
- Дефолты: MTU 9000 (как у sing-box TUN), DNS — DoH Cloudflare, режим маршрутизации «По правилам» с обходом LAN.

### UI
- Кнопка подключения — CustomPainter с плавной интерполяцией палитры между состояниями,
  пульсирующими кольцами (connected) и вращающейся дугой (connecting). Контроллеры анимаций
  работают только когда нужны. Haptic: medium по тапу, heavy при подключении.
- Sparkline плавно сдвигается при поступлении новой точки (1 Гц данных → 60 fps анимации).
  При подключении история заполняется нулями, чтобы линия сразу шла на всю ширину.
- Логи — моноширинный JetBrains Mono (OFL, локально), висячий отступ, список `reverse` прилипает к низу.
- Избранное — заполненная звезда Material (в Lucide нет залитых глифов).

## Этап 3 — парсеры, хранилище, подписки, генератор конфигов

### Модель
- `OutboundConfig` — одна плоская неизменяемая модель для всех 7 протоколов: транспорт (tcp/ws/grpc/h2/httpupgrade)
  и TLS (none/tls/reality + uTLS). JSON-сериализация нужна для зашифрованного хранения. Отдельный класс на каждый
  протокол удвоил бы код парсеров, хранилища и редактора без выигрыша.
- `ServerProfile.identity` = протокол + хост + порт + имя. При обновлении подписки сервер с той же identity
  сохраняет `id`, а с ним избранное и текущий выбор.

### Парсеры
- Ссылки: vless, vmess (base64 JSON), trojan, ss (SIP002, SIP022 для 2022-шифров, legacy base64), hysteria2/hy2
  (obfs salamander, port hopping — берётся первый порт), tuic, wireguard/wg, `happ://add/<url>`.
  Authority и query разбираются вручную, без `Uri.parse`: IPv6 в скобках, пароли со спецсимволами, `+` остаётся `+`.
- Не поддерживается (с понятной ошибкой): xhttp/kcp/quic-транспорты (их нет в sing-box), плагины Shadowsocks,
  зашифрованные `happ://crypt…` (проприетарный ключ Happ).
- Подписки: формат определяется автоматически — sing-box JSON (`outbounds` + `endpoints`), список ссылок,
  base64-список (стандартный и URL-safe, с переносами), Clash/mihomo YAML (`proxies`).
- Заголовки: `subscription-userinfo`, `profile-update-interval`, `profile-title` (в т.ч. `base64:`),
  `content-disposition` как запасной источник имени, `support-url`. Интервал из заголовка используется,
  пока пользователь не выбрал свой в форме.
- User-Agent `AuroraVPN/0.1`: клиент представляется честно, без маскировки под чужие приложения.
  Панели на неизвестный UA отдают base64-список, его мы разбираем.

### Хранилище
- drift (SQLite), таблицы `subscriptions` и `servers`, `ON DELETE CASCADE`.
- Учётные данные серверов (UUID, пароли, ключи, параметры TLS) и URL подписок (в них токены) шифруются
  AES-256-GCM (`package:cryptography`). Случайный 256-битный ключ создаётся один раз и хранится в
  `flutter_secure_storage` (Android Keystore / Windows DPAPI). Имя, хост, порт и протокол хранятся открыто,
  они нужны для списков и поиска.
- Строки, которые не удалось расшифровать (например, после сброса хранилища ключей), пропускаются, без падения.
- База лежит в каталоге application support (на Windows — `%APPDATA%`, не «Документы»).
- Демо-данные больше не попадают в продакшен. Приложение стартует пустым, демо используется только в тестах.

### Генератор sing-box
- Целевая версия ядра **1.14.3**. Формат 1.12+: DNS-серверы нового вида (`type: https/tls/udp/local`),
  `route.default_domain_resolver`, rule actions (`sniff`, `hijack-dns`, `reject`), WireGuard через `endpoints`.
  Устаревших outbound'ов `block`/`dns` нет.
- Каждая комбинация протокол × транспорт × режим проверяется настоящим `sing-box check`
  (`test/integration_core`, тег `core`): 12 конфигов, 0 ошибок, 0 предупреждений.
- Rule-set'ы (geoip-ru, geosite-category-ru, geosite-category-ads-all) **локальные**. Они скачиваются
  `fetch_core` с закреплённых коммитов, кладутся в ассеты и подключаются как `type: local`. Ядру не нужно ходить
  на GitHub при старте: запуск быстрее, работает офлайн, нет лишних внешних запросов.
- Если IPv6 выключен, туннель всё равно захватывает v6 и отклоняет его, чтобы IPv6 не утекал мимо VPN.
  Для DNS при этом стоит `ipv4_only`.
- Kill switch на Windows = `strict_route` в режиме TUN. На Android `strict_route` включён всегда.

### Задержка
- TCP-handshake до сервера без DNS-резолва (`TcpLatencyTester`) работает без ядра и без прав.
  Для UDP-протоколов (Hysteria2, TUIC, WireGuard) так не измерить: они пропускаются, URL-тест через ядро
  появится на этапах 4–5.

### Загрузка ядра
- `scripts/fetch_core.ps1`: sing-box.exe (GitHub SagerNet), wintun.dll (wintun.net), rule-set'ы.
  SHA-256 закреплены в `scripts/core_versions.json` (хэш wintun сверен с опубликованным на сайте), при
  несовпадении скрипт останавливается. Бинарники и `.srs` в `.gitignore`.
- В релизах sing-box нет готового `libbox.aar`: на этапе 4 он собирается из исходников через gomobile.

### Импорт
- Один `ImportService` для буфера обмена, QR (`mobile_scanner`, только Android) и deep-link (`app_links`,
  Android intent-filter для всех схем). Одиночный http(s)-URL из буфера открывает форму подписки, всё остальное
  импортируется сразу. Повторно ту же подписку не добавляет.
