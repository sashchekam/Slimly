import Foundation

/// Кадр из готового файла.
///
/// Результат обработки ещё не ассет медиатеки — это просто файл на диске,
/// и достать из него картинку умеет только модуль системной обработки.
/// Экранам итога нужен один этот протокол, а не весь ImageIO с AVFoundation.
public protocol MediaPreviewRenderer: Sendable {
    /// JPEG-данные превью или `nil`, если кадр достать не удалось.
    func preview(at url: URL, maxPixel: Int) async -> Data?
}
