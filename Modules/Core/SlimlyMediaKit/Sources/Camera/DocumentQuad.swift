import CoreGraphics
import Foundation

/// Границы листа, найденные в кадре.
///
/// Координаты — доли кадра с началом в левом верхнем углу. Vision считает
/// от нижнего, но рамку рисует SwiftUI, и переворачивать ось один раз здесь
/// дешевле, чем помнить про неё в каждом месте отрисовки.
public struct DocumentQuad: Sendable, Hashable {
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

    /// Насколько углы разъехались с прошлым кадром — в долях кадра.
    ///
    /// По этому числу решается, что лист лежит спокойно: сравнивать площади
    /// бесполезно, потому что при повороте вокруг центра она не меняется.
    func drift(from previous: DocumentQuad) -> CGFloat {
        zip(corners, previous.corners).reduce(0) { largest, pair in
            max(largest, hypot(pair.0.x - pair.1.x, pair.0.y - pair.1.y))
        }
    }
}
