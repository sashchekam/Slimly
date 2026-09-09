import SwiftUI

/// Чип выбора: формат результата, короткий фильтр.
public struct SlimlyChip: View {
    /// На чём лежит чип. Внутри карточки невыбранный чип не заливается:
    /// заливка совпала бы с поверхностью под ним и ряд превратился бы в кашу.
    public enum Style: Sendable {
        case standalone
        case onSurface
    }

    private let title: String
    private let isSelected: Bool
    private let style: Style
    private let fillsWidth: Bool

    /// `fillsWidth` — для ряда, который делит ширину поровну: переключатель
    /// среза времени. Без него чип сжимается по надписи, и «30 дней»
    /// оказывается уже «Всё время».
    public init(
        _ title: String,
        isSelected: Bool,
        style: Style = .standalone,
        fillsWidth: Bool = false
    ) {
        self.title = title
        self.isSelected = isSelected
        self.style = style
        self.fillsWidth = fillsWidth
    }

    public var body: some View {
        Text(title)
            .font(.system(size: style == .standalone ? 13 : 12, weight: .medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, style == .standalone ? 15 : 12)
            .padding(.vertical, style == .standalone ? 10 : 8)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .background(background, in: shape)
            .overlay { shape.strokeBorder(border, lineWidth: 1) }
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: SlimlyRadius.md, style: .continuous)
    }

    private var foreground: Color {
        if isSelected { return SlimlyColor.accent200 }
        return style == .standalone ? SlimlyColor.neutral300 : SlimlyColor.neutral400
    }

    private var background: Color {
        if isSelected { return SlimlyColor.accentTint(14) }
        return style == .standalone ? SlimlyColor.surface : .clear
    }

    private var border: Color {
        if isSelected { return SlimlyColor.accent }
        return SlimlyColor.text.opacity(style == .standalone ? 0.1 : 0.12)
    }
}

/// Переключатель на два-три положения внутри пилюли: «Оригинал / Сжатое».
public struct SlimlySegmentedControl: View {
    public struct Option: Identifiable, Sendable {
        public let id: String
        public let title: String

        public init(id: String, title: String) {
            self.id = id
            self.title = title
        }
    }

    private let options: [Option]
    @Binding
    private var selection: String

    /// Выделение — одна пилюля, переезжающая между положениями, а не две
    /// разные, гаснущие и загорающиеся: переезд показывает, что положение
    /// сменилось, а не что экран перерисовали.
    @Namespace
    private var highlight

    public init(options: [Option], selection: Binding<String>) {
        self.options = options
        _selection = selection
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { option in
                let isSelected = option.id == selection

                Button {
                    selection = option.id
                } label: {
                    Text(option.title)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(isSelected ? SlimlyColor.accent200 : SlimlyColor.neutral400)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        // Мерка для пилюли: сама она лежит слоем ниже кнопок,
                        // иначе на переезде перехватывала бы нажатия соседа.
                        .matchedGeometryEffect(id: option.id, in: highlight)
                        // Прямоугольник, а не капсула: у скруглённых торцов
                        // углы сегмента выпадали бы из зоны нажатия.
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .background {
            Capsule()
                .fill(SlimlyColor.accentTint(18))
                .matchedGeometryEffect(id: selection, in: highlight, isSource: false)
        }
        .padding(4)
        .background(SlimlyColor.text.opacity(0.07), in: Capsule())
        // Пружина без раскачки: пилюля догоняет палец, но не проскакивает
        // мимо края переключателя.
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selection)
    }
}

/// Счётчик выбранного с полосой заполнения: «2 из 5».
///
/// Лимит видно всё время, а не только при попытке его превысить: иначе
/// пользователь узнаёт о нём в момент отказа, что читается как ошибка.
public struct SlimlyLimitPill<Trailing: View>: View {
    private let title: String
    private let fraction: Double
    private let isAtLimit: Bool
    private let trailing: Trailing

