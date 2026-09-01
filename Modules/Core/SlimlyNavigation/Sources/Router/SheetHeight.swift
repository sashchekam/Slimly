import SwiftUI

/// Высота, которую экран просит у шторки, показавшей его.
///
/// Задать `presentationDetents` прямо на экране нельзя: он лежит внутри
/// `NavigationStack` слоя, а оттуда presentation-модификаторы до шита не
/// доходят. Поэтому высота поднимается к хосту предпочтением, и хост
/// применяет её уже снаружи стека.
struct SheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

public extension View {
    /// Показать этот экран шторкой заданной высоты.
    ///
    /// Число живёт рядом с вёрсткой экрана: высота — это его свойство,
    /// а не знание того, кто его открывает.
    func sheetHeight(_ height: CGFloat) -> some View {
        preference(key: SheetHeightKey.self, value: height)
    }
}
