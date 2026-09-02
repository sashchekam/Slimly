import AVFoundation
import Foundation
import SlimlyCore

/// Частота, каналы и раскладка звуковой дорожки.
///
/// Берём их у самого файла, а не константами: AAC-кодировщик не примет
/// настройки, которые расходятся с тем, что ему подают. Многоканальный
/// звук сводим в стерео — иначе кодировщику нужна раскладка, которой
/// у бытового видео всё равно не бывает.
struct AudioLayout {
    let sampleRate: Double
    let channels: Int

    var readerSettings: [String: Any] {
        var settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
        ]
        if let data = channelLayoutData { settings[AVChannelLayoutKey] = data }
        return settings
    }

    func encoderSettings(format: AudioFormat) -> [String: Any] {
        switch format {
        case let .aac(kilobits):
            var settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channels,
                AVEncoderBitRateKey: kilobits * 1000,
                // Постоянный битрейт, а не переменный: на подписи
                // «128 кбит» и на оценке веса держится обещание экрана,
                // а VBR на тихой дорожке выдал бы втрое меньше.
                AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_Constant,
            ]
            if let data = channelLayoutData { settings[AVChannelLayoutKey] = data }
            return settings
        case .linearPCM:
            return readerSettings
        }
    }

    private var channelLayoutData: Data? {
        var layout = AudioChannelLayout()
        layout.mChannelLayoutTag = channels == 1
            ? kAudioChannelLayoutTag_Mono
            : kAudioChannelLayoutTag_Stereo
        return Data(bytes: &layout, count: MemoryLayout<AudioChannelLayout>.size)
    }
}

protocol AudioLayoutReading: Sendable {
    func layout(of track: AVAssetTrack) async throws -> AudioLayout
}

struct AudioLayoutReader: AudioLayoutReading {
    func layout(of track: AVAssetTrack) async throws -> AudioLayout {
        let descriptions = try await track.load(.formatDescriptions)
        guard
            let description = descriptions.first,
            let basic = CMAudioFormatDescriptionGetStreamBasicDescription(description)?.pointee
        else {
            return AudioLayout(sampleRate: 44_100, channels: 2)
        }

        return AudioLayout(
            sampleRate: basic.mSampleRate > 0 ? basic.mSampleRate : 44_100,
            channels: min(max(Int(basic.mChannelsPerFrame), 1), 2)
        )
    }
}
