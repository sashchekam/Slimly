# Slimly

iOS-приложение (SwiftUI, Swift 6.2, iOS 17+), собирается **Tuist 4**.
Архитектура — **MVVM + декларативный Router** (вариант B, см. `ARCHITECTURE.md`).

## Команды

```bash
tuist install                   # после правки Tuist/Package.swift (зависимости SPM)
tuist generate --no-open        # после добавления/переименования файлов и модулей
xcodebuild -workspace Slimly.xcworkspace -scheme Slimly \
  -destination 'generic/platform=iOS Simulator' build

xcrun simctl openurl booted "slimly://profile"   # проверить диплинк

swift Tools/AnalyticsRegistry.swift  # пересобрать ANALYTICS.md после правки событий
swift Tools/L10nGenerator.swift      # пересобрать L10n после правки строкового каталога

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
Modules/Core/SlimlyFirebase        — единственный модуль, знающий про Firebase
                                     SDK: аналитика и удалённый конфиг
Modules/Core/SlimlyPurchases       — единственный модуль, знающий про RevenueCat:
                                     витрина тарифов и покупка
Modules/Features/<Name>Feature/
  Interface/                       — только enum Route, без UI
  Sources/                         — View, ViewModel, <Name>Feature.resolver(...)
App/                               — composition root, реестр резолверов,
                                     состав главного экрана, диплинки
Tuist/ProjectDescriptionHelpers/   — реестр модулей и правила связей
```

Реализации сервисов живут в `SlimlyMediaKit` и `SlimlyFirebase`, а протоколы —
в `SlimlyCore`: фича видит только протокол, поэтому не тянет за собой
ни PhotoKit, ни Firebase.

Пейволл — своя фича (`PaywallFeature`): её маршрут приходит значением
и в профиль, и в шаг выбора файлов, и в конец тура, поэтому про неё
не знает ни один из них.

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

## Аналитика и удалённый конфиг

Протоколы `AnalyticsService` и `RemoteConfigService` живут в `SlimlyCore`,
реализации на Firebase — в `SlimlyFirebase`. Про SDK знает только этот модуль:
наружу он отдаёт `FirebaseServices` с двумя протоколами, и собирает их App.

Общая аналитика одна на приложение и приходит в фичу параметром резолвера.
Своих событий фича в неё не пишет напрямую — она заводит свой объект поверх
(`FeatureAnalytics`): префикс модуля, свой словарь событий, имена в одном
файле. Образец — `App/Sources/AppAnalytics.swift`.

```swift
struct CompressAnalytics: FeatureAnalytics {
    static let scope = "compress"
    let analytics: any AnalyticsService

    func didPickFiles(_ count: Int) {
        track("files_picked", ["count": .int(count)])
    }
}
```

Все события лежат в `ANALYTICS.md`. Файл собирается из кода скриптом
`Tools/AnalyticsRegistry.swift` и руками не правится; фаза сборки
`AnalyticsRegistry` валит сборку, если он отстал от кода. Конвенция имён
и порядок работы — в скилле `analytics-event`.

Ключ удалённого конфига объявляется расширением `RemoteConfigKey` рядом
с тем, кто им пользуется, — как `StorageKey`. Умолчание лежит в самом ключе,
поэтому без сети и без Firebase значение всё равно есть:

```swift
public extension RemoteConfigKey where Value == Bool {
    static var paywallEnabled: RemoteConfigKey { RemoteConfigKey("paywall_enabled", default: false) }
}
```

`GoogleService-Info.plist` в репозитории нет — положи его в `App/Resources/`
(он подхватится глобом) и выполни `tuist generate`. Без файла приложение
работает как обычно: события уходят в `NoAnalytics`, конфиг отдаёт умолчания.

## Покупки

Протоколы `PurchaseService` и `ProSubscription` живут в `SlimlyCore`,
реализация на RevenueCat — в `SlimlyPurchases`. Про SDK знает только этот
модуль: наружу он отдаёт `PurchasesServices` с магазином за протоколом
и тарифом, за которым наблюдают экраны.

Тариф — один экземпляр на приложение (`StoredProSubscription`): его меняет
ответ магазина, тумблер отладочного меню ставит туда же, а пределы
инструментов и плашка профиля читают его же.

Ключа в репозитории нет — положи `RevenueCat-Info.plist` в `App/Resources/`
и выполни `tuist generate`:

```xml
<key>API_KEY</key>
<string>appl_…</string>
```

Право в кабинете RevenueCat зовётся `pro`, тарифы берутся из текущего
offering — экраны спрашивают «есть ли Pro», а не «какой продукт куплен».
Без файла отладочная сборка показывает витрину-образец с придуманными ценами
(`SamplePurchases`), а релизная — пустой магазин: сборка без ключей работает,
просто без подписки.

Пейволл открывается ссылкой `slimly://paywall` — так его проверяют, не проходя
весь путь до него. Показ после тура выключается ключом `paywall_after_tour`.

