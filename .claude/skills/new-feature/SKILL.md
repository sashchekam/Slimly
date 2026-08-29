---
name: new-feature
description: Создать новый фичевый модуль в Slimly по архитектуре B — пара Interface/Sources, маршруты, резолвер, регистрация в Tuist и App. Использовать, когда просят добавить фичу, новый экранный модуль или новый раздел приложения (дневник, пейволл, онбординг, настройки и т.п.).
---

# Новая фича

Фича = два таргета: тонкий `<Name>FeatureInterface` (только маршруты, без UI)
и `<Name>Feature` (View, ViewModel, резолвер). Эталон — `Modules/Features/HomeFeature`.

## Шаги

### 1. Файлы

```
Modules/Features/<Name>Feature/
  Interface/<Name>Route.swift
  Sources/<Name>View.swift
  Sources/<Name>ViewModel.swift
  Sources/<Name>Feature.swift
```

`Interface/<Name>Route.swift` — импортирует только `SlimlyNavigation`:

```swift
import SlimlyNavigation

/// Публичный вход в фичу <…>.
public enum <Name>Route: Route {
    case root
}
```

`Sources/<Name>Feature.swift` — точка сборки. Зависимости приходят явными
параметрами, `AppContainer` фиче неизвестен:

```swift
public enum <Name>Feature {
    @MainActor
    public static func resolver(authService: any AuthService) -> RouteResolver {
        RouteResolver(for: <Name>Route.self) { route, router in
            switch route {
            case .root:
                <Name>View(viewModel: <Name>ViewModel(authService: authService, router: router))
            }
        }
    }
}
```

ViewModel — `@MainActor @Observable final class`, получает `Router` в `init`.

### 2. Реестр модулей

`Tuist/ProjectDescriptionHelpers/Module.swift` — добавить **два** кейса
(`<name>Interface` и `<name>`) в `enum Module` и во все `switch`:
`kind`, `name`, `path`, `dependencies`.

- `<name>Interface` → `[.navigation]`
- `<name>` → `[.core, .designSystem, .navigation, .<name>Interface]` + `*Interface`
  тех фич, чьи экраны она открывает

Кейс должен попасть в `allCases` — порядок объявления задаёт порядок таргетов.

### 3. Регистрация в App

`App/Sources/AppContainer.swift` → добавить резолвер в `RouteRegistry`:

```swift
registry = RouteRegistry([
    CompressFeature.resolver(
        mediaLibrary: mediaLibrary,
        compressionService: compressionService,
        showProfile: { tabRouter.selection = SqueezeTab.profile.id }
    ),
    <Name>Feature.resolver(mediaLibrary: mediaLibrary),
])
```

Импорт `<Name>Feature` и `<Name>FeatureInterface` — там же.

Если фича должна стать отдельным табом — добавь кейс в `App/Sources/SqueezeTab.swift`:
корень таба, заголовок, иконку и ветку в `owner(of:)` для диплинков.

### 4. Проверка

```bash
tuist generate --no-open
xcodebuild -workspace Slimly.xcworkspace -scheme Slimly \
  -destination 'generic/platform=iOS Simulator' build
```

## Чего не делать

- Не импортировать чужой `<Other>Feature` — только `<Other>FeatureInterface`.
  `Module.validated` уронит `tuist generate` с объяснением.
- Не тащить `AppContainer` в фичу.
- Не класть UI, ViewModel или зависимости в `Interface/` — там живут только маршруты.
