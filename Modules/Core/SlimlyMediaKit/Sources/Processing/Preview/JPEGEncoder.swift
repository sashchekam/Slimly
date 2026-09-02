import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Кадр в JPEG-данные — в таком виде превью уезжает на экран.
protocol JPEGEncoding: Sendable {
    func data(from image: CGImage) -> Data?
}

struct JPEGEncoder: JPEGEncoding {
    /// Превью показывают мелко, но рядом с оригиналом: заметная разница
    /// здесь читалась бы как испорченный результат.
    private static let quality = 0.9

    func data(from image: CGImage) -> Data? {
        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                data,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else { return nil }

        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImageDestinationLossyCompressionQuality: Self.quality] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
