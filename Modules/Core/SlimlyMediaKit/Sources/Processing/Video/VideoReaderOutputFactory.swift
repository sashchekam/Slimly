import AVFoundation
import CoreGraphics
import Foundation

/// Выход читателя видео и то, что о нём нужно знать писателю.
struct VideoReaderOutput {
    let output: AVAssetReaderOutput
    let size: CGSize
    /// Кадры от композиции приезжают уже развёрнутыми, а от дорожки —
    /// как сняты: поворот в этом случае несёт контейнер.
    let needsTransform: Bool
}

protocol VideoReaderOutputMaking: Sendable {
    /// Готовый выход, уже добавленный в читателя.
    func makeOutput(
        for track: AVAssetTrack,
        reader: AVAssetReader,
        geometry: VideoGeometry,
        frameRate: Double,
        duration: CMTime
    ) throws -> VideoReaderOutput
}

/// Основной путь — композиция: только она умеет и развернуть кадр
/// по EXIF-повороту, и уменьшить его. Если ассет композицию не принимает
/// (бывает с необычными дорожками), откатываемся к чтению как есть —
/// без уменьшения, но с рабочим результатом.
struct VideoReaderOutputFactory: VideoReaderOutputMaking {
    private let geometry: any VideoGeometryCalculating

    /// Формат кадра, в котором читаем видео: 4:2:0 — то, что кодировщик
    /// принимает без лишней конвертации.
    private var pixelSettings: [String: Any] {
        [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
    }

    init(geometry: any VideoGeometryCalculating = VideoGeometryCalculator()) {
        self.geometry = geometry
    }

    func makeOutput(
        for track: AVAssetTrack,
        reader: AVAssetReader,
        geometry frame: VideoGeometry,
        frameRate: Double,
        duration: CMTime
    ) throws -> VideoReaderOutput {
        let compositionOutput = AVAssetReaderVideoCompositionOutput(
            videoTracks: [track],
            videoSettings: pixelSettings
        )
        compositionOutput.videoComposition = composition(
            for: track,
            geometry: frame,
            frameRate: frameRate,
            duration: duration
        )
        compositionOutput.alwaysCopiesSampleData = false

        if reader.canAdd(compositionOutput) {
            reader.add(compositionOutput)
            return VideoReaderOutput(output: compositionOutput, size: frame.renderSize, needsTransform: false)
        }

        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: pixelSettings)
        trackOutput.alwaysCopiesSampleData = false
        guard reader.canAdd(trackOutput) else { throw ProcessingError.unreadableSource }
        reader.add(trackOutput)

        return VideoReaderOutput(
            output: trackOutput,
            size: geometry.evenSize(frame.naturalSize),
            needsTransform: true
        )
    }

    private func composition(
        for track: AVAssetTrack,
        geometry frame: VideoGeometry,
        frameRate: Double,
        duration: CMTime
    ) -> AVMutableVideoComposition {
        let composition = AVMutableVideoComposition()
        composition.renderSize = frame.renderSize
        composition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(max(1, frameRate.rounded())))

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)

        let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        // После поворота кадр может стоять где угодно относительно начала
        // координат — у файлов из мессенджеров это обычное дело. Сдвигаем
        // его в угол сами, иначе часть картинки уедет за рамку и станет
        // чёрной полосой.
        let normalize = CGAffineTransform(translationX: -frame.displayRect.minX, y: -frame.displayRect.minY)
        layer.setTransform(
            frame.transform
                .concatenating(normalize)
                .concatenating(CGAffineTransform(scaleX: frame.scale, y: frame.scale)),
            at: .zero
        )

        instruction.layerInstructions = [layer]
        composition.instructions = [instruction]
        return composition
    }
}
