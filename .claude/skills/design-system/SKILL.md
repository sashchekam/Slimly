---
name: design-system
description: Работа с дизайн-системой Slimly (Nocturne) — токены цветов, отступов, радиусов, шрифтов и компоненты вроде SlimlyCard, SlimlyRowGroup, SlimlyNavigationBar. Использовать при вёрстке любого экрана, добавлении переиспользуемого компонента или при появлении в коде «магических» цветов, размеров и системных шрифтов.
---

# Дизайн-система (Nocturne)

`Modules/Core/SlimlyDesignSystem`. В коде экранов **не должно быть** литеральных
цветов, радиусов и полей экрана — только токены. Мелкие числа вёрстки внутри
одного компонента (`spacing: 10`, `padding(.top, 13)`) допустимы: они взяты
из макета и шкалой не выражаются.

Система тёмная, светлого варианта нет. Акцент — блюрпл `#9184D9`: им красят
линии, метки и цифры, но **не заливают площади**; заливка всегда разбавлена
основой через `SlimlyColor.accentTint(_:)`.

## Токены

`Sources/Tokens/`: `Colors.swift`, `Metrics.swift`, `Typography.swift`.

```swift
// Роли
SlimlyColor.background / .backgroundGlow / .surface / .surfaceSunken / .text
SlimlyColor.accent / .divider / .onAccent / .sheet / .menu / .scrim / .chrome
// Рампы 100…900 — шаг светлоты общий у обеих
SlimlyColor.neutral100 … .neutral900
SlimlyColor.accent100  … .accent900
// Полупрозрачная заливка акцентом: 9…22% в макете
SlimlyColor.accentTint(12)

SlimlySpacing.x1(2.8) .x2 .x3 .x4 .x6 .x8   // плотность 0.7× уже в числах
SlimlySpacing.screenHorizontal              // 20 — поля экрана
SlimlyRadius.sm(4) .md(8) .lg(14) .tile(10) .thumbnail(8) .pill(999)
SlimlySize.progressRing / .progressRingWidth / .toggleWidth / .toggleHeight

Font.slimlyLargeTitle / .slimlyTitle                       // заголовки экранов
Font.slimlyStatXL / .slimlyStatL / .slimlyStatM / .slimlyStatS / .slimlyStatRing
Font.slimlySectionTitle / .slimlyRowTitle / .slimlyBody / .slimlyBodySmall
Font.slimlyCaption / .slimlyCaptionSmall / .slimlyMicro / .slimlyNano
Font.slimlyButton / .slimlyButtonSmall / .slimlyPill
SlimlyTracking.largeTitle / .title / .statXL / .statL / .statM / .statS / .kicker
```

Крупный текст всегда идёт с трекингом: `.font(.slimlyTitle).tracking(SlimlyTracking.title)`.
Надпись-кикер над блоком («ГОТОВО», «В МЕДИАТЕКЕ») — модификатор `.slimlyKicker()`,
он сам ставит размер, разрядку, капс и цвет.

## Компоненты

`Sources/Components/`:

