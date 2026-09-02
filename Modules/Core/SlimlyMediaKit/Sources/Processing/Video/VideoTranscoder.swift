import AVFoundation
import Foundation
import SlimlyCore

struct VideoTranscodeSettings {
    let container: VideoContainer
    let codec: VideoCodec
    /// Ограничение короткой стороны: 1080 — это «1080p» и для вертикали,
    /// и для горизонтали. `nil` — размер кадра не трогаем.
    let shortSideLimit: Int?
    /// Доля исходного битрейта.
    let bitrateFactor: Double
}

protocol VideoTranscoding: Sendable {
    func transcode(
        source: URL,
        destination: URL,
        settings: VideoTranscodeSettings,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws
}

/// Перекодирование видео парой «reader → writer».
///
/// Не `AVAssetExportSession`: его пресеты не дают задать битрейт, а вся суть
/// сжатия — именно в нём. Здесь только сборка: разбор исходника, геометрия,
/// битрейт, входы и выходы — каждый своим воркером.
struct VideoTranscoder: VideoTranscoding {
    private let sources: any VideoSourceReading
    private let geometry: any VideoGeometryCalculating
    private let bitrates: any VideoBitrateEstimating
    private let outputs: any VideoReaderOutputMaking
    private let inputs: any VideoWriterInputMaking
    private let audioLegs: any AudioLegMaking
    private let transfer: any SampleTransferring

    init(
        sources: any VideoSourceReading = VideoSourceReader(),
        geometry: any VideoGeometryCalculating = VideoGeometryCalculator(),
        bitrates: any VideoBitrateEstimating = VideoBitrateEstimator(),
        outputs: any VideoReaderOutputMaking = VideoReaderOutputFactory(),
        inputs: any VideoWriterInputMaking = VideoWriterInputFactory(),
        audioLegs: any AudioLegMaking = AudioLegFactory(),
        transfer: any SampleTransferring = SampleTransfer()
    ) {
        self.sources = sources
        self.geometry = geometry
        self.bitrates = bitrates
        self.outputs = outputs
        self.inputs = inputs
        self.audioLegs = audioLegs
        self.transfer = transfer
    }

    func transcode(
        source: URL,
        destination: URL,
        settings: VideoTranscodeSettings,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        let info = try await sources.read(at: source)

        let frame = geometry.geometry(
            naturalSize: info.naturalSize,
            transform: info.transform,
            shortSideLimit: settings.shortSideLimit
        )
        let bitrate = bitrates.bitrate(
            source: source,
            dataRate: info.dataRate,
            seconds: info.duration.seconds,
            factor: settings.bitrateFactor
        )

        let reader = try AVAssetReader(asset: info.asset)
        let writer = try AVAssetWriter(outputURL: destination, fileType: settings.container.fileType)

        let videoOutput = try outputs.makeOutput(
            for: info.track,
            reader: reader,
            geometry: frame,
            frameRate: info.frameRate,
            duration: info.duration
        )
        let videoInput = try inputs.makeInput(
            for: writer,
            settings: VideoInputSettings(
                codec: settings.codec,
                size: videoOutput.size,
                bitrate: bitrate,
                frameRate: info.frameRate,
                transform: videoOutput.needsTransform ? info.transform : .identity
            )
        )

        var legs = [TransferLeg(input: videoInput, output: videoOutput.output, reportsProgress: true)]
        if let audioLeg = try await audioLegs.makeLeg(of: info.asset, reader: reader, writer: writer) {
            legs.append(audioLeg)
        }

        try await transfer.run(
            reader: reader,
            writer: writer,
            legs: legs,
            seconds: info.duration.seconds,
            progress: progress
        )
    }
}
