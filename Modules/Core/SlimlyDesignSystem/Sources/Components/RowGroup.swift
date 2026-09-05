import SwiftUI

/// Сгруппированный список: строки на `surface`, между ними просвет в 1 пункт,
/// сквозь который виден полупрозрачный фон группы. Так разделители получаются
/// сплошными внутри контрола — фаска гаснущих линеек к ним не применяется.
public struct SlimlyRowGroup<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 1) { content }
            .background(SlimlyColor.text.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous))
            .slimlyElevation(.sm)
    }
}

public extension View {
    /// Заливка строки внутри ``SlimlyRowGroup``.
    ///
    /// - Parameter fill: цвет самой строки. Меняют его там, где строка ещё и
    ///   выбрана, — тогда она уходит на ступень глубже поверхности, а не
    ///   красится акцентом: в списке из десяти строк акцентная заливка
    ///   перевесила бы сам список.
    func slimlyRow(
        horizontal: CGFloat = 13,
        vertical: CGFloat = 12,
        fill: Color = SlimlyColor.surface
    ) -> some View {
        padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill)
    }
}
