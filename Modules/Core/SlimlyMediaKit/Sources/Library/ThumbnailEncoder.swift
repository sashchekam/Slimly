import Foundation
import UIKit

/// Кадр миниатюры в байты JPEG.
protocol ThumbnailEncoding: Sendable {
    /// - Parameter quality: от нуля до единицы; чем выше, тем чётче кадр
    ///   и тем дороже кодирование.
    func data(from image: UIImage, quality: Double) -> Data?
}

struct ThumbnailEncoder: ThumbnailEncoding {
    func data(from image: UIImage, quality: Double) -> Data? {
        // Рисуем в непрозрачный контекст, а не жмём кадр как есть.
        // PhotoKit отдаёт миниатюру с альфа-каналом, хотя прозрачного в ней
        // ничего нет, — на такой кадр ImageIO ругается в логи и при распаковке
        // держит вдвое больше памяти. Заодно снимается ориентация: рисование
        // разворачивает кадр, а не запоминает поворот отдельным полем.
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = true
        format.scale = image.scale
        // Расширенный диапазон миниатюре ни к чему, а памяти на кадр он берёт
        // вдвое: показываем её в плитке размером с ноготь.
        format.preferredRange = .standard

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.jpegData(withCompressionQuality: quality) { _ in
            image.draw(at: .zero)
        }
    }
}