| Что | Как |
| --- | --- |
| Обвязка экрана | `.slimlyScreen()` — фон, скрытая системная панель, обрезка |
| Шапка | `SlimlyNavigationBar(backTitle:onBack:trailing:)`, `SlimlyCircleButton` |
| Кнопка внизу | `SlimlyBottomAction { Button(…).buttonStyle(.slimlyPrimary) } ` |
| Кнопки | `.slimlyPrimary` / `.slimlyOutline` / `.slimlyCompact` / `.slimlyLink` / `.slimlyQuietLink` |
| Карточка | `SlimlyCard(padding:) { … }` |
| Список строк | `SlimlyRowGroup { … }` + `.slimlyRow(horizontal:vertical:)` на каждой строке |
| Прогресс | `SlimlyProgressBar(value:height:fill:)`, `SlimlyProgressRing(value:) { label }` |
| Линейки | `SlimlyFadingRule()`, `SlimlyColumnDivider()` |
| Мелочь | `SlimlyDeltaBadge("−58%")`, `SlimlyChip(_:isSelected:)`, `SlimlyLimitPill` |
| Контролы | `SlimlySegmentedControl`, `SlimlyLevelSlider`, `Toggle(…).toggleStyle(.slimly)` |
| Шторка | `SlimlySheetScaffold(title:height:onCancel:) { … }` |
| Раскладка | `SlimlyWrap { … }` — строка чипов с переносом |
| Заглушки | `SlimlyStripes.tile` / `.thumbnail` вместо превью файла |
| Высота | `.slimlyElevation(.sm)` — кромка, а не тень |
| Иконки | `SlimlyIcon(.compress, width: 24)` |
| Знак | `SlimlyLogoMark(size: 84)` — ромб из четырёх, он же в иконке |
| Знак в движении | `SlimlyLogoMarkAnimation(size:onLanding:onFinish:)` — один круг акцента для заставки |

Иконки: `compress`, `photoConvert`, `videoConvert`, `scan`, `audio`, `camera`,
`gallery`, `folder`, `check`, `chevronLeft/Right/Down`, `arrowRight`, `eye`,
`trash`, `person`. Новая рисуется путями в `SlimlyIcon.swift` (viewBox из макета,
скруглённые углы — через `Path.corner(via:to:radius:)`), а не подменяется
SF Symbol'ом: у системных символов другой оптический вес.

## Каркас экрана

Шапка — **сосед** скролла, а не `safeAreaInset(edge: .top)`: иначе содержимое
уезжает под неё и проступает у статус-бара.

```swift
var body: some View {
    VStack(spacing: 0) {
        SlimlyNavigationBar(backTitle: "Инструменты") { viewModel.goBack() }

        ScrollView {
            VStack(alignment: .leading, spacing: 15) { … }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 6)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SlimlyBottomAction {
                Button(viewModel.ctaTitle) { viewModel.proceed() }
                    .buttonStyle(.slimlyPrimary)
            }
        }
    }
    .slimlyScreen()
    .task { await viewModel.load() }
}
```

Экран без возврата (обработка, итог) всё равно ставит пустой
`SlimlyNavigationBar()` — иначе контент прижимается к вырезу.

## Добавление токена или компонента

1. Токен — в `Colors.swift` / `Metrics.swift` / `Typography.swift`, рядом
   с однотипными. Новая шкала заводится, только если её нельзя выразить
   существующей.
2. Компонент — отдельный файл в `Sources/Components/`, `public`. На вход —
   данные и колбэки; ни `Router`, ни доменных моделей внутри.
3. `tuist generate --no-open` после добавления файла.

## Проверка вёрстки

`#Preview` в проекте не используются — экран смотрят в симуляторе, а дойти
до него быстрее всего диплинком:

```bash
xcodebuild -workspace Slimly.xcworkspace -scheme Slimly \
  -destination 'id=<UDID>' -derivedDataPath /tmp/dd build
xcrun simctl install booted /tmp/dd/Build/Products/Debug-iphonesimulator/Slimly.app
xcrun simctl launch booted com.slimly
xcrun simctl openurl booted "slimly://compress"
xcrun simctl io booted screenshot /tmp/shot.png
```

Скриншот делай через пару секунд после `openurl`: снимок в момент перехода
ловит промежуточный кадр и врёт.

## Чего не делать

- Не импортировать `SlimlyDesignSystem` в `SlimlyCore` — зависимость идёт наоборот.
- Не тащить в дизайн-систему `Router` и доменные модели: компонент, которому
  нужен `MediaItem`, живёт в `SlimlyMediaFlow`, а не здесь.
- Не хардкодить `Color(red:green:blue:)` и цвета макета в экранах — заводи токен.
- Не заливать акцентом площади и не вешать мягкие тени: высота в Nocturne —
  это кромка (`slimlyElevation`), а не свечение.
