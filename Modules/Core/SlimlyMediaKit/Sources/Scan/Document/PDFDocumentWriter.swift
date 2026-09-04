import CoreGraphics
import Foundation

/// Сборка готовых страниц в один PDF.
protocol DocumentWriting: Sendable {
    /// - Parameter pages: страницы в порядке следования в документе.
    func write(pages: [ScannedPage], to destination: URL, title: String) throws
}

/// A4 в точках PDF (72 dpi) — размер, на котором документ печатается
/// без пересчёта. Страницу вписываем в лист, а не подгоняем лист под
/// снимок: скан должен выходить из принтера тем, чем был на столе.
struct PDFDocumentWriter: DocumentWriting {
    private static let a4 = CGSize(width: 595, height: 842)

    func write(pages: [ScannedPage], to destination: URL, title: String) throws {
        let info: [CFString: Any] = [
            kCGPDFContextTitle: title,
            kCGPDFContextCreator: "Slimly",
        ]

        guard let context = CGContext(destination as CFURL, mediaBox: nil, info as CFDictionary) else {
            throw ProcessingError.pdfAssemblyFailed
        }

        var written = 0
        for page in pages {
            guard let image = image(for: page) else { continue }

            var box = box(for: image)
            context.beginPage(mediaBox: &box)
            // Белая подложка: страница вписана в лист по длинной стороне,
            // и поля по короткой не должны остаться прозрачными.
            context.setFillColor(gray: 1, alpha: 1)
            context.fill(box)
            context.draw(image, in: frame(of: image, in: box))
            context.endPage()
            written += 1
        }

        context.closePDF()

        guard written > 0 else {
            try? FileManager.default.removeItem(at: destination)
            throw ProcessingError.pdfAssemblyFailed
        }
    }

    private func image(for page: ScannedPage) -> CGImage? {
        switch page {
        case let .jpeg(data): jpegBacked(data)
        case let .bilevel(bitmap): bilevel(bitmap)
        }
    }

    /// Картинка, за которой стоят исходные байты JPEG.
    ///
    /// Именно такую CoreGraphics кладёт в PDF как есть, потоком `DCTDecode`.
    /// Собранная через `CGImageSource` картинка — уже разжатый растр, и тот же
    /// документ вышел бы в десятки раз тяжелее.
    private func jpegBacked(_ data: Data) -> CGImage? {
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }
        return CGImage(
            jpegDataProviderSource: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }

    /// Двухцветная страница уходит в PDF однобитным растром — его CoreGraphics
    /// дожимает Flate, и страница текста весит десяток килобайт вместо двух
    /// сотен, которые запросил бы за неё JPEG.
    private func bilevel(_ bitmap: ScannedPage.Bitmap) -> CGImage? {
        guard let provider = CGDataProvider(data: bitmap.bits as CFData) else { return nil }
        return CGImage(
            width: bitmap.width,
            height: bitmap.height,
            bitsPerComponent: 1,
            bitsPerPixel: 1,
            bytesPerRow: bitmap.rowBytes,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: provider,
            decode: nil,
            // Сглаживание при показе: без него мелкий текст на уменьшенной
            // странице рассыпается в ступеньки.
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }

    /// Альбомный лист для широкого кадра, книжный — для всего остального.
    private func box(for image: CGImage) -> CGRect {
        let size = image.width > image.height
            ? CGSize(width: Self.a4.height, height: Self.a4.width)
            : Self.a4
        return CGRect(origin: .zero, size: size)
    }

    private func frame(of image: CGImage, in box: CGRect) -> CGRect {
        let scale = min(box.width / CGFloat(image.width), box.height / CGFloat(image.height))
        let width = CGFloat(image.width) * scale
        let height = CGFloat(image.height) * scale

        return CGRect(
            x: box.midX - width / 2,
            y: box.midY - height / 2,
            width: width,
            height: height
        )
    }
}
