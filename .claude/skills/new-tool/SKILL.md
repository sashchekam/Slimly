---
name: new-tool
description: Добавить в Slimly новый инструмент обработки файлов (сжатие, конвертация, извлечение звука, скан и т.п.) — модуль флоу поверх общих шагов SlimlyMediaFlow, карточка на главной, диплинк. Использовать, когда просят новый инструмент, новый пункт хаба на главном экране или новый вид обработки медиа.
---

# Новый инструмент

Инструмент = свой фичевый модуль + карточка на главной. Экраны при этом
**не пишутся заново**: путь «выбор файлов → настройки → обработка → итог»
один на всех и живёт в `Modules/Core/SlimlyMediaFlow`. Модулю остаются
маршруты, конфиг шагов и то, что есть только у него.

Эталоны: `ConvertFeature` (голый общий путь), `ScanFeature` (свой первый шаг),
`CompressFeature` (своя шторка настроек и сравнение «до / после»).

## 1. Модуль

Заводится как обычная фича — по скиллу `new-feature`, но в зависимостях
модуля-реализации обязателен `.mediaFlow`:

```swift
case .<name>: [.core, .designSystem, .navigation, .mediaFlow, .<name>Interface]
```

## 2. Маршруты

`Interface/<Name>Route.swift` — по шагу на кейс. Шаги несут данные, а не ссылку
на объект сессии: состояние флоу целиком лежит в `Router`.

```swift
public enum <Name>Route: Route {
    case picker
    case format(items: [MediaItem])
    case run(ProcessingRequest)
    case outcome(ProcessingOutcome)
}
```

## 3. Резолвер и конфиги

`Sources/<Name>Feature.swift` — вся фича обычно помещается в один файл:

```swift
RouteResolver(for: <Name>Route.self) { route, router in
    switch route {
    case .picker:
        MediaPickerView(viewModel: MediaPickerViewModel(
            config: pickerConfig,
            library: mediaLibrary,
            router: router,
            destination: { .push(<Name>Route.format(items: $0)) }   // или .present для шторки
        ))

    case let .format(items):
        FormatStepView(viewModel: FormatStepViewModel(
            config: formatConfig,
            items: items,
            router: router,
            thumbnails: mediaLibrary.thumbnailLoader,
            run: { <Name>Route.run($0) }
        ))

    case let .run(request):
        ProcessingView(viewModel: ProcessingViewModel(
            request: request,
            service: processingService,
            router: router,
            thumbnails: mediaLibrary.thumbnailLoader,
            outcome: { <Name>Route.outcome($0) }
        ))

    case let .outcome(outcome):
        OutcomeView(viewModel: OutcomeViewModel(
            outcome: outcome,
            library: mediaLibrary,
            router: router
        ))
    }
}
```

`MediaPickerConfig` — `title`, `hint`, `footnote`, `kind`
(`nil` — фото и видео вместе), `limit`, `noun`.
`FormatStepConfig` — `title`, `note`, `actionTitle`, `sourceFormat`, `formats`,
`noun` и `makeOperation` — что делать с выбранным форматом
(`{ .convert($0) }`, `{ .extractAudio($0) }`). Исходный формат из списка
вычёркивается сам.

`MediaFormat` несёт не только подпись, но и `ProcessingTarget` — то, что
обработчик умеет исполнить: `.image(.heic)`, `.video(container:codec:)`,
`.audio(.aac(kilobits: 128))`. Формата, которого нет в `ProcessingTarget`,
в списке быть не должно — иначе экран обещает то, чего система не сделает.

Что уже решено за тебя и переписывать не нужно: пилюля «2 из 5» и приглушённые
плитки сверх лимита, порядок выбора (у скана он становится порядком страниц),
замена экрана обработки итогом в стеке, «Удалить оригиналы» и сравнение
«до / после» — включаются по `ProcessingKind`.

## 4. Новый вид работы

Если инструмент делает не сжатие/конвертацию/звук/скан, нужны три правки:

1. `ProcessingKind` и `ProcessingOperation` в `SlimlyCore/Models/Processing.swift`
   — новый кейс работы и, если нужно, новый `ProcessingTarget`;
2. `FlowCopy` в `SlimlyMediaFlow/Model` — слово на кольце, кикер итога, строка
   под цифрой, право предлагать удаление оригиналов и сравнение;
3. `MediaProcessor` в `SlimlyMediaKit` — собственно обработка: без неё файл
   попадёт в список отказов с текстом «не реализовано».

Компилятор покажет все места — `switch` намеренно без `default`.

Коэффициент веса — это только оценка для экрана: обработчик берёт настройки
из `ProcessingOperation`, а не из числа «доля веса».

## 5. Регистрация

- `AppContainer` — резолвер в `RouteRegistry`;
- `App/Sources/HomeTools.swift` — карточка: заголовок, подпись, иконка, маршрут
  (`isWide: true` — во всю ширину сетки);
- `App/Sources/DeeplinkMap.swift` — `slimly://<name>`, первым маршрутом `HomeRoute.home`;
- `SlimlyIcon.Kind` — иконка, если подходящей нет.

## 6. Проверка

```bash
tuist generate --no-open
xcodebuild -workspace Slimly.xcworkspace -scheme Slimly \
  -destination 'generic/platform=iOS Simulator' build
xcrun simctl openurl booted "slimly://<name>"
```

## Чего не делать

- Не копировать `MediaPickerView` / `ProcessingView` / `OutcomeView` в фичу
  ради «пары отличий» — отличия выражаются конфигом и `ProcessingKind`.
- Не хранить выбранные файлы в сервисе или в синглтоне: они едут в маршруте,
  поэтому любой шаг восстанавливается одним присвоением роутера.
- Не складывать вес конвертации в «освобождено» — конвертация может файл
  и утяжелить, для неё в `ProcessingStats` отдельный счётчик.
