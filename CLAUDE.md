# Slimly

iOS-приложение (SwiftUI, Swift 6.2, iOS 17+), собирается **Tuist 4**.
Архитектура — **MVVM + декларативный Router** (вариант B, см. `ARCHITECTURE.md`).

## Команды

```bash
tuist generate --no-open        # после добавления/переименования файлов и модулей
xcodebuild -workspace Slimly.xcworkspace -scheme Slimly \
  -destination 'generic/platform=iOS Simulator' build

xcrun simctl openurl booted "slimly://profile"   # проверить диплинк

swiftlint lint --strict --quiet  # линтер: обязателен в конце любой доработки
swiftlint --fix --quiet          # автоисправимое (порядок импортов, запятые, отступы)
```

`.xcodeproj` и `.xcworkspace` — **генерируемые артефакты**, они в `.gitignore`.
Никогда не редактируй их руками: правь `Project.swift` и
`Tuist/ProjectDescriptionHelpers/Module.swift`.

Файлы подхватываются по glob'ам (`Sources/**`, `Interface/**`), но новый файл
всё равно требует `tuist generate`, иначе Xcode его не увидит.

## Структура

```
Modules/Core/SlimlyCore            — модели, протоколы сервисов, форматтеры,
                                     DeeplinkURL (без системных фреймворков)
Modules/Core/SlimlyDesignSystem    — токены Nocturne и компоненты
Modules/Core/SlimlyNavigation      — Route, AnyRoute, Router, TabRouter,
                                     RouteRegistry, RouterHost, TabRouterHost,
                                     DeeplinkRegistry
Modules/Core/SlimlyMediaKit       — единственный модуль, знающий про PhotoKit
                                     и AVFoundation: медиатека, перекодирование,
                                     сохранение результата
Modules/Core/SlimlyMediaFlow       — общие шаги флоу обработки: выбор файлов,
                                     формат, обработка, итог
Modules/Features/<Name>Feature/
  Interface/                       — только enum Route, без UI
  Sources/                         — View, ViewModel, <Name>Feature.resolver(...)
App/                               — composition root, реестр резолверов,
                                     состав главного экрана, диплинки
Tuist/ProjectDescriptionHelpers/   — реестр модулей и правила связей
```

Реализации сервисов живут в `SlimlyMediaKit`, а протоколы — в `SlimlyCore`:
фича видит только протокол, поэтому не тянет за собой PhotoKit.

Главный экран (`HomeFeature`) — хаб инструментов, а каждый инструмент —
свой модуль: `CompressFeature`, `ConvertFeature`, `AudioFeature`, `ScanFeature`.
Общие шаги у них одни (`SlimlyMediaFlow`), различаются конфиг и то, что есть
только у инструмента. Табов в приложении нет: навигация — один стек с корнем
`HomeRoute.home`.

## Архитектурные правила (не нарушать)

1. **Навигация — это состояние.** Экран открывается изменением `Router`
   (`push` / `present` / `cover` / `replace` / `restart`), а не императивным вызовом.
   Никакого UIKit и `UIHostingController`.
2. **Фича не импортирует другую фичу** — только её `*FeatureInterface`.
   Нарушение валит `tuist generate` через `Module.validated`.
3. **Фича не знает про `AppContainer`.** Зависимости приходят явными параметрами
   в `<Name>Feature.resolver(authService:...)`. Обратной зависимости App → фича
   в коде фичи быть не должно.
4. **ViewModel получает `Router` в конструкторе** — так навигация тестируется как
   чистая функция над состоянием (`router.path == [...]`). View роутер напрямую
   не дёргает; при необходимости берёт из `@Environment(Router.self)`.
5. **Маршрут не знает про способ показа.** Один и тот же `Route` можно и
   запушить, и показать модалкой — решает вызывающая сторона.

## SwiftLint

Правила лежат в `.swiftlint.yml` (в корне), сам линтер ставится через
`brew install swiftlint`. Он же висит фазой `SwiftLint` перед компиляцией
приложения, причём с `--strict`: **любое замечание валит сборку**, даже
предупреждение.

**Заканчивая любую доработку — прогони `swiftlint lint --strict --quiet` и
почини всё, что он нашёл.** Целевое состояние репозитория — ноль замечаний,
поэтому вывод линтера всегда либо пустой, либо про твои изменения.

Порядок работы: сначала `swiftlint --fix --quiet` (он сам чинит импорты,
запятые и отступы), потом руками остальное. Правило глушится точечным
`// swiftlint:disable:next <rule>` с комментарием «почему» — и только когда
нарушение осознанное (`layer as! AVPlayerLayer` при заданном `layerClass`).
Массовые `disable` на файл и правку `.swiftlint.yml` под конкретный случай
не используем: если правило мешает постоянно — обсуждаем его отключение.

## Конвенции кода

- Комментарии, UI-строки и документация — **на русском**. Идентификаторы — английские.
- Комментарий объясняет «почему», а не «что». Очевидное не комментируем.
- `public` — только то, что реально пересекает границу модуля.
- Всё, что связано с UI и навигацией, — `@MainActor`. Сервисы — `actor` или `Sendable`.
- ViewModel — `@MainActor @Observable final class`, состояние наружу через
  `private(set)`, ввод пользователя — обычные `var`.
- View принимает готовую ViewModel в `init` и держит её в `@State`.
- Property wrapper (`@State`, `@Binding`, `@Environment`, `@ObservationIgnored`
  и т.п.) и `@ViewBuilder` — на отдельной строке над объявлением; за этим
  следит правило `attributes`.
- **Никаких `enum` со `static func` вместо сервисов.** Работа — это объект
  за протоколом, который приходит в `init` параметром со значением
  по умолчанию (`init(images: any ImageEncoding = ImageEncoder())`).
  Большой класс разбирается на маленькие воркеры, каждый в своём файле.
  Подробности и чек-лист — в скилле `small-workers`.

## Грабли Swift 6 в этом проекте

- `@Observable` **несовместим с `lazy var`** («'lazy' cannot be used on a computed
  property»): инициализируй в `init` или помечай `@ObservationIgnored`.
- Статические замыкания (мэпперы диплинков) должны быть `@Sendable`, иначе
  strict concurrency их не пропустит.
- `AnyRoute` намеренно **не** конформит `Route` — так исключается двойная обёртка.
