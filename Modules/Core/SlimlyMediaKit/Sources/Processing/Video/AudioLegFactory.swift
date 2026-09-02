import AVFoundation
import Foundation
import SlimlyCore

/// Звуковая дорожка рядом с видео: её нужно перенести в результат,
/// но не трогать по существу.
protocol AudioLegMaking: Sendable {
    /// `nil` — звука в файле нет либо система не даёт его перенести:
    /// видео от этого не пропадает, поэтому это не ошибка.
    func makeLeg(
        of asset: AVAsset,
        reader: AVAssetReader,
        writer: AVAssetWriter
    ) async throws -> TransferLeg?
}

struct AudioLegFactory: AudioLegMaking {
    /// Звук не улучшаем и не раздуваем: берём битрейт исходной дорожки,
    /// но не выше 128 кбит — на видео из галереи это потолок разумного.
    private static let maxKilobits = 128
    private static let minKilobits = 64

    private let layouts: any AudioLayoutReading

    init(layouts: any AudioLayoutReading = AudioLayoutReader()) {
        self.layouts = layouts
    }

    func makeLeg(
        of asset: AVAsset,
        reader: AVAssetReader,
        writer: AVAssetWriter
    ) async throws -> TransferLeg? {
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else { return nil }

        let layout = try await layouts.layout(of: track)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: layout.readerSettings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { return nil }
        reader.add(output)

        let sourceRate = (try? await track.load(.estimatedDataRate)) ?? 0
        let kilobits = sourceRate > 1
            ? min(Self.maxKilobits, max(Self.minKilobits, Int(sourceRate / 1000)))
            : Self.maxKilobits

        let input = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: layout.encoderSettings(format: .aac(kilobits: kilobits))
        )
        input.expectsMediaDataInRealTime = false
        guard writer.canAdd(input) else { return nil }
        writer.add(input)

        return TransferLeg(input: input, output: output, reportsProgress: false)
    }
}
