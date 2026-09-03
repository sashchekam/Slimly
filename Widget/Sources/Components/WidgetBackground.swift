import SlimlyDesignSystem
import SwiftUI

/// Фон виджета: тёмная основа Nocturne и мягкое пятно от левого верхнего угла —
/// та же глубина, что у экранов приложения.
///
/// Экранный `SlimlyScreenBackground` сюда не годится: его пятно рассчитано
/// на высоту телефона и в плитке виджета выродилось бы в ровную заливку.
struct WidgetBackground: View {
    /// Размах свечения — примерно диагональ большого виджета: свет должен
    /// гаснуть, не доходя до правого нижнего угла.
    private static let glowRadius: CGFloat = 240

    var body: some View {
        SlimlyColor.background
            .overlay {
                RadialGradient(
                    colors: [SlimlyColor.backgroundGlow, SlimlyColor.backgroundGlow.opacity(0)],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: Self.glowRadius
                )
            }
    }
}
