import AVFoundation
import Foundation
import SlimlyCore

/// Извлечение звуковой дорожки в отдельный файл.
protocol AudioExtracting: Sendable {
    func extract(
        source: URL,
        destination: URL,
        format: AudioFormat,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws
}

struct AudioExtractor: AudioExtracting {
    private let layouts: any AudioLayoutReading
    private let transfer: any SampleTransferring

    init(
        layouts: any AudioLayoutReading = AudioLayoutReader(),
        transfer: any SampleTransferring = SampleTransfer()
    ) {
        self.layouts = layouts
        self.transfer = transfer
    }

    func extract(
        source: URL,
        destination: URL,
        format: AudioFormat,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        let asset = AVURLAsset(url: source)
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else {
            throw ProcessingError.noAudioTrack
        }

        let duration = try await asset.load(.duration)
        let layout = try await layouts.layout(of: track)

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: layout.readerSettings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { throw ProcessingError.unreadableSource }
        reader.add(output)

        let writer = try AVAssetWriter(outputURL: destination, fileType: format.fileType)
        let input = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: layout.encoderSettings(format: format)
        )
        input.expectsMediaDataInRealTime = false
        guard writer.canAdd(input) else {
            throw ProcessingError.unsupportedFormat(format.displayName)
        }
        writer.add(input)

        try await transfer.run(
            reader: reader,
            writer: writer,
            legs: [TransferLeg(input: input, output: output, reportsProgress: true)],
            seconds: duration.seconds,
            progress: progress
        )
    }
}
