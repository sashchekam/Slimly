---
name: design-system
description: Работа с дизайн-системой Slimly — токены цветов, отступов, радиусов, шрифтов и компоненты вроде SlimlyButtonStyle. Использовать при вёрстке любого экрана, добавлении переиспользуемого компонента или при появлении в коде «магических» цветов, размеров и системных шрифтов.
---

# Дизайн-система

`Modules/Core/SlimlyDesignSystem`. Правило простое: в коде экранов **не должно быть**
литеральных цветов, отступов, радиусов и системных шрифтов — только токены.

## Токены

```swift
SlimlyColor.accent / .accentSoft / .background / .surface / .textPrimary / .textSecondary
SlimlySpacing.xs(4) / .s(8) / .m(16) / .l(24) / .xl(32)
SlimlyRadius.button(16) / .card(20)
Font.slimlyTitle / .slimlySubtitle / .slimlyButton
```

## Компоненты

```swift
Button("Войти") { … }.buttonStyle(.slimlyPrimary)
Button("Настройки") { … }.buttonStyle(.slimlySecondary)
```

## Типовой экран

```swift
VStack(spacing: SlimlySpacing.l) { … }
    .padding(SlimlySpacing.l)
    .background(SlimlyColor.background)
```

Карточка: `.padding(SlimlySpacing.m)`, `.background(SlimlyColor.surface)`,
`.clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.card, style: .continuous))`.

## Добавление токена или компонента

1. Токен — в `Sources/Tokens/Tokens.swift`, рядом с однотипными.
   Новая шкала заводится, только если её нельзя выразить существующей.
2. Компонент — отдельный файл в `Sources/Components/`, `public`, с `#Preview`.
   Компонент не знает ни про навигацию, ни про модели: на вход — данные и колбэки.
3. `tuist generate --no-open` после добавления файла.

## Чего не делать

- Не импортировать `SlimlyDesignSystem` в `SlimlyCore` — зависимость идёт наоборот.
- Не тащить в дизайн-систему `Router`, `AuthService` и доменные модели.
- Не хардкодить `Color(red:green:blue:)`, `.font(.system(size:))` и числовые отступы
  в экранах — заводи токен.
