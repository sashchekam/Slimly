import CoreGraphics
import Foundation

/// Как обрабатываем страницу перед сборкой в PDF.
///
/// Это не «фильтр для красоты»: от режима зависит читаемость текста.
/// Скан договора и скан чека с печатью — разные задачи, и одним режимом
/// их не закрыть.
public enum ScanMode: String, Sendable, Hashable, CaseIterable, Identifiable {
    /// Цвет сохраняем — нужен печатям, подписям и иллюстрациям.
    case color
    /// Оттенки серого: текст читается так же, а лишний цвет не отвлекает.
    case grayscale
    /// Чистая двухцветная страница — самый контрастный вариант.
    case blackAndWhite

    public var id: String { rawValue }

    /// Подпись в списке форматов. Короткая: «PDF» повторяется во всех трёх
    /// вариантах, и длинные хвосты превратили бы выбор в стену текста.
    public var displayName: String {
        switch self {
        case .color: "цвет"
        case .grayscale: "серый"
        case .blackAndWhite: "ч/б"
        }
    }
}

// MARK: - Границы листа

/// Границы листа в кадре.
///
/// Координаты — доли кадра с началом в левом верхнем углу. Vision считает
/// от нижнего, но рамку рисует SwiftUI, и переворачивать ось один раз на
/// границе с системой дешевле, чем помнить про неё в каждом месте отрисовки.
public struct DocumentQuad: Sendable, Hashable {
    /// Угол четырёхугольника. По часовой стрелке — в том же порядке, в каком
    /// углы перечислены в ``corners``: индекс здесь и там один и тот же.
    public enum Corner: Int, Sendable, Hashable, CaseIterable, Identifiable {
        case topLeft
        case topRight
        case bottomRight
        case bottomLeft

        public var id: Int { rawValue }
    }

    public let topLeft: CGPoint
    public let topRight: CGPoint
    public let bottomRight: CGPoint
    public let bottomLeft: CGPoint

    public init(topLeft: CGPoint, topRight: CGPoint, bottomRight: CGPoint, bottomLeft: CGPoint) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }

    /// Углы по часовой стрелке — в том порядке, в каком их обходит рамка.
    public var corners: [CGPoint] {
        [topLeft, topRight, bottomRight, bottomLeft]
    }

    public subscript(corner: Corner) -> CGPoint {
        corners[corner.rawValue]
    }

    /// Кадр целиком — то же, что «не обрезать».
    public static let full = DocumentQuad(
        topLeft: CGPoint(x: 0, y: 0),
        topRight: CGPoint(x: 1, y: 0),
        bottomRight: CGPoint(x: 1, y: 1),
        bottomLeft: CGPoint(x: 0, y: 1)
    )

    /// Насколько углы разъехались с прошлым кадром — в долях кадра.
    ///
    /// По этому числу решается, что лист лежит спокойно: сравнивать площади
    /// бесполезно, потому что при повороте вокруг центра она не меняется.
    public func drift(from previous: DocumentQuad) -> CGFloat {
        zip(corners, previous.corners).reduce(0) { largest, pair in
            max(largest, hypot(pair.0.x - pair.1.x, pair.0.y - pair.1.y))
        }
    }

    // MARK: Правка вручную

    /// Наименьшая доля кадра, которую ещё имеет смысл считать страницей.
    /// Меньше — это уже не рамка, а схлопнутый в точку четырёхугольник,
    /// из которого не выйдет ни превью, ни страницы PDF.
    private static let minimumArea: CGFloat = 0.02

    /// Тот же четырёхугольник с одним переставленным углом.
    ///
    /// `nil` — угол занесли за соседние стороны: рамка сложилась бы бантиком,
    /// и выпрямлять по ней было бы нечего. Отказ вместо подгонки намеренный:
    /// палец продолжает вести, а рамка просто перестаёт следовать за ним —
    /// это понятнее, чем угол, живущий своей жизнью.
    public func moving(_ corner: Corner, to point: CGPoint) -> DocumentQuad? {
        var points = corners
        points[corner.rawValue] = CGPoint(
            x: min(max(point.x, 0), 1),
            y: min(max(point.y, 0), 1)
        )

        let moved = DocumentQuad(
            topLeft: points[0],
            topRight: points[1],
            bottomRight: points[2],
            bottomLeft: points[3]
        )
        return moved.isUsable ? moved : nil
    }

    /// Выпуклый и не выродившийся в полоску: только по такой рамке можно
    /// выпрямить перспективу.
    public var isUsable: Bool {
        isConvex && area >= Self.minimumArea
    }

    /// Площадь по формуле шнурования — в долях кадра.
    private var area: CGFloat {
        let points = corners
        let doubled = points.indices.reduce(CGFloat.zero) { sum, index in
            let current = points[index]
            let next = points[(index + 1) % points.count]
            return sum + current.x * next.y - next.x * current.y
        }
        return abs(doubled) / 2
    }

    /// Все повороты обхода в одну сторону — значит, стороны не пересекаются.
    private var isConvex: Bool {
        let points = corners
        var sign: CGFloat = 0

        for index in points.indices {
            let a = points[index]
            let b = points[(index + 1) % points.count]
            let c = points[(index + 2) % points.count]
            let cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x)
            guard abs(cross) > .ulpOfOne else { return false }
            if sign == 0 {
                sign = cross
            } else if cross * sign < 0 {
                return false
            }
        }
        return true
    }
}

/// Границы страниц, с которыми собирается документ.
///
/// Ключ — идентификатор страницы: задание на обработку носит с собой список
/// страниц, а границы к нему прилагаются отдельно. Чего в таблице нет, то
/// обработка ищет сама — так «границы по умолчанию» остаются поведением
/// обработчика, а не выдуманным на экране значением.
public struct ScanBounds: Sendable, Hashable {
    private var quads: [String: DocumentQuad]

    public init(_ quads: [String: DocumentQuad] = [:]) {
        self.quads = quads
    }

    /// Границы ищет сама обработка.
    public static let automatic = ScanBounds()

    public subscript(id: String) -> DocumentQuad? {
        get { quads[id] }
        set { quads[id] = newValue }
    }

    public subscript(item: MediaItem) -> DocumentQuad? {
        self[item.id]
    }

    public var isEmpty: Bool { quads.isEmpty }
}
