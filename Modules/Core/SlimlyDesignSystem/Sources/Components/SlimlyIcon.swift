import SwiftUI

/// Иконки интерфейса, обведённые контуром, — как в макете.
///
/// Рисуем путями, а не системными символами: у SF Symbols нет точных
/// соответствий для «сжать» и «извлечь звук», а подмена похожими сбивает
/// оптический вес строки. Ширина задаётся явно, высота следует пропорции.
public struct SlimlyIcon: View {
    public enum Kind: Sendable {
        // Инструменты
        case compress
        case photoConvert
        case videoConvert
        case scan
        case audio
        // Источники
        case camera
        case gallery
        case folder
        // Управление
        case check
        case chevronLeft
        case chevronRight
        case chevronDown
        case arrowRight
        case eye
        case trash
        case person
        case share
    }

    private let kind: Kind
    private let width: CGFloat

    public init(_ kind: Kind, width: CGFloat) {
        self.kind = kind
        self.width = width
    }

    public var body: some View {
        let scale = width / kind.viewBox.width

        IconShape(kind: kind)
            .stroke(
                style: StrokeStyle(
                    lineWidth: kind.lineWidth * scale,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .frame(width: width, height: width * kind.viewBox.height / kind.viewBox.width)
    }
}

extension SlimlyIcon.Kind {
    /// Система координат макета. Все точки ниже заданы в ней.
    var viewBox: CGSize {
        switch self {
        case .check: CGSize(width: 12, height: 12)
        case .chevronLeft, .chevronRight: CGSize(width: 8, height: 14)
        case .chevronDown: CGSize(width: 10, height: 7)
        case .arrowRight: CGSize(width: 16, height: 10)
        default: CGSize(width: 24, height: 24)
        }
    }

    /// Толщина обводки в координатах viewBox.
    var lineWidth: CGFloat {
        switch self {
        case .check: 2
        case .chevronLeft: 1.8
        case .chevronRight, .chevronDown: 1.6
        case .arrowRight: 1.4
        case .compress, .person, .share: 1.6
        default: 1.5
        }
    }
}

private struct IconShape: Shape {
    let kind: SlimlyIcon.Kind

    func path(in rect: CGRect) -> Path {
        var path = Path()
        build(&path)

        let box = kind.viewBox
        return path.applying(
            CGAffineTransform(scaleX: rect.width / box.width, y: rect.height / box.height)
        )
    }

    private func build(_ path: inout Path) {
        switch kind {
        case .compress:
            path.line(from: CGPoint(x: 12, y: 3), to: CGPoint(x: 12, y: 9))
            path.polyline([CGPoint(x: 9, y: 6), CGPoint(x: 12, y: 3), CGPoint(x: 15, y: 6)])
            path.line(from: CGPoint(x: 12, y: 21), to: CGPoint(x: 12, y: 15))
            path.polyline([CGPoint(x: 9, y: 18), CGPoint(x: 12, y: 21), CGPoint(x: 15, y: 18)])
            path.line(from: CGPoint(x: 4, y: 12), to: CGPoint(x: 20, y: 12))

        case .photoConvert:
            path.addRoundedRect(
                in: CGRect(x: 3.2, y: 5.4, width: 12, height: 9.4),
                cornerSize: CGSize(width: 2, height: 2)
            )
            path.move(to: CGPoint(x: 8.8, y: 19.4))
            path.corner(via: CGPoint(x: 19.8, y: 19.4), to: CGPoint(x: 19.8, y: 9.6), radius: 2)
            path.addLine(to: CGPoint(x: 19.8, y: 9.6))
            path.polyline([CGPoint(x: 17.4, y: 12.6), CGPoint(x: 19.8, y: 9.6), CGPoint(x: 22, y: 12.6)])

        case .videoConvert:
            path.addRoundedRect(
                in: CGRect(x: 2.6, y: 6, width: 13, height: 12),
                cornerSize: CGSize(width: 2.4, height: 2.4)
            )
            path.polyline([
                CGPoint(x: 15.6, y: 11),
                CGPoint(x: 20.2, y: 8.2),
                CGPoint(x: 20.2, y: 15.8),
                CGPoint(x: 15.6, y: 13),
            ])
            path.closeSubpath()

        case .scan:
            // Четыре уголка рамки: сам документ не рисуем, его заменяет
            // линия сканера посередине.
            path.move(to: CGPoint(x: 3.4, y: 8.4))
            path.corner(via: CGPoint(x: 3.4, y: 3.4), to: CGPoint(x: 8.4, y: 3.4), radius: 2.4)
            path.addLine(to: CGPoint(x: 8.4, y: 3.4))
            path.move(to: CGPoint(x: 20.6, y: 8.4))
            path.corner(via: CGPoint(x: 20.6, y: 3.4), to: CGPoint(x: 15.6, y: 3.4), radius: 2.4)
            path.addLine(to: CGPoint(x: 15.6, y: 3.4))
            path.move(to: CGPoint(x: 3.4, y: 15.6))
            path.corner(via: CGPoint(x: 3.4, y: 20.6), to: CGPoint(x: 8.4, y: 20.6), radius: 2.4)
            path.addLine(to: CGPoint(x: 8.4, y: 20.6))
            path.move(to: CGPoint(x: 20.6, y: 15.6))
            path.corner(via: CGPoint(x: 20.6, y: 20.6), to: CGPoint(x: 15.6, y: 20.6), radius: 2.4)
            path.addLine(to: CGPoint(x: 15.6, y: 20.6))
            path.line(from: CGPoint(x: 6.6, y: 12), to: CGPoint(x: 17.4, y: 12))

        case .audio:
            path.polyline([
                CGPoint(x: 9.4, y: 15.6),
                CGPoint(x: 9.4, y: 5.8),
                CGPoint(x: 18.4, y: 4.2),
                CGPoint(x: 18.4, y: 13.8),
            ])
            path.addEllipse(in: CGRect(x: 3.8, y: 13.6, width: 5.6, height: 5.6))
            path.addEllipse(in: CGRect(x: 12.8, y: 11.8, width: 5.6, height: 5.6))

        case .camera:
            path.move(to: CGPoint(x: 3.4, y: 8.6))
            path.corner(via: CGPoint(x: 3.4, y: 6.2), to: CGPoint(x: 7.1, y: 6.2), radius: 2.4)
            path.addLine(to: CGPoint(x: 7.1, y: 6.2))
            path.addLine(to: CGPoint(x: 8.2, y: 4.4))
            path.addLine(to: CGPoint(x: 14.8, y: 4.4))
            path.addLine(to: CGPoint(x: 15.9, y: 6.2))
            path.addLine(to: CGPoint(x: 17.2, y: 6.2))
            path.corner(via: CGPoint(x: 19.6, y: 6.2), to: CGPoint(x: 19.6, y: 16.2), radius: 2.4)
            path.corner(via: CGPoint(x: 19.6, y: 18.6), to: CGPoint(x: 5.8, y: 18.6), radius: 2.4)
            path.corner(via: CGPoint(x: 3.4, y: 18.6), to: CGPoint(x: 3.4, y: 8.6), radius: 2.4)
            path.closeSubpath()
            path.addEllipse(in: CGRect(x: 8.6, y: 9, width: 6.8, height: 6.8))

        case .gallery:
            path.addRoundedRect(
                in: CGRect(x: 3.4, y: 4.6, width: 17.2, height: 14.8),
                cornerSize: CGSize(width: 2.4, height: 2.4)
            )
            path.polyline([
                CGPoint(x: 6, y: 16.4),
                CGPoint(x: 10.2, y: 11.8),
                CGPoint(x: 13.3, y: 15),
                CGPoint(x: 15.6, y: 12.6),
                CGPoint(x: 18.2, y: 16.4),
            ])

        case .folder:
            path.move(to: CGPoint(x: 3.4, y: 7.6))
            path.corner(via: CGPoint(x: 3.4, y: 5.6), to: CGPoint(x: 8.4, y: 5.6), radius: 2)
            path.addLine(to: CGPoint(x: 8.4, y: 5.6))
            path.addLine(to: CGPoint(x: 10, y: 7.6))
            path.addLine(to: CGPoint(x: 16.6, y: 7.6))
            path.corner(via: CGPoint(x: 18.6, y: 7.6), to: CGPoint(x: 18.6, y: 16.8), radius: 2)
            path.corner(via: CGPoint(x: 18.6, y: 18.8), to: CGPoint(x: 5.4, y: 18.8), radius: 2)
            path.corner(via: CGPoint(x: 3.4, y: 18.8), to: CGPoint(x: 3.4, y: 7.6), radius: 2)
            path.closeSubpath()

        case .check:
            path.polyline([CGPoint(x: 2, y: 6.3), CGPoint(x: 4.6, y: 8.9), CGPoint(x: 10, y: 3.4)])

        case .chevronLeft:
            path.polyline([CGPoint(x: 6.5, y: 1), CGPoint(x: 1, y: 7), CGPoint(x: 6.5, y: 13)])

        case .chevronRight:
            path.polyline([CGPoint(x: 1.5, y: 1), CGPoint(x: 7, y: 7), CGPoint(x: 1.5, y: 13)])

        case .chevronDown:
            path.polyline([CGPoint(x: 1, y: 1.4), CGPoint(x: 5, y: 5.4), CGPoint(x: 9, y: 1.4)])

        case .arrowRight:
            path.line(from: CGPoint(x: 1, y: 5), to: CGPoint(x: 14, y: 5))
            path.polyline([CGPoint(x: 11, y: 1.5), CGPoint(x: 14.5, y: 5), CGPoint(x: 11, y: 8.5)])

        case .eye:
            path.move(to: CGPoint(x: 2.6, y: 12))
            path.addCurve(
                to: CGPoint(x: 12, y: 6.4),
                control1: CGPoint(x: 2.6, y: 12),
                control2: CGPoint(x: 6, y: 6.4)
            )
            path.addCurve(
                to: CGPoint(x: 21.4, y: 12),
                control1: CGPoint(x: 18, y: 6.4),
                control2: CGPoint(x: 21.4, y: 12)
            )
            path.addCurve(
                to: CGPoint(x: 12, y: 17.6),
                control1: CGPoint(x: 21.4, y: 12),
                control2: CGPoint(x: 18, y: 17.6)
            )
            path.addCurve(
                to: CGPoint(x: 2.6, y: 12),
                control1: CGPoint(x: 6, y: 17.6),
                control2: CGPoint(x: 2.6, y: 12)
            )
            path.closeSubpath()
            path.addEllipse(in: CGRect(x: 9.4, y: 9.4, width: 5.2, height: 5.2))

        case .trash:
            path.line(from: CGPoint(x: 4.6, y: 7.4), to: CGPoint(x: 19.4, y: 7.4))
            path.polyline([
                CGPoint(x: 9.4, y: 7.4),
                CGPoint(x: 9.4, y: 5.2),
                CGPoint(x: 14.6, y: 5.2),
                CGPoint(x: 14.6, y: 7.4),
            ])
            path.move(to: CGPoint(x: 6.6, y: 7.4))
            path.addLine(to: CGPoint(x: 7.5, y: 18.4))
            path.addQuadCurve(to: CGPoint(x: 9.5, y: 20.2), control: CGPoint(x: 7.6, y: 20.2))
            path.addLine(to: CGPoint(x: 14.5, y: 20.2))
            path.addQuadCurve(to: CGPoint(x: 16.5, y: 18.4), control: CGPoint(x: 16.4, y: 20.2))
            path.addLine(to: CGPoint(x: 17.4, y: 7.4))

        case .share:
            // Стрелка вверх из открытой коробки — системный жест «поделиться».
            path.line(from: CGPoint(x: 12, y: 15.4), to: CGPoint(x: 12, y: 3.6))
            path.polyline([CGPoint(x: 8.4, y: 7.1), CGPoint(x: 12, y: 3.5), CGPoint(x: 15.6, y: 7.1)])
            path.move(to: CGPoint(x: 6.4, y: 11.2))
            path.addLine(to: CGPoint(x: 5.2, y: 11.2))
            path.corner(via: CGPoint(x: 3.6, y: 11.2), to: CGPoint(x: 3.6, y: 19.2), radius: 1.6)
            path.addLine(to: CGPoint(x: 3.6, y: 19.2))
            path.corner(via: CGPoint(x: 3.6, y: 20.8), to: CGPoint(x: 18.8, y: 20.8), radius: 1.6)
            path.addLine(to: CGPoint(x: 18.8, y: 20.8))
            path.corner(via: CGPoint(x: 20.4, y: 20.8), to: CGPoint(x: 20.4, y: 12.8), radius: 1.6)
            path.addLine(to: CGPoint(x: 20.4, y: 12.8))
            path.corner(via: CGPoint(x: 20.4, y: 11.2), to: CGPoint(x: 17.6, y: 11.2), radius: 1.6)
            path.addLine(to: CGPoint(x: 17.6, y: 11.2))

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

    /// Скруглённый угол: линия из текущей точки к `via` и дуга в сторону `to`.
    /// Через касательные — так радиус не нужно переводить в углы дуги.
    mutating func corner(via: CGPoint, to: CGPoint, radius: CGFloat) {
        addArc(tangent1End: via, tangent2End: to, radius: radius)
    }
}
