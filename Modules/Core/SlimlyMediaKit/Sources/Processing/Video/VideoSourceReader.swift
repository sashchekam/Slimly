import AVFoundation
import CoreGraphics
import Foundation

/// Всё, что нужно знать об исходном видео до начала перекодирования.
struct VideoSourceInfo {
    let asset: AVURLAsset
    let track: AVAssetTrack
    let duration: CMTime
    let naturalSize: CGSize
    let transform: CGAffineTransform
    /// Кадров в секунду. У файлов с нечитаемой частотой — 30: без числа
    /// не задать ни интервал ключевых кадров, ни шаг композиции.
    let frameRate: Double
    /// Битрейт исходной дорожки в битах в секунду по данным системы.
    let dataRate: Float
}

/// Разбор исходного файла: дорожка и её параметры.
protocol VideoSourceReading: Sendable {
    func read(at url: URL) async throws -> VideoSourceInfo
}

struct VideoSourceReader: VideoSourceReading {
    func read(at url: URL) async throws -> VideoSourceInfo {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw ProcessingError.noVideoTrack
        }

        let nominalFrameRate = try await track.load(.nominalFrameRate)

        return VideoSourceInfo(
            asset: asset,
            track: track,
            duration: try await asset.load(.duration),
            naturalSize: try await track.load(.naturalSize),
            transform: try await track.load(.preferredTransform),
            frameRate: nominalFrameRate > 1 ? Double(nominalFrameRate) : 30,
            dataRate: try await track.load(.estimatedDataRate)
        )
    }
}
