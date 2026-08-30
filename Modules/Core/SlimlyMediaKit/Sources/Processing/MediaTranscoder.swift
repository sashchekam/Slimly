import AVFoundation
import Foundation
import SlimlyCore

/// Перекодирование видео и извлечение звука.
///
/// Не `AVAssetExportSession`: его пресеты не дают задать битрейт, а вся суть
/// сжатия — именно в нём. Пара «reader → writer» стоит дороже в коде, зато
/// это настоящее перекодирование с нужными параметрами и честным прогрессом.
enum MediaTranscoder {
    struct VideoSettings {
        let container: VideoContainer
        let codec: VideoCodec
        /// Ограничение короткой стороны: 1080 — это «1080p» и для вертикали,
        /// и для горизонтали. `nil` — размер кадра не трогаем.
        let shortSideLimit: Int?
        /// Доля исходного битрейта.
        let bitrateFactor: Double
    }

    // MARK: Видео

    static func transcodeVideo(
        source: URL,
        destination: URL,
        settings: VideoSettings,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        let asset = AVURLAsset(url: source)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw ProcessingError.noVideoTrack
        }

        let duration = try await asset.load(.duration)
        let naturalSize = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)
        let nominalFrameRate = try await track.load(.nominalFrameRate)
        let dataRate = try await track.load(.estimatedDataRate)

        let frameRate = nominalFrameRate > 1 ? Double(nominalFrameRate) : 30
        let displayRect = CGRect(origin: .zero, size: naturalSize).applying(transform)
        let scale = scale(for: displayRect.size, shortSideLimit: settings.shortSideLimit)
        let renderSize = evenSize(
            CGSize(width: displayRect.width * scale, height: displayRect.height * scale)
        )

        let sourceBitrate = Double(dataRate) > 1 ? Double(dataRate) : fallbackBitrate(
            source: source,
            seconds: duration.seconds
        )
        // Ниже 400 кбит/с картинка рассыпается независимо от разрешения.
        let bitrate = Int(max(400_000, sourceBitrate * settings.bitrateFactor))

        let reader = try AVAssetReader(asset: asset)
        let writer = try AVAssetWriter(outputURL: destination, fileType: settings.container.fileType)

        let videoOutput = try videoOutput(
            for: track,
            reader: reader,
            naturalSize: naturalSize,
            renderSize: renderSize,
            transform: transform,
            displayRect: displayRect,
            scale: scale,
            frameRate: frameRate,
            duration: duration
        )

        let videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: settings.codec.avCodec,
                AVVideoWidthKey: Int(videoOutput.size.width),
                AVVideoHeightKey: Int(videoOutput.size.height),
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: bitrate,
                    AVVideoExpectedSourceFrameRateKey: Int(frameRate.rounded()),
                    // Ключевой кадр раз в две секунды — как в системном экспорте:
                    // перемотка остаётся быстрой, а вес почти не растёт.
                    AVVideoMaxKeyFrameIntervalKey: Int((frameRate * 2).rounded()),
                ],
            ]
        )
        videoInput.expectsMediaDataInRealTime = false
        // Кадры от композиции приезжают уже развёрнутыми, а от дорожки —
        // как сняты: поворот в этом случае несёт контейнер.
        videoInput.transform = videoOutput.needsTransform ? transform : .identity
        guard writer.canAdd(videoInput) else {
            throw ProcessingError.unsupportedFormat(settings.codec.displayName)
        }
        writer.add(videoInput)

        var legs: [Transfer.Leg] = [
            Transfer.Leg(input: videoInput, output: videoOutput.output, reportsProgress: true),
        ]

        if let audioLeg = try await audioLeg(of: asset, reader: reader, writer: writer) {
            legs.append(audioLeg)
        }

        try await Transfer(
            reader: reader,
            writer: writer,
            legs: legs,
            seconds: duration.seconds,
            progress: progress
        ).run()
    }

    /// Выход читателя видео.
    ///
    /// Основной путь — композиция: только она умеет и развернуть кадр
    /// по EXIF-повороту, и уменьшить его. Если ассет композицию не принимает
    /// (бывает с необычными дорожками), откатываемся к чтению как есть —
    /// без уменьшения, но с рабочим результатом.
    private struct VideoOutput {
        let output: AVAssetReaderOutput
        let size: CGSize
        let needsTransform: Bool
    }

    private static func videoOutput(
        for track: AVAssetTrack,
        reader: AVAssetReader,
        naturalSize: CGSize,
        renderSize: CGSize,
        transform: CGAffineTransform,
        displayRect: CGRect,
        scale: CGFloat,
        frameRate: Double,
        duration: CMTime
    ) throws -> VideoOutput {
        let pixelSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
        ]

        let composition = AVMutableVideoComposition()
        composition.renderSize = renderSize
        composition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(max(1, frameRate.rounded())))

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        // После поворота кадр может стоять где угодно относительно начала
        // координат — у файлов из мессенджеров это обычное дело. Сдвигаем
        // его в угол сами, иначе часть картинки уедет за рамку и станет
        // чёрной полосой.
        let normalize = CGAffineTransform(translationX: -displayRect.minX, y: -displayRect.minY)
        layer.setTransform(
            transform
                .concatenating(normalize)
                .concatenating(CGAffineTransform(scaleX: scale, y: scale)),
            at: .zero
        )
        instruction.layerInstructions = [layer]
        composition.instructions = [instruction]

        let compositionOutput = AVAssetReaderVideoCompositionOutput(
            videoTracks: [track],
            videoSettings: pixelSettings
        )
        compositionOutput.videoComposition = composition
        compositionOutput.alwaysCopiesSampleData = false

        if reader.canAdd(compositionOutput) {
            reader.add(compositionOutput)
            return VideoOutput(output: compositionOutput, size: renderSize, needsTransform: false)
        }

        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: pixelSettings)
        trackOutput.alwaysCopiesSampleData = false
        guard reader.canAdd(trackOutput) else { throw ProcessingError.unreadableSource }
        reader.add(trackOutput)

        return VideoOutput(
            output: trackOutput,
            size: evenSize(naturalSize),
            needsTransform: true
        )
    }

    private static func audioLeg(
        of asset: AVAsset,
        reader: AVAssetReader,
        writer: AVAssetWriter
    ) async throws -> Transfer.Leg? {
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else { return nil }

        let layout = try await audioLayout(of: track)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: layout.readerSettings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { return nil }
        reader.add(output)

        // Звук не улучшаем и не раздуваем: берём битрейт исходной дорожки,
        // но не выше 128 кбит — на видео из галереи это потолок разумного.
        let sourceRate = (try? await track.load(.estimatedDataRate)) ?? 0
        let kilobits = sourceRate > 1
            ? min(128, max(64, Int(sourceRate / 1000)))
            : 128

        let input = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: layout.encoderSettings(format: .aac(kilobits: kilobits))
        )
        input.expectsMediaDataInRealTime = false
        guard writer.canAdd(input) else { return nil }
        writer.add(input)

        return Transfer.Leg(input: input, output: output, reportsProgress: false)
    }

    // MARK: Звук

    static func extractAudio(
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
        let layout = try await audioLayout(of: track)

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

        try await Transfer(
            reader: reader,
            writer: writer,
            legs: [Transfer.Leg(input: input, output: output, reportsProgress: true)],
            seconds: duration.seconds,
            progress: progress
        ).run()
    }

    /// Частота, каналы и раскладка исходной дорожки.
    ///
    /// Берём их у самого файла, а не константами: AAC-кодировщик не примет
    /// настройки, которые расходятся с тем, что ему подают. Многоканальный
    /// звук сводим в стерео — иначе кодировщику нужна раскладка, которой
    /// у бытового видео всё равно не бывает.
    private struct AudioLayout {
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

    private static func audioLayout(of track: AVAssetTrack) async throws -> AudioLayout {
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

    // MARK: Разбор исходника

    /// Кодек исходного видео — чтобы сжатие не меняло формат исподтишка.
    static func videoCodec(of source: URL) async -> VideoCodec? {
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

    // MARK: Геометрия

    private static func scale(for size: CGSize, shortSideLimit: Int?) -> CGFloat {
        guard let limit = shortSideLimit, limit > 0 else { return 1 }
        let shortSide = min(size.width, size.height)
        guard shortSide > CGFloat(limit) else { return 1 }
        return CGFloat(limit) / shortSide
    }

    /// Кодировщики требуют чётных размеров: 4:2:0 делит кадр на пары пикселей.
    private static func evenSize(_ size: CGSize) -> CGSize {
        CGSize(
            width: max(2, (size.width / 2).rounded() * 2),
            height: max(2, (size.height / 2).rounded() * 2)
        )
    }

    /// Битрейт по весу файла — на случай, если система его не сообщила.
    private static func fallbackBitrate(source: URL, seconds: Double) -> Double {
        guard seconds > 0 else { return 8_000_000 }
        let size = (try? FileManager.default.attributesOfItem(atPath: source.path)[.size] as? Int64) ?? nil
        guard let size, size > 0 else { return 8_000_000 }
        return Double(size) * 8 / seconds
    }
}

extension VideoContainer {
    var fileType: AVFileType {
        switch self {
        case .mp4: .mp4
        case .mov: .mov
        }
    }
}

extension VideoCodec {
    var avCodec: AVVideoCodecType {
        switch self {
        case .h264: .h264
        case .hevc: .hevc
        }
    }
}

extension AudioFormat {
    var fileType: AVFileType {
        switch self {
        case .aac: .m4a
        case .linearPCM: .wav
        }
    }
}
