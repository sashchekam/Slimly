import SwiftUI

/// Фон экрана: ровная тёмная основа и мягкое пятно от левого верхнего угла.
/// Плоская заливка выглядела бы мертво, а градиент даёт глубину, не поднимая
/// насыщенность.
///
/// Пятно задано в точках окна, а не в долях своего кадра: так тот же фон
/// повторяет отдельный кусок интерфейса, зная лишь свою позицию на экране, —
/// например, прилипшая шапка списка.
struct SlimlyScreenGlow: View {
    /// Левый верхний угол вида в координатах окна.
    var origin: CGPoint = .zero

    /// Центр пятна и размер его эллипса — у левого края под вырезом, размах
    /// примерно в полтора экрана: свет должен гаснуть к середине списка.
    private static let center = CGPoint(x: 31, y: 0)
    private static let size = CGSize(width: 629, height: 1363)

    var body: some View {
        SlimlyColor.background
            .overlay {
                EllipticalGradient(
                    stops: [
                        .init(color: SlimlyColor.backgroundGlow, location: 0),
                        .init(color: SlimlyColor.backgroundGlow.opacity(0), location: 0.62),
                    ]
                )
                .frame(width: Self.size.width, height: Self.size.height)
                .position(x: Self.center.x - origin.x, y: Self.center.y - origin.y)
            }
            .clipped()
    }
}

/// Фон целого экрана — то же пятно, отсчитанное от угла окна.
public struct SlimlyScreenBackground: View {
    public init() {}

    public var body: some View {
        SlimlyScreenGlow()
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
    /// Подложка прилипшей шапки списка: тот же экранный фон, сдвинутый под её
    /// место в окне. Плоская заливка выделялась бы пятном поверх свечения.
    ///
    /// Ниже края — растушёвка: плитки уезжают под шапку и гаснут, а не
    /// обрезаются о её край.
    func slimlyStickyBackground(fade: CGFloat = 10) -> some View {
        background {
            GeometryReader { proxy in
                let frame = proxy.frame(in: .global)

                SlimlyScreenGlow(origin: frame.origin)
                    .frame(height: frame.height + fade)
                    .mask(alignment: .top) {
                        VStack(spacing: 0) {
                            Color.black

                            LinearGradient(
                                colors: [.black, .black.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: fade)
                        }
                    }
            }
            // Подложка вылезает на растушёвку ниже шапки и там накрывает
            // содержимое списка: без запрета она съедала бы нажатия по нему.
            .allowsHitTesting(false)
        }
    }

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
