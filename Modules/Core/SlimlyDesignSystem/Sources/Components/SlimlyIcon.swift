import SwiftUI

/// Иконки интерфейса, обведённые контуром, — как в макете.
///
/// Рисуем путями, а не системными символами: у SF Symbols нет точных
/// соответствий для «сжать» и «HEIC → JPEG», а подмена похожими сбивает
/// оптический вес строки. Ширина задаётся явно, высота следует пропорции.
public struct SlimlyIcon: View {
    public enum Kind: Sendable {
        case plus
        case convert
        case check
        case chevronLeft
        case chevronRight
        case arrowRight
        case trophy
        case compress
        case person
    }

    private let kind: Kind
    private let width: CGFloat

    public init(_ kind: Kind, width: CGFloat) {
        self.kind = kind
        self.width = width
    }

    public var body: some View {
        let scale = width / kind.viewBox.width

        ZStack {
            ForEach(Array(kind.layers.enumerated()), id: \.offset) { index, layer in
                IconShape(kind: kind, layer: index)
                    .stroke(
                        style: StrokeStyle(
                            lineWidth: layer * scale,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
            }
        }
        .frame(width: width, height: width * kind.viewBox.height / kind.viewBox.width)
    }
}

private extension SlimlyIcon.Kind {
    var viewBox: CGSize {
        switch self {
        case .plus, .convert, .trophy: CGSize(width: 20, height: 20)
        case .check: CGSize(width: 12, height: 12)
        case .chevronLeft, .chevronRight: CGSize(width: 8, height: 14)
        case .arrowRight: CGSize(width: 16, height: 10)
        case .compress, .person: CGSize(width: 24, height: 24)
        }
    }

    /// Толщина обводки каждого слоя в координатах viewBox.
    var layers: [CGFloat] {
        switch self {
        case .plus: [1.7]
        case .convert: [1.5]
        case .check: [2]
        case .chevronLeft: [1.8]
        case .chevronRight: [1.6]
        case .arrowRight: [1.4]
        case .trophy: [1.3, 1.1]
        case .compress, .person: [1.6]
        }
    }
}

private struct IconShape: Shape {
    let kind: SlimlyIcon.Kind
    let layer: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        build(&path)

        let box = viewBox
        let transform = CGAffineTransform(
            scaleX: rect.width / box.width,
            y: rect.height / box.height
        )
        return path.applying(transform)
    }

    private var viewBox: CGSize {
        switch kind {
        case .plus, .convert, .trophy: CGSize(width: 20, height: 20)
        case .check: CGSize(width: 12, height: 12)
        case .chevronLeft, .chevronRight: CGSize(width: 8, height: 14)
        case .arrowRight: CGSize(width: 16, height: 10)
        case .compress, .person: CGSize(width: 24, height: 24)
        }
    }

    private func build(_ path: inout Path) {
        switch kind {
        case .plus:
            path.line(from: CGPoint(x: 10, y: 4.2), to: CGPoint(x: 10, y: 15.8))
            path.line(from: CGPoint(x: 4.2, y: 10), to: CGPoint(x: 15.8, y: 10))

        case .convert:
            path.line(from: CGPoint(x: 3.4, y: 7.6), to: CGPoint(x: 12.6, y: 7.6))
            path.polyline([CGPoint(x: 10, y: 4.9), CGPoint(x: 12.6, y: 7.6), CGPoint(x: 10, y: 10.3)])
            path.line(from: CGPoint(x: 16.6, y: 12.4), to: CGPoint(x: 7.4, y: 12.4))
            path.polyline([CGPoint(x: 10, y: 9.7), CGPoint(x: 7.4, y: 12.4), CGPoint(x: 10, y: 15.1)])

        case .check:
            path.polyline([CGPoint(x: 2, y: 6.3), CGPoint(x: 4.6, y: 8.9), CGPoint(x: 10, y: 3.4)])

        case .chevronLeft:
            path.polyline([CGPoint(x: 6.5, y: 1), CGPoint(x: 1, y: 7), CGPoint(x: 6.5, y: 13)])

        case .chevronRight:
            path.polyline([CGPoint(x: 1.5, y: 1), CGPoint(x: 7, y: 7), CGPoint(x: 1.5, y: 13)])

        case .arrowRight:
            path.line(from: CGPoint(x: 1, y: 5), to: CGPoint(x: 14, y: 5))
            path.polyline([CGPoint(x: 11, y: 1.5), CGPoint(x: 14.5, y: 5), CGPoint(x: 11, y: 8.5)])

        case .compress:
            path.line(from: CGPoint(x: 12, y: 3), to: CGPoint(x: 12, y: 9))
            path.polyline([CGPoint(x: 9, y: 6), CGPoint(x: 12, y: 3), CGPoint(x: 15, y: 6)])
            path.line(from: CGPoint(x: 12, y: 21), to: CGPoint(x: 12, y: 15))
            path.polyline([CGPoint(x: 9, y: 18), CGPoint(x: 12, y: 21), CGPoint(x: 15, y: 18)])
            path.line(from: CGPoint(x: 4, y: 12), to: CGPoint(x: 20, y: 12))

        case .person:
            path.addEllipse(in: CGRect(x: 8.4, y: 4.9, width: 7.2, height: 7.2))
            path.move(to: CGPoint(x: 4.8, y: 20))
            path.addCurve(
                to: CGPoint(x: 12, y: 14.6),
                control1: CGPoint(x: 5.9, y: 16.4),
                control2: CGPoint(x: 8.7, y: 14.6)
            )
            path.addCurve(
                to: CGPoint(x: 19.2, y: 20),
                control1: CGPoint(x: 15.3, y: 14.6),
                control2: CGPoint(x: 18.1, y: 16.4)
            )

        case .trophy where layer == 0:
            path.move(to: CGPoint(x: 6.2, y: 3))
            path.addLine(to: CGPoint(x: 13.8, y: 3))
            path.addLine(to: CGPoint(x: 13.8, y: 6.8))
            path.addArc(
                center: CGPoint(x: 10, y: 6.8),
                radius: 3.8,
                startAngle: .degrees(0),
                endAngle: .degrees(180),
                clockwise: false
            )
            path.closeSubpath()
            path.line(from: CGPoint(x: 10, y: 10.8), to: CGPoint(x: 10, y: 14.2))
            path.line(from: CGPoint(x: 7, y: 17), to: CGPoint(x: 13, y: 17))

        case .trophy:
            path.move(to: CGPoint(x: 13.8, y: 4.2))
            path.addLine(to: CGPoint(x: 16.2, y: 4.2))
            path.addLine(to: CGPoint(x: 16.2, y: 5.4))
            path.addArc(
                center: CGPoint(x: 13.8, y: 5.4),
                radius: 2.4,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
            path.move(to: CGPoint(x: 6.2, y: 4.2))
            path.addLine(to: CGPoint(x: 3.8, y: 4.2))
            path.addLine(to: CGPoint(x: 3.8, y: 5.4))
            path.addArc(
                center: CGPoint(x: 6.2, y: 5.4),
                radius: 2.4,
                startAngle: .degrees(180),
                endAngle: .degrees(90),
                clockwise: true
            )
        }
    }
}

private extension Path {
    mutating func line(from start: CGPoint, to end: CGPoint) {
        move(to: start)
        addLine(to: end)
    }

    mutating func polyline(_ points: [CGPoint]) {
        guard let first = points.first else { return }
        move(to: first)
        for point in points.dropFirst() { addLine(to: point) }
    }
}