    /// - Parameter trailing: что стоит за полосой — например, предложение
    ///   тарифа, который этот предел снимает. Слот пустует, когда предлагать
    ///   нечего, и пилюля остаётся одним счётчиком.
    public init(
        title: String,
        fraction: Double,
        isAtLimit: Bool,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.fraction = fraction
        self.isAtLimit = isAtLimit
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 11) {
            // Счётчик и полоса — одно показание, и озвучиваются вместе.
            // Объединять с ними то, что стоит в слоте, нельзя: кнопку внутри
            // склеенного элемента VoiceOver уже не нажмёт.
            HStack(spacing: 11) {
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(isAtLimit ? SlimlyColor.accent200 : SlimlyColor.neutral300)

                SlimlyProgressBar(
                    value: fraction,
                    height: 4,
                    fill: isAtLimit ? .solid : .gradient
                )
                // Шаг лимита крупный — пятая или третья часть полосы, — поэтому
                // заполнение догоняет выбор упруго: мгновенный скачок читается
                // как подмена картинки, а не как реакция на нажатие.
                .animation(.spring(response: 0.32, dampingFraction: 0.8), value: fraction)
            }
            .accessibilityElement(children: .combine)

            trailing
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(SlimlyColor.surfaceSunken.opacity(0.9), in: Capsule())
        .overlay {
            Capsule().strokeBorder(
                isAtLimit ? SlimlyColor.accent600 : SlimlyColor.text.opacity(0.1),
                lineWidth: 1
            )
            // Кромка загорается отдельно от счётчика: под общей анимацией
            // цифра «4 из 5» перекрёстно растворялась бы в «5 из 5».
            .animation(.easeOut(duration: 0.2), value: isAtLimit)
        }
    }
}

public extension SlimlyLimitPill where Trailing == EmptyView {
    init(title: String, fraction: Double, isAtLimit: Bool) {
        self.init(title: title, fraction: fraction, isAtLimit: isAtLimit) { EmptyView() }
    }
}

/// Ползунок степени сжатия с засечками на пресетах.
///
/// Значение непрерывное: пресеты — подписи шкалы, а не три кнопки, поэтому
/// ползунок не «прилипает» к засечкам, но по тапу на подпись встаёт на неё.
public struct SlimlyLevelSlider: View {
    @Binding
    private var value: Double
    private let stops: Int

    /// Половина кноба: на неё шкала отступает от краёв, эти же отступы берут
    /// подписи, чтобы стоять ровно над крайними положениями кноба.
    public static let edgeInset: CGFloat = 13

    private let trackHeight: CGFloat = 5
    private var thumbSize: CGFloat { Self.edgeInset * 2 }

    public init(value: Binding<Double>, stops: Int) {
        _value = value
        self.stops = stops
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let clamped = min(max(value, 0), 1)
            // Центр кноба ходит по отрезку [edgeInset, width - edgeInset]:
            // иначе на краях половина круга выезжает за границы и обрезается.
            let travel = max(width - thumbSize, 0)
            let center = Self.edgeInset + travel * clamped

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(SlimlyColor.neutral900)
                    .frame(height: trackHeight)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [SlimlyColor.accent500, SlimlyColor.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: center, height: trackHeight)

                ForEach(0 ..< stops, id: \.self) { index in
                    let position = Double(index) / Double(max(stops - 1, 1))

                    Circle()
                        .fill(position <= clamped ? SlimlyColor.onAccent.opacity(0.6) : SlimlyColor.neutral700)
                        .frame(width: 5, height: 5)
                        .offset(x: Self.edgeInset + travel * position - 2.5)
                }

                Circle()
                    .fill(SlimlyColor.neutral100)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.55), radius: 4, y: 2)
                    .offset(x: center - thumbSize / 2)
            }
            .frame(height: thumbSize, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        guard travel > 0 else { return }
                        value = min(max((drag.location.x - Self.edgeInset) / travel, 0), 1)
                    }
            )
        }
        .frame(height: thumbSize)
        .accessibilityElement()
        .accessibilityLabel(Text(L10n.Accessibility.compressionLevel))
        .accessibilityValue(Text(verbatim: "\(Int((value * 100).rounded()))%"))
        .accessibilityAdjustableAction { direction in
            let step = 1.0 / Double(max(stops - 1, 1))
            switch direction {
            case .increment: value = min(value + step, 1)
            case .decrement: value = max(value - step, 0)
            default: break
            }
        }
    }
}
