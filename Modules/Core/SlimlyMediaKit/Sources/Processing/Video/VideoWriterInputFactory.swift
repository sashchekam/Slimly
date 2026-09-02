import AVFoundation
import CoreGraphics
import Foundation
import SlimlyCore

/// Настройки входа писателя: то, с чем кодировщик получает кадры.
struct VideoInputSettings {
    let codec: VideoCodec
    let size: CGSize
    /// Битов в секунду.
    let bitrate: Int
    let frameRate: Double
    /// Поворот, который несёт контейнер. Для кадров, развёрнутых
    /// композицией, — `.identity`.
    let transform: CGAffineTransform
}

protocol VideoWriterInputMaking: Sendable {
    /// Готовый вход, уже добавленный в писателя.
    func makeInput(for writer: AVAssetWriter, settings: VideoInputSettings) throws -> AVAssetWriterInput
}

struct VideoWriterInputFactory: VideoWriterInputMaking {
    func makeInput(for writer: AVAssetWriter, settings: VideoInputSettings) throws -> AVAssetWriterInput {
        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: settings.codec.avCodec,
                AVVideoWidthKey: Int(settings.size.width),
                AVVideoHeightKey: Int(settings.size.height),
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: settings.bitrate,
                    AVVideoExpectedSourceFrameRateKey: Int(settings.frameRate.rounded()),
                    // Ключевой кадр раз в две секунды — как в системном экспорте:
                    // перемотка остаётся быстрой, а вес почти не растёт.
                    AVVideoMaxKeyFrameIntervalKey: Int((settings.frameRate * 2).rounded()),
                ],
            ]
        )
        input.expectsMediaDataInRealTime = false
        input.transform = settings.transform

        guard writer.canAdd(input) else {
            throw ProcessingError.unsupportedFormat(settings.codec.displayName)
        }
        writer.add(input)
        return input
    }
}
