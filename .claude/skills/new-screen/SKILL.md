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
public enum DiaryRoute: Route {
    case today
    case meal(id: UUID)
}
```

Маршрут описывает **что открыть**, а не как: способ показа выбирает вызывающая
сторона (`push` / `present` / `cover`).

### 2. View + ViewModel

В `Sources/`. ViewModel получает `Router` и сервисы в `init`, наружу отдаёт
состояние через `private(set)`:

```swift
@MainActor
@Observable
public final class MealViewModel {
    public private(set) var meal: Meal?

    private let storage: any MealStorage
    private let router: Router

    public init(id: UUID, storage: any MealStorage, router: Router) { … }
}
```

View держит ViewModel в `@State`, загрузку делает через `.task { await viewModel.load() }`.
Стили и отступы — только из `SlimlyDesignSystem`.

### 3. Ветка резолвера

`Sources/<Name>Feature.swift` — новый `case` в `switch`. `switch` без `default`,
чтобы компилятор ловил забытые экраны.

### 4. Вызов

```swift
router.push(DiaryRoute.meal(id: id))        // в стек
router.present(DiaryRoute.meal(id: id))     // модалкой, со своим вложенным Router
```

Из другой фичи — то же самое, но с импортом `DiaryFeatureInterface`.

### 5. Проверка

`tuist generate --no-open`, затем сборка. Если экран должен открываться ссылкой —
дальше по скиллу `add-deeplink`.

## Чего не делать

- Не вызывать `router` прямо из `View` — навигация живёт в ViewModel.
- Не передавать во `View` больше, чем её ViewModel.
- Не хранить в маршруте тяжёлые объекты: только идентификаторы и мелкие значения.
