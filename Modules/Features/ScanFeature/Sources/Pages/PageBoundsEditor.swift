import SlimlyCore
import SlimlyDesignSystem
import SwiftUI
import UIKit

/// Кадр страницы с рамкой, за углы которой можно тянуть.
///
/// Всё вне рамки притушено — так видно не «где линии», а «что останется»:
/// от границ зависит вся страница, и судить о них по одному контуру трудно.
/// Под пальцем угол не видно, поэтому на время перетаскивания в свободном
/// углу кадра появляется лупа с тем же куском изображения.
struct PageBoundsEditor: View {
    let image: UIImage?
    /// Пропорции, пока кадра нет: пустое место должно занять ровно столько,
    /// сколько потом займёт страница, иначе экран прыгает при загрузке.
    let fallbackAspectRatio: CGFloat
    let quad: DocumentQuad
    let onMove: (DocumentQuad.Corner, CGPoint) -> Void

    @State
    private var drag: Drag?

    /// Начало перетаскивания. Точку считаем от него, а не от текущего угла:
    /// отклонённое перемещение (рамка сложилась бы бантиком) не должно
    /// сбивать палец с угла — иначе рамка «уползает» от пальца.
    private struct Drag {
        let corner: DocumentQuad.Corner
        let origin: CGPoint
    }

    /// Кольцо-ручка и её область нажатия. Кольцо мелкое, чтобы не закрывать
    /// край страницы, а нажатие ловится по всей сорокачетырёхточечной цели.
    private static let handleSize: CGFloat = 26
    private static let touchSize: CGFloat = 44

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                GeometryReader { geometry in
                    frame(in: geometry.size)
                }
            }
            .sensoryFeedback(.selection, trigger: drag != nil)
    }

    private var aspectRatio: CGFloat {
        guard let image, image.size.height > 0 else { return fallbackAspectRatio }
        return image.size.width / image.size.height
    }

    private func frame(in size: CGSize) -> some View {
        ZStack {
            page

            Shade(quad: quad, size: size)

            Outline(quad: quad, size: size)

            ForEach(DocumentQuad.Corner.allCases) { corner in
                handle(corner, in: size)
            }
        }
        // Рамку двигает палец, и догоняющая анимация превратила бы её
        // в резиновую. Зато «Авто» и «Весь кадр» должны переезжать плавно.
        .animation(drag == nil ? .easeOut(duration: 0.2) : nil, value: quad)
        .overlay(alignment: loupeAlignment) {
            if let drag, let image {
                Loupe(image: image, quad: quad, corner: drag.corner, frame: size)
                    .padding(10)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    // Лупа лежит поверх кадра и накрывает собой дальний угол:
                    // без этого она перехватывала бы нажатие по его ручке.
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeOut(duration: 0.15), value: drag?.corner)
    }

    @ViewBuilder
    private var page: some View {
        ZStack {
            SlimlyStripes(light: SlimlyColor.stripeLight, dark: SlimlyColor.stripeDark, band: 9)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous))
    }

    // MARK: Ручки

    private func handle(_ corner: DocumentQuad.Corner, in size: CGSize) -> some View {
        let isActive = drag?.corner == corner

        return Circle()
            .fill(SlimlyColor.accentTint(22))
            .overlay(Circle().strokeBorder(SlimlyColor.accent200, lineWidth: 2))
            .overlay(Circle().fill(SlimlyColor.accent200).frame(width: 5, height: 5))
            .frame(width: Self.handleSize, height: Self.handleSize)
            .scaleEffect(isActive ? 1.3 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isActive)
            .frame(width: Self.touchSize, height: Self.touchSize)
            .contentShape(Circle())
            .position(point(quad[corner], in: size))
            .gesture(gesture(for: corner, in: size))
            .accessibilityLabel(label(for: corner))
    }

    private func gesture(for corner: DocumentQuad.Corner, in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let origin = drag?.origin ?? quad[corner]
                if drag == nil {
                    drag = Drag(corner: corner, origin: origin)
                }
                onMove(
                    corner,
                    CGPoint(
                        x: origin.x + value.translation.width / size.width,
                        y: origin.y + value.translation.height / size.height
                    )
                )
            }
            .onEnded { _ in drag = nil }
    }

    private func label(for corner: DocumentQuad.Corner) -> String {
        switch corner {
        case .topLeft: "Левый верхний угол"
        case .topRight: "Правый верхний угол"
        case .bottomRight: "Правый нижний угол"
        case .bottomLeft: "Левый нижний угол"
        }
    }

    /// Лупа уходит в противоположную по горизонтали половину кадра: рядом
    /// с пальцем ей места нет, а под ним она была бы бесполезна.
    private var loupeAlignment: Alignment {
        guard let drag else { return .topLeading }
        return quad[drag.corner].x < 0.5 ? .topTrailing : .topLeading
    }
}

// MARK: - Части рамки

/// Всё, что вне рамки, гасим: страница остаётся яркой, фон уходит назад.
private struct Shade: View {
    let quad: DocumentQuad
    let size: CGSize

    var body: some View {
        Path { path in
            path.addRect(CGRect(origin: .zero, size: size))
            path.addLines(quad.corners.map { point($0, in: size) })
            path.closeSubpath()
        }
        // Чётно-нечётное правило вырезает рамку из общей заливки — так
        // затемнение получается одной фигурой, а не четырьмя полосами.
        .fill(SlimlyColor.background.opacity(0.68), style: FillStyle(eoFill: true))
        .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous))
        .allowsHitTesting(false)
    }
}

