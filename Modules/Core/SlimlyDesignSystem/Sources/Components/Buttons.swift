import SwiftUI

/// Кнопка Nocturne: акцентный контур на прозрачном, никогда не сплошная заливка.
/// Акцент здесь работает линией, а нажатие проявляется усилением тинта.
public struct SlimlyOutlineButtonStyle: ButtonStyle {
    /// Главное действие экрана держит слабый тинт даже в покое — так оно
    /// отличается от вторичного контура, не превращаясь в заливку.
    public enum Emphasis: Sendable { case tinted, plain }
    public enum Size: Sendable { case regular, compact }

    private let emphasis: Emphasis
    private let size: Size

    public init(emphasis: Emphasis = .tinted, size: Size = .regular) {
        self.emphasis = emphasis
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size == .regular ? .slimlyButton : .slimlyButtonSmall)
            .foregroundStyle(SlimlyColor.accent200)
            .padding(.vertical, size == .regular ? 14 : 8)
            .padding(.horizontal, size == .regular ? SlimlySpacing.x4 : 13)
            .frame(maxWidth: size == .regular ? .infinity : nil)
            .background(tint(pressed: configuration.isPressed), in: shape)
            .overlay(shape.strokeBorder(SlimlyColor.accent, lineWidth: 1))
            // Без своей формы кнопка без заливки ловит нажатие только по тексту
            // и линии рамки — прозрачная середина и отступы проваливались бы
            // мимо, а в скролле промах ещё и уходит в жест прокрутки.
            .contentShape(shape)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: SlimlyRadius.md, style: .continuous)
    }

    private func tint(pressed: Bool) -> Color {
        switch (emphasis, pressed) {
        case (.tinted, false): SlimlyColor.accentTint(12)
        case (.tinted, true): SlimlyColor.accentTint(22)
        case (.plain, false): .clear
        case (.plain, true): SlimlyColor.accentTint(14)
        }
    }
}

public extension ButtonStyle where Self == SlimlyOutlineButtonStyle {
    /// Главное действие экрана — контур с лёгким тинтом.
    static var slimlyPrimary: SlimlyOutlineButtonStyle { SlimlyOutlineButtonStyle(emphasis: .tinted) }
    /// Тот же контур, но без заливки: «Готово» на экране результата.
    static var slimlyOutline: SlimlyOutlineButtonStyle { SlimlyOutlineButtonStyle(emphasis: .plain) }
    /// Компактный контур в строке — кнопка «Открыть» у блока Pro.
    static var slimlyCompact: SlimlyOutlineButtonStyle {
        SlimlyOutlineButtonStyle(emphasis: .plain, size: .compact)
    }
}

/// Текстовое действие без рамки: «Отменить», «Смотреть в профиле», «Вся галерея».
public struct SlimlyLinkButtonStyle: ButtonStyle {
    private let color: Color
    private let font: Font

    public init(color: Color = SlimlyColor.accent300, font: Font = .slimlyBody) {
        self.color = color
        self.font = font
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(color)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == SlimlyLinkButtonStyle {
    static var slimlyLink: SlimlyLinkButtonStyle { SlimlyLinkButtonStyle() }

    static var slimlyQuietLink: SlimlyLinkButtonStyle {
        SlimlyLinkButtonStyle(color: SlimlyColor.neutral400, font: .slimlyBody)
    }
}

public struct SlimlyPressableStyle: ButtonStyle {
    private let scale: CGFloat

    public init(scale: CGFloat = 0.95) {
        self.scale = scale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: configuration.isPressed) { _, pressed in
                pressed
            }
    }
}

public extension ButtonStyle where Self == SlimlyPressableStyle {
    /// Плитка на главной и прочие крупные тапабельные поверхности.
    static var slimlyPressable: SlimlyPressableStyle { SlimlyPressableStyle() }
}
