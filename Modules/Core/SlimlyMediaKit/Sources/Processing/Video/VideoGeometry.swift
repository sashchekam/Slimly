import CoreGraphics
import Foundation

/// Геометрия кадра одним куском: по отдельности эти величины смысла
/// не имеют — поворот считается от исходного размера, сдвиг от рамки
/// после поворота, а масштаб связывает их с итоговым кадром.
struct VideoGeometry {
    let naturalSize: CGSize
    let renderSize: CGSize
    let transform: CGAffineTransform
    let displayRect: CGRect
    let scale: CGFloat
}

/// Пересчёт размеров кадра под ограничение короткой стороны.
protocol VideoGeometryCalculating: Sendable {
    /// - Parameter shortSideLimit: 1080 — это «1080p» и для вертикали,
    ///   и для горизонтали. `nil` — размер кадра не трогаем.
    func geometry(
        naturalSize: CGSize,
        transform: CGAffineTransform,
        shortSideLimit: Int?
    ) -> VideoGeometry

    /// Кодировщики требуют чётных размеров: 4:2:0 делит кадр на пары пикселей.
    func evenSize(_ size: CGSize) -> CGSize
}

struct VideoGeometryCalculator: VideoGeometryCalculating {
    func geometry(
        naturalSize: CGSize,
        transform: CGAffineTransform,
        shortSideLimit: Int?
    ) -> VideoGeometry {
        let displayRect = CGRect(origin: .zero, size: naturalSize).applying(transform)
        let scale = scale(for: displayRect.size, shortSideLimit: shortSideLimit)

        return VideoGeometry(
            naturalSize: naturalSize,
            renderSize: evenSize(
                CGSize(width: displayRect.width * scale, height: displayRect.height * scale)
            ),
            transform: transform,
            displayRect: displayRect,
            scale: scale
        )
    }

    func evenSize(_ size: CGSize) -> CGSize {
        CGSize(
            width: max(2, (size.width / 2).rounded() * 2),
            height: max(2, (size.height / 2).rounded() * 2)
        )
    }

    private func scale(for size: CGSize, shortSideLimit: Int?) -> CGFloat {
        guard let limit = shortSideLimit, limit > 0 else { return 1 }
        let shortSide = min(size.width, size.height)
        guard shortSide > CGFloat(limit) else { return 1 }
        return CGFloat(limit) / shortSide
    }
}
