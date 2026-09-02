import AVFoundation
import Foundation
import SlimlyCore

/// Кодек исходного видео — чтобы сжатие не меняло формат исподтишка.
protocol VideoCodecProbing: Sendable {
    /// `nil` — кодек не читается или не наш: вызывающая сторона решает,
    /// чем его заменить.
    func codec(of source: URL) async -> VideoCodec?
}

struct VideoCodecProbe: VideoCodecProbing {
    func codec(of source: URL) async -> VideoCodec? {
        let asset = AVURLAsset(url: source)
        guard
            let track = try? await asset.loadTracks(withMediaType: .video).first,
            let descriptions = try? await track.load(.formatDescriptions),
            let description = descriptions.first
        else { return nil }

        switch CMFormatDescriptionGetMediaSubType(description) {
        case kCMVideoCodecType_HEVC: return .hevc
        case kCMVideoCodecType_H264: return .h264
        default: return nil
        }
    }
}
