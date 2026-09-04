import CoreGraphics
import Foundation
import SlimlyCore

/// Истинные пропорции листа по его проекции в кадре.
protocol PageAspectEstimating: Sendable {
    /// Отношение ширины листа к его высоте или `nil`, если по этому
    /// четырёхугольнику восстановить его нельзя.
    ///
    /// - Parameter frame: размер кадра в пикселях. Углы `quad` заданы долями
    ///   от него, а расчёт ведётся от центра кадра — там оптическая ось.
    func ratio(of quad: DocumentQuad, in frame: CGSize) -> CGFloat?
}

/// Метод Чжана и Хэ: у прямоугольника в перспективе две пары параллельных
/// сторон, и по точкам схода этих пар восстанавливаются сразу и фокусное
/// расстояние камеры, и отношение сторон самого прямоугольника.
///
/// Без этого шага страница выходит сплющенной. `CIPerspectiveCorrection`
/// снимает наклон, но размер готовой картинки берёт по длинам сторон
/// четырёхугольника как они есть, а дальний край листа в кадре короче
/// ближнего — и лист A4 приезжает в PDF то узким, то широким, смотря
/// с какого ракурса его сняли.
///
/// Ссылка: Z. Zhang, L. He. Whiteboard scanning and image enhancement.
/// Digital Signal Processing, 2007.
struct PageAspectEstimator: PageAspectEstimating {
    /// Насколько коэффициенты схода должны отличаться от единицы, чтобы
    /// перспектива считалась заметной. Ровно единица означает параллельные
    /// стороны: точка схода уходит в бесконечность, и общая формула делится
    /// на ноль там, где ответ и так известен.
    private static let perspectiveTolerance = 1e-6
    /// Оценка ниже этой считается вырожденной: столько не бывает даже
    /// у кассового чека, а значит, углы пришли неверные.
    private static let sane: ClosedRange<CGFloat> = 0.05 ... 20

    func ratio(of quad: DocumentQuad, in frame: CGSize) -> CGFloat? {
        guard frame.width > 0, frame.height > 0 else { return nil }

        // Начало координат — в центре кадра: формулы ниже считают углы
        // лучами из оптического центра, а не точками растра.
        func centred(_ point: CGPoint) -> Point {
            Point(
                x: Double(point.x * frame.width - frame.width / 2),
                y: Double(point.y * frame.height - frame.height / 2)
            )
        }

        let corners = Corners(
            topLeft: centred(quad.topLeft),
            topRight: centred(quad.topRight),
            bottomLeft: centred(quad.bottomLeft),
            bottomRight: centred(quad.bottomRight)
        )

        guard let ratio = corners.ratio() else { return nil }
        let value = CGFloat(ratio)
        return Self.sane.contains(value) ? value : nil
    }

    fileprivate struct Point {
        let x: Double
        let y: Double
    }

    /// Углы листа лучами из оптического центра. Отдельный тип, потому что
    /// весь расчёт — про их взаимное расположение и больше ни про что.
    fileprivate struct Corners {
        let topLeft: Point
        let topRight: Point
        let bottomLeft: Point
        let bottomRight: Point

        func ratio() -> Double? {
            guard
                let horizontal = converge(topRight, over: bottomLeft),
                let vertical = converge(bottomLeft, over: topRight)
            else {
                return nil
            }

            // Стороны параллельны — перспективы нет, и отношение сторон
            // читается прямо с картинки.
            guard
                abs(horizontal - 1) > PageAspectEstimator.perspectiveTolerance,
                abs(vertical - 1) > PageAspectEstimator.perspectiveTolerance
            else {
                return flat()
            }

            // Квадрат фокусного расстояния в пикселях кадра. Отрицательный
            // означает, что такой камеры не бывает: углы описывают не
            // прямоугольник, а произвольный четырёхугольник.
            let width = scaled(topRight, by: horizontal)
            let height = scaled(bottomLeft, by: vertical)
            let focal = -(height.y * width.y + height.x * width.x)
                / ((vertical - 1) * (horizontal - 1))
            guard focal > 0 else { return flat() }

            let across = pow(horizontal - 1, 2) + (width.x * width.x + width.y * width.y) / focal
            let along = pow(vertical - 1, 2) + (height.x * height.x + height.y * height.y) / focal
            guard along > 0 else { return flat() }

            return (across / along).squareRoot()
        }

        /// Коэффициент схода стороны `corner`: во сколько раз её дальний
        /// конец «сжат» перспективой относительно ближнего.
        private func converge(_ corner: Point, over other: Point) -> Double? {
            let divisor = cross(corner, other)
            guard abs(divisor) > 1e-9 else { return nil }
            return cross(topLeft, other) / divisor
        }

        /// Смешанное произведение трёх лучей: ноль означает, что они лежат
        /// в одной плоскости, то есть точка схода этой пары сторон найдена.
        private func cross(_ point: Point, _ other: Point) -> Double {
            (point.y - bottomRight.y) * other.x - (point.x - bottomRight.x) * other.y
                + point.x * bottomRight.y - point.y * bottomRight.x
        }

        private func scaled(_ corner: Point, by factor: Double) -> Point {
            Point(x: factor * corner.x - topLeft.x, y: factor * corner.y - topLeft.y)
        }

        /// Отношение сторон без перспективы — просто их длины.
        private func flat() -> Double? {
            let across = hypot(topRight.x - topLeft.x, topRight.y - topLeft.y)
            let along = hypot(bottomLeft.x - topLeft.x, bottomLeft.y - topLeft.y)
            guard along > 0 else { return nil }
            return across / along
        }
    }
}
