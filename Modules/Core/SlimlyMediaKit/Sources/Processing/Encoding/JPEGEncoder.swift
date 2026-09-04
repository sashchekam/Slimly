import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Готовый растр в байты JPEG.
protocol JPEGEncoding: Sendable {
    /// - Parameter quality: от нуля до единицы; чем выше, тем меньше звона
    ///   на резких границах и тем тяжелее результат.
    func data(from image: CGImage, quality: Double) -> Data?
}

struct JPEGEncoder: JPEGEncoding {
    func data(from image: CGImage, quality: Double) -> Data? {
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
            [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
