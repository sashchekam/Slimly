import SwiftUI

/// Сетка знака: квадраты 30×30 в поле 100×100, центры разведены на 21
/// от середины, всё вместе повёрнуто на 45°.
///
/// Одна на всех: статичный знак, анимацию сплэша и два растра —
/// иконку (`Tools/GenerateAppIcon.swift`) и первый кадр заставки на экране
/// запуска (`Tools/GenerateLaunchMark.swift`). Правишь сетку — перерисовывай
/// оба: разъехавшиеся пропорции видно сразу, потому что иконка, экран запуска
/// и заставка идут друг за другом при старте.
enum SlimlyMarkGrid {
    static let box: CGFloat = 100
    static let cell: CGFloat = 30
    static let corner: CGFloat = 8
    static let offset: CGFloat = 21
    /// Толщина контура в единицах сетки.
    static let stroke: CGFloat = 5.5

    /// Залитый квадрат в анимации крупнее обведённых: он занимает их внешние
    /// габариты (30 + 5.5 контура), иначе на ходу пятно «худеет» рядом
    /// с контурами, мимо которых летит.
    static let accentCell: CGFloat = 36
    static let accentCorner: CGFloat = 10

    /// Углы обхода в координатах сетки. После поворота на 45° это, по экрану,
    /// низ → лево → верх → право — то есть против часовой стрелки.
    static let corners: [CGPoint] = [
        CGPoint(x: offset, y: offset),
        CGPoint(x: -offset, y: offset),
        CGPoint(x: -offset, y: -offset),
        CGPoint(x: offset, y: -offset),
    ]

    /// Контур, который в покое горит белым, — верхний на экране.
    static let litCorner = 2

    /// Толщина контура на экране. Пропорция макета — 5.5 % стороны, но тоньше
    /// ~2.8 pt контур на тёмном фоне перестаёт читаться, поэтому подпёрт снизу.
    static func lineWidth(for size: CGFloat) -> CGFloat {
        max(size * stroke / box, 2.8)
    }
}

/// Знак Slimly: четыре квадрата ромбом — по одному на инструмент хаба.
///
/// Три обведены контуром, четвёртый залит акцентом. Заливка здесь —
/// исключение из правила «акцент не заливает площади»: на иконке в 40 pt
/// контуры сливаются, и узнать приложение можно только по цветному пятну.
///
/// `size` — сторона макетной сетки, как атрибут `width` у исходного SVG.
/// Повёрнутый знак выходит за неё примерно на 10 % с каждой стороны,
/// поэтому в тесной раскладке ему нужен запас.
public struct SlimlyLogoMark: View {
    private let size: CGFloat

    public init(size: CGFloat) {
        self.size = size
    }

    public var body: some View {
        let scale = size / SlimlyMarkGrid.box
        let shape = RoundedRectangle(cornerRadius: SlimlyMarkGrid.corner * scale)
        let side = SlimlyMarkGrid.cell * scale
        let line = SlimlyMarkGrid.lineWidth(for: size)

        ZStack {
            ForEach(SlimlyMarkGrid.corners.indices, id: \.self) { index in
                let point = SlimlyMarkGrid.corners[index]

                if index == 0 {
                    shape.fill(SlimlyColor.accent)
                        .frame(width: side, height: side)
                        .offset(x: point.x * scale, y: point.y * scale)
                } else {
                    shape.stroke(
                        index == SlimlyMarkGrid.litCorner ? SlimlyColor.text : SlimlyColor.markMuted,
                        lineWidth: line
                    )
                    .frame(width: side, height: side)
                    .offset(x: point.x * scale, y: point.y * scale)
                }
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(45))
    }
}
