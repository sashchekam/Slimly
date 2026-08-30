---
name: new-screen
description: Добавить экран в существующую фичу Slimly — кейс маршрута, View, ViewModel и ветку резолвера. Использовать, когда просят добавить экран, страницу, модалку, шит или fullScreenCover внутри уже существующего модуля фичи.
---

# Новый экран в существующей фиче

Экран = кейс `Route` + `View` + `ViewModel` + ветка в резолвере. Четыре правки,
новых таргетов не появляется.

## Шаги

### 1. Маршрут

`Modules/Features/<Name>Feature/Interface/<Name>Route.swift` — новый кейс.
Ассоциированные значения допустимы, если тип `Hashable & Sendable`:

```swift
public enum CompressRoute: Route {
    case picker
    case level(items: [MediaItem])
    case outcome(ProcessingOutcome)
}
```

Маршрут описывает **что открыть**, а не как: способ показа выбирает вызывающая
сторона (`push` / `present` / `cover`).

### 2. View + ViewModel

В `Sources/`. ViewModel получает `Router` и сервисы в `init`. Неизменяемый вход —
`let`, вычисленное состояние — `private(set) var`, ввод пользователя — обычный `var`:

```swift
@MainActor
@Observable
public final class ComparisonViewModel {
    public let result: ProcessingResult          // вход шага
    public var side: Side = .after               // переключатель на экране

    private let router: Router

    public init(result: ProcessingResult, router: Router) { … }
}
```

View держит ViewModel в `@State`, загрузку делает через `.task { await viewModel.load() }`.
Стили и отступы — только из `SlimlyDesignSystem`.

### 3. Ветка резолвера

`Sources/<Name>Feature.swift` — новый `case` в `switch`. `switch` без `default`,
чтобы компилятор ловил забытые экраны.

### 4. Вызов

```swift
router.push(CompressRoute.outcome(outcome))     // в стек
router.present(CompressRoute.level(items: items)) // модалкой, со своим вложенным Router
router.setPath([CompressRoute.outcome(outcome)])  // заменить стек целиком
router.popToRoot()                                // вернуться на главную
```

Из другой фичи — то же самое, но с импортом `CompressFeatureInterface`.

Экран **внутри модалки** живёт в собственном дочернем роутере. Чтобы уйти
из шторки в стек под ней, закрой её и толкай маршрут родителю — так делает
`LevelSheetViewModel`:

```swift
let parent = router.parent ?? router
router.dismiss()
parent.push(CompressRoute.run(request))
```

### 5. Проверка

`tuist generate --no-open`, затем сборка. Если экран должен открываться ссылкой —
дальше по скиллу `add-deeplink`. Вёрстку смотри в симуляторе: `#Preview`
в проекте не используются, до экрана быстрее дойти диплинком (см. `design-system`).

## Чего не делать

- Не вызывать `router` прямо из `View` — навигация живёт в ViewModel.
- Не передавать во `View` больше, чем её ViewModel.
- Не хранить в маршруте тяжёлые объекты: идентификаторы, выбранные файлы
  и задание на обработку — да, изображения и сервисы — нет.
- Не вешать шапку через `safeAreaInset(edge: .top)`: она рисуется соседом
  скролла, иначе контент проступает под статус-баром (см. `design-system`).
