import AVFoundation
import Foundation

/// Через сколько отсчётов брать следующий замер громкости.
protocol WaveformSamplingStepEstimating: Sendable {
    func step(of track: AVAssetTrack, in asset: AVURLAsset, bars: Int) async -> Int
}

/// Читать час записи подряд — это сотни миллионов итераций ради
/// шестидесяти полос. Шаг подбираем так, чтобы на полосу приходилось
/// несколько десятков замеров: пик от этого практически не меняется,
/// а работа сокращается на порядки.
struct WaveformSamplingStep: WaveformSamplingStepEstimating {
    private static let samplesPerBar = 32.0

    func step(of track: AVAssetTrack, in asset: AVURLAsset, bars: Int) async -> Int {
        let seconds = (try? await asset.load(.duration).seconds) ?? 0
        let format = try? await track.load(.formatDescriptions).first
        let stream = format.flatMap { CMAudioFormatDescriptionGetStreamBasicDescription($0)?.pointee }

        let sampleRate = stream?.mSampleRate ?? 44_100
        let channels = Double(stream?.mChannelsPerFrame ?? 2)
        let total = seconds * sampleRate * max(channels, 1)

        return max(1, Int(total / (Double(bars) * Self.samplesPerBar)))
    }
}
