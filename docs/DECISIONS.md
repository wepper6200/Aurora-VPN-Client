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