## Локализация

Приложение переведено на десять языков: `en` (язык разработки), `de`, `es`,
`fr`, `it`, `ja`, `ko`, `pt-BR`, `ru`, `zh-Hans`.

Строки живут в `Localizable.xcstrings` **в папке `Resources/` своего модуля**,
а не одним файлом на приложение: модуль остаётся самодостаточным, и виджет
берёт свои строки из `SlimlyShortcuts`, не заглядывая в бандл приложения.

Ключ — адрес вида `section.name`, английский текст лежит значением для `en`.
В коде строку зовут только через `L10n` — структуру, которую собирает
`swift Tools/L10nGenerator.swift` из каталога модуля:

```swift
Text(L10n.Home.title)                       // во View
L10n.Picker.next(count)                     // строка с аргументом — функция
.accessibilityLabel(Text(L10n.Common.back)) // модификаторы берут Text
Text(verbatim: "\(count)")                  // числа и форматы не переводим
```

Почему не `String(localized:)`: он игнорирует переданную локаль и берёт язык,
выбранный при запуске, — сменить его на ходу нечем. `L10n` ходит через
`L10nBundle` (SlimlyCore), а тот отдаёт `.lproj` выбранного языка, поэтому
экран переводится сразу. Ставит язык `StoredLocalization.setPreferred`.

Смена языка на ходу пересобирает дерево экранов: корень вешает
`.id(localization.current)` на `RouterHost`, потому что строка приходит обычным
`String` и сама по себе ни одну перерисовку не вызывает. Путь при этом
сохраняется — он живёт в роутере, а не в снесённых вью. Отсюда два правила:
список, собранный заранее (плитки главной), приходит в резолвер замыканием,
а не готовым массивом; локаль для чисел и дат берётся из `L10nBundle.locale`,
потому что `Locale.current` после ручного выбора остаётся системной.

Раздел — это экран или роль строки (`quality`, `failureDetail`), уровня ровно
два: глубже не пропустит `nesting` у SwiftLint, да и адрес из четырёх частей
на месте вызова не читается. Имена — по смыслу строки, а не по её тексту:
`qualitySummary.medium`, а не `1080pLowerBitrate`.

Порядок работы: добавил ключ в каталог → `swift Tools/L10nGenerator.swift` →
зовёшь `L10n`. Фаза сборки `L10nGenerator` валит сборку, если файл отстал
от каталога. Сгенерированный `Sources/Generated/L10n.swift` руками не правят.

**На `L10n` переехали все модули** — и core, и фичи: `String(localized:)`
и `Text(_:bundle:)` в них не осталось. Каталог, где переименована только часть
ключей, генератор считает ошибкой: модуль переезжает целиком за один заход.

Виджет — исключение, и оно не временное. Его строки читает система: заголовок
в галерее (`configurationDisplayName`), описание и подписи `AppIntents` берутся
из бандла расширения до того, как появится наш код, а `LocalizedStringResource`
требует литерала. Ключом там стоит английский текст, и генератор про виджет
каждый раз напоминает строкой «ещё не переехали» — это норма, а не долг.

Строка, которую видно на экране, зовётся из тела свойства, а не сохраняется
в поле: `static let` со строкой запоминает язык, который стоял при первом
обращении. Поэтому каталог инструментов, список страниц тура и настройки
шагов флоу объявлены через `static var`.

Грабли, на которые уже наступили:

- `String(format:)` без `locale` выбирает форму слова по правилам английского:
  русское «5 файлов» превращается в «5 файла». В `tr` локаль передаётся
  всегда — поэтому руками `String(format:)` над переводом не зовут.
- Литеральный `%` рядом с числом ломает шаблон: собери долю отдельной
  строкой и подставь её как `%@`.
- `L10n` (как и `Bundle.module` под ним) — `internal`, поэтому значением
  по умолчанию у публичного параметра он быть не может: принимай `String?`
  и подставляй строку в теле.
- Форма слова выбирается каталогом, а не таблицей в коде. Слово без числа
  (крупная цифра + мелкая подпись) — это `substitutions` с явным
  `formatSpecifier`: без числа внутри значений `xcstringstool` не соберёт
  каталог.
- Ключ, которого нет в коде литералом, Xcode считает устаревшим. У переехавших
  строк стоит `extractionState: manual` — без него он их вычистит.

Info.plist и меню иконки переводит `App/Resources/InfoPlist.xcstrings`.
Подписи быстрых действий в `Tuist/ProjectDescriptionHelpers/QuickActions.swift`
— это английский текст и одновременно ключ.

Новая папка `Resources/` подхватывается только после `tuist install` и
`tuist generate`: без этого `Bundle.module` у модуля не появится.

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

- Комментарии и документация — **на русском**. Идентификаторы и ключи
  строковых каталогов — английские (см. «Локализация»).
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
