import SlimlyDesignSystem
import SwiftUI

/// Лист бумаги в иллюстрациях тура: конвертированный кадр и страница скана.
///
/// Единственная светлая поверхность во всей системе, поэтому она не белая:
/// свет идёт сверху вниз с лёгким сносом вправо, иначе прямоугольник
/// выглядит вырезанной дырой в тёмном экране.
struct PaperSurface: View {
    var body: some View {
        LinearGradient(
            colors: [SlimlyColor.paperLight, SlimlyColor.paperDark],
            startPoint: UnitPoint(x: 0.3, y: 0),
            endPoint: UnitPoint(x: 0.7, y: 1)
        )
    }
}
