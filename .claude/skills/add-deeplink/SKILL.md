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
3. `router.replace(with: routes)` — **первый** маршрут становится корнем,
   остальные ложатся в стек. Модалки при этом закрываются.

Табов в приложении нет: роутер один, корень — `HomeRoute.home`.

## Шаги

### 1. Мэппер

`App/Sources/DeeplinkMap.swift` — единственное место, где известны маршруты всех фич.

```swift
/// `slimly://convert/photo`, `slimly://convert/video`
private static let convert: DeeplinkRegistry.Mapper = { deeplink in
    guard
        deeplink.host == "convert",
        deeplink.pathComponents.count == 1,
        let kind = ConvertKind(rawValue: deeplink.pathComponents[0])
    else { return nil }
    return [HomeRoute.home, ConvertRoute.picker(kind)]
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
xcrun simctl openurl booted "slimly://convert/photo"
```

Симулятор показывает системный алерт «Open in Slimly?» — это нормально,
нужно подтвердить.

## Правила

- Первый маршрут — всегда `HomeRoute.home`, иначе экран откроется без родителя
  и кнопка «Назад» уведёт в пустоту.
- Ссылками открываются только входы во флоу (`CompressRoute.picker`,
  `ScanRoute.intro`). Внутренние шаги требуют конкретных файлов медиатеки
  и заданий на обработку — такое в URL не положишь.
- Маршруты, которые в UI показываются модалкой (`CompressRoute.level`),
  в диплинке не используются: `replace(with:)` строит стек, и закрытие модалки
  окажется мёртвым.
- Диплинк — рабочий способ дойти до экрана при проверке вёрстки в симуляторе;
  для внутренних шагов проще временный мэппер, чем клики.
