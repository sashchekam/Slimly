# Slimly

iOS-приложение (SwiftUI, Swift 6.2, iOS 17+), собирается **Tuist 4**.
Архитектура — **MVVM + декларативный Router** (вариант B, см. `ARCHITECTURE.md`).

## Команды

```bash
tuist generate --no-open        # после добавления/переименования файлов и модулей
xcodebuild -workspace Slimly.xcworkspace -scheme Slimly \
  -destination 'generic/platform=iOS Simulator' build

xcrun simctl openurl booted "slimly://home/profile"   # проверить диплинк
```

`.xcodeproj` и `.xcworkspace` — **генерируемые артефакты**, они в `.gitignore`.
Никогда не редактируй их руками: правь `Project.swift` и
`Tuist/ProjectDescriptionHelpers/Module.swift`.

Файлы подхватываются по glob'ам (`Sources/**`, `Interface/**`), но новый файл
всё равно требует `tuist generate`, иначе Xcode его не увидит.

## Структура

```
Modules/Core/SlimlyCore            — модели, сервисы, форматтеры, DeeplinkURL
Modules/Core/SlimlyDesignSystem    — токены и компоненты
Modules/Core/SlimlyNavigation      — Route, AnyRoute, Router, RouteRegistry,
                                     RouterHost, DeeplinkRegistry
Modules/Features/<Name>Feature/
  Interface/                       — только enum Route, без UI
  Sources/                         — View, ViewModel, <Name>Feature.resolver(...)
App/                               — composition root, реестр резолверов, диплинки
Tuist/ProjectDescriptionHelpers/   — реестр модулей и правила связей
```

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

## Конвенции кода

- Комментарии, UI-строки и документация — **на русском**. Идентификаторы — английские.
- Комментарий объясняет «почему», а не «что». Очевидное не комментируем.
- `public` — только то, что реально пересекает границу модуля.
- Всё, что связано с UI и навигацией, — `@MainActor`. Сервисы — `actor` или `Sendable`.
- ViewModel — `@MainActor @Observable final class`, состояние наружу через
  `private(set)`, ввод пользователя — обычные `var`.
- View принимает готовую ViewModel в `init` и держит её в `@State`.

## Грабли Swift 6 в этом проекте

- `@Observable` **несовместим с `lazy var`** («'lazy' cannot be used on a computed
  property»): инициализируй в `init` или помечай `@ObservationIgnored`.
- Статические замыкания (мэпперы диплинков) должны быть `@Sendable`, иначе
  strict concurrency их не пропустит.
- `AnyRoute` намеренно **не** конформит `Route` — так исключается двойная обёртка.
