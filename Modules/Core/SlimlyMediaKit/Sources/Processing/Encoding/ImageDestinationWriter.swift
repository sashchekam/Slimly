import CoreGraphics
import Foundation
import ImageIO
import SlimlyCore

/// Запись готового кадра в файл нужного формата.
protocol ImageDestinationWriting: Sendable {
    func write(
        _ image: CGImage,
        to destination: URL,
        format: ImageFormat,
        properties: [CFString: Any]
    ) throws
}

struct ImageDestinationWriter: ImageDestinationWriting {
    func write(
        _ image: CGImage,
        to destination: URL,
        format: ImageFormat,
        properties: [CFString: Any]
    ) throws {
        guard
            let output = CGImageDestinationCreateWithURL(
                destination as CFURL,
                format.utType.identifier as CFString,
                1,
                nil
            )
        else {
            throw ProcessingError.unsupportedFormat(format.displayName)
        }

        CGImageDestinationAddImage(output, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(output) else {
            throw ProcessingError.encodingFailed(format.displayName)
        }
    }
}
