---
name: add-deeplink
description: Добавить или изменить диплинк в Slimly — маппинг slimly://-ссылки в маршруты, регистрация мэппера, проверка в симуляторе. Использовать при работе с deeplink, universal link, push-переходами по ссылке и схемой slimly://.
---

# Диплинк

Диплинк — это одно присвоение состояния роутера. Никакого проигрывания цепочки
переходов по шагам.

## Как устроено

1. `SlimlyApp.onOpenURL` → `DeeplinkURL(url:)` разбирает `slimly://host/path?query`
   (`Modules/Core/SlimlyCore/Sources/Deeplink/DeeplinkURL.swift`).
2. `AppContainer.handle(_:)` спрашивает `DeeplinkRegistry` о маршрутах.
3. `rootRouter.replace(with: routes)` — **первый** маршрут становится корнем,
   остальные ложатся в стек. Модалки при этом закрываются.

## Шаги

### 1. Мэппер

`App/Sources/DeeplinkMap.swift` — единственное место, где известны маршруты всех фич.

```swift
/// `slimly://diary`, `slimly://diary/meal?id=<uuid>`
private static let diary: DeeplinkRegistry.Mapper = { deeplink in
    guard deeplink.host == "diary" else { return nil }
    switch deeplink.pathComponents.first {
    case nil:
        return [DiaryRoute.today]
    case "meal":
        guard let raw = deeplink[query: "id"], let id = UUID(uuidString: raw) else { return nil }
        return [DiaryRoute.today, DiaryRoute.meal(id: id)]
    default:
        return nil
    }
}
```

Мэппер обязан быть `@Sendable` (тип `DeeplinkRegistry.Mapper` это уже задаёт) —
иначе strict concurrency не пропустит статическое свойство.

Вернуть `nil` — «это не мой URL, пусть попробует следующий». Неизвестный URL
должен приводить к `nil`, а не к случайному экрану.

### 2. Регистрация

Добавить мэппер в `DeeplinkMap.mappers`. Порядок важен: выигрывает первый,
вернувший непустой массив.

### 3. Новая схема (если нужна)

`Project.swift` → `CFBundleURLTypes` → `CFBundleURLSchemes`. Текущая схема — `slimly`.

### 4. Проверка

```bash
tuist generate --no-open
xcrun simctl openurl booted "slimly://diary/meal?id=<uuid>"
```

Симулятор показывает системный алерт «Open in Slimly?» — это нормально,
нужно подтвердить.

## Правила

- Первый маршрут — всегда корень «мира» (например `DiaryRoute.today`), иначе экран
  откроется без родителя и без кнопки «назад».
- Маршруты, которые в UI показываются модалкой, в диплинке лучше не использовать:
  `replace(with:)` строит стек, и кнопка закрытия модалки окажется мёртвой.
- Экран, требующий авторизации, не должен открываться поверх экрана логина —
  проверяй состояние `AuthService` в `AppContainer.handle(_:)`.
