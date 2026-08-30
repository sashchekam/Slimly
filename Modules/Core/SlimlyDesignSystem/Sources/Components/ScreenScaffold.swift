import SwiftUI

/// Фон экрана: ровная тёмная основа и мягкое пятно от левого верхнего угла.
/// Плоская заливка выглядела бы мертво, а градиент даёт глубину, не поднимая
/// насыщенность.
public struct SlimlyScreenBackground: View {
    public init() {}

    public var body: some View {
        EllipticalGradient(
            stops: [
                .init(color: SlimlyColor.backgroundGlow, location: 0),
                .init(color: SlimlyColor.background, location: 0.62),
            ],
            center: UnitPoint(x: 0.08, y: 0),
            endRadiusFraction: 0.8
        )
        .background(SlimlyColor.background)
        .ignoresSafeArea()
    }
}

/// Главное действие, приклеенное к низу экрана.
///
/// Над кнопкой — растушёвка в цвет фона: контент, уезжающий под панель,
/// гаснет вместо того, чтобы обрезаться по краю. Под самой кнопкой фон
/// уже сплошной, иначе сквозь неё просвечивает список.
public struct SlimlyBottomAction<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [SlimlyColor.background.opacity(0), SlimlyColor.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)

            content
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 10)
                .background(SlimlyColor.background)
        }
    }
}

public extension View {
    /// Общая обвязка экрана: фон, поля и спрятанная системная навигационная
    /// панель — макет рисует заголовки и «Назад» сам.
    func slimlyScreen() -> some View {
        scrollIndicators(.hidden)
            // Скролл рисует содержимое и за своими границами: без обрезки
            // хвост списка проступает под статус-баром поверх шапки.
            .clipped()
            .background(SlimlyScreenBackground())
            .toolbar(.hidden, for: .navigationBar)
            // Скрытая панель уносит с собой системный свайп-назад — возвращаем.
            .interactivePopGestureEnabled()
            .foregroundStyle(SlimlyColor.text)
    }
}