/// Контур страницы: линия по сторонам и уголки поверх неё.
private struct Outline: View {
    let quad: DocumentQuad
    let size: CGSize

    var body: some View {
        ZStack {
            shape
                .stroke(SlimlyColor.accent, lineWidth: 1.5)

            corners
                .stroke(SlimlyColor.accent200, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .shadow(color: SlimlyColor.accent.opacity(0.3), radius: 10)
        .allowsHitTesting(false)
    }

    private var shape: Path {
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        return path
    }

    /// Короткие усы у каждого угла — по ним видно, куда именно тянуть,
    /// даже когда сама линия теряется на светлой странице.
    private var corners: Path {
        var path = Path()
        for (index, corner) in points.enumerated() {
            for neighbour in [points[(index + 3) % 4], points[(index + 1) % 4]] {
                path.move(to: corner)
                path.addLine(to: corner.approaching(neighbour, by: 20, share: 0.28))
            }
        }
        return path
    }

    private var points: [CGPoint] { quad.corners.map { point($0, in: size) } }
}

/// Кусок кадра под пальцем, увеличенный в два с половиной раза.
///
/// Сильнее нельзя: на увеличении крупнее трёх крат в круг перестаёт помещаться
/// край страницы, и становится не видно, куда относительно него едет угол.
private struct Loupe: View {
    let image: UIImage
    let quad: DocumentQuad
    let corner: DocumentQuad.Corner
    /// Размер кадра под лупой — в нём считаются доли.
    let frame: CGSize

    private static let side: CGFloat = 104
    private static let zoom: CGFloat = 2.6
    /// Точка, которой человек целится. Крест вокруг неё разорван: сплошные
    /// линии перечеркнули бы саму точку ровно там, где на неё и смотрят.
    private static let markSize: CGFloat = 9
    private static let markGap: CGFloat = 8
    private static let markReach: CGFloat = 17

    var body: some View {
        // Круг задаёт систему координат: всё остальное приходит наложением
        // и получает ровно его размер. В `ZStack` кадр, увеличенный в разы,
        // растянул бы стопку до себя, и центр лупы уехал бы вместе с ней.
        SlimlyColor.surfaceSunken
            .frame(width: Self.side, height: Self.side)
            .overlay(alignment: .topLeading) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: frame.width * Self.zoom, height: frame.height * Self.zoom)
                    .offset(x: offset.x, y: offset.y)
            }
            .overlay { outline }
            .overlay { crosshair }
            .overlay { mark }
            .clipShape(Circle())
            // Кромка вместо тени: круг лежит поверх кадра, и подсветить его
            // здесь можно только линией — как всё в Nocturne.
            .overlay(Circle().strokeBorder(SlimlyColor.accent600, lineWidth: 1))
    }

    private var center: CGPoint {
        CGPoint(x: Self.side / 2, y: Self.side / 2)
    }

    /// Сдвиг кадра так, чтобы угол оказался в центре лупы.
    private var offset: CGPoint {
        let point = zoomed(quad[corner])
        return CGPoint(x: center.x - point.x, y: center.y - point.y)
    }

    /// Рамка внутри лупы: без неё увеличенный кусок бумаги ничем не отличается
    /// от любого другого куска бумаги.
    private var outline: some View {
        Path { path in
            path.addLines(quad.corners.map { shifted($0) })
            path.closeSubpath()
        }
        .stroke(SlimlyColor.accent200, lineWidth: 1.5)
    }

    private var crosshair: some View {
        Path { path in
            for (dx, dy) in [(1.0, 0.0), (-1.0, 0.0), (0.0, 1.0), (0.0, -1.0)] {
                path.move(to: CGPoint(
                    x: center.x + dx * Self.markGap,
                    y: center.y + dy * Self.markGap
                ))
                path.addLine(to: CGPoint(
                    x: center.x + dx * Self.markReach,
                    y: center.y + dy * Self.markReach
                ))
            }
        }
        .stroke(SlimlyColor.accent100.opacity(0.9), lineWidth: 1)
    }

    /// Сама точка угла. Светлая обводка нужна на тёмной странице так же,
    /// как заливка — на белой: без неё точка теряется в одном из двух случаев.
    private var mark: some View {
        Circle()
            .fill(SlimlyColor.accent)
            .overlay(Circle().strokeBorder(SlimlyColor.accent100, lineWidth: 1.5))
            .frame(width: Self.markSize, height: Self.markSize)
            .position(center)
    }

    private func zoomed(_ normalized: CGPoint) -> CGPoint {
        CGPoint(
            x: normalized.x * frame.width * Self.zoom,
            y: normalized.y * frame.height * Self.zoom
        )
    }

    private func shifted(_ normalized: CGPoint) -> CGPoint {
        let point = zoomed(normalized)
        return CGPoint(x: point.x + offset.x, y: point.y + offset.y)
    }
}

// MARK: - Мелочи геометрии

/// Доли кадра — в точки экрана.
private func point(_ normalized: CGPoint, in size: CGSize) -> CGPoint {
    CGPoint(x: normalized.x * size.width, y: normalized.y * size.height)
}

private extension CGPoint {
    /// Точка на отрезке к соседу: длиной в `distance`, но не длиннее доли стороны.
    func approaching(_ other: CGPoint, by distance: CGFloat, share: CGFloat) -> CGPoint {
        let side = hypot(other.x - x, other.y - y)
        guard side > 0 else { return self }
        let fraction = min(distance / side, share)
        return CGPoint(x: x + (other.x - x) * fraction, y: y + (other.y - y) * fraction)
    }
}
