import AVFoundation
import Foundation

/// Огибающая громкости готовой дорожки.
///
/// Просмотр звука без картинки — это полосы: по ним видно, где речь,
/// где пауза, и что файл вообще не пустой. Считаем по самому результату,
/// а не по исходному видео: показывать нужно то, что получилось.
enum AudioWaveform {
    /// Пики по `count` равным отрезкам, нормированные к самому громкому.
    ///
    /// Пустой массив значит «прочитать не удалось» — экран покажет это
    /// заглушкой, а не ровной линией: ровная линия читалась бы как тишина,
    /// то есть как испорченный файл.
    static func peaks(at url: URL, count: Int) async -> [Double] {
        let asset = AVURLAsset(url: url)

        guard
            let track = try? await asset.loadTracks(withMediaType: .audio).first,
            let reader = try? AVAssetReader(asset: asset)
        else { return [] }

        // Просим распакованный 16-битный PCM: у AAC отсчётов в файле нет,
        // а по сжатым кадрам громкость не измерить.
        let output = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsNonInterleaved: false,
            ]
        )

        guard reader.canAdd(output) else { return [] }
        reader.add(output)
        guard reader.startReading() else { return [] }

        let step = await samplingStep(of: track, in: asset, bars: count)
        let fine = readPeaks(from: output, every: step)
        reader.cancelReading()

        return normalized(downsample(fine, to: count))
    }

    /// Через сколько отсчётов брать следующий замер.
    ///
    /// Читать час записи подряд — это сотни миллионов итераций ради
    /// шестидесяти полос. Шаг подбираем так, чтобы на полосу приходилось
    /// несколько десятков замеров: пик от этого практически не меняется,
    /// а работа сокращается на порядки.
    private static func samplingStep(
        of track: AVAssetTrack,
        in asset: AVURLAsset,
        bars: Int
    ) async -> Int {
        let seconds = (try? await asset.load(.duration).seconds) ?? 0
        let format = try? await track.load(.formatDescriptions).first
        let stream = format.flatMap { CMAudioFormatDescriptionGetStreamBasicDescription($0)?.pointee }

        let sampleRate = stream?.mSampleRate ?? 44_100
        let channels = Double(stream?.mChannelsPerFrame ?? 2)
        let total = seconds * sampleRate * max(channels, 1)

        return max(1, Int(total / Double(bars * 32)))
    }

    /// Модуль каждого `step`-го отсчёта, в порядке чтения.
    private static func readPeaks(from output: AVAssetReaderTrackOutput, every step: Int) -> [Double] {
        var peaks: [Double] = []
        // Шаг должен идти сквозь границы буферов: считая его от начала
        // каждого буфера, мы бы сгущали замеры на стыках.
        var cursor = 0

        while let buffer = output.copyNextSampleBuffer() {
            defer { CMSampleBufferInvalidate(buffer) }

            guard
                let block = CMSampleBufferGetDataBuffer(buffer),
                CMBlockBufferGetDataLength(block) > 0
            else { continue }

            // Копируем в массив Int16, а не читаем байты на месте: так
            // выравнивание отсчётов гарантирует тип, а не удача аллокатора.
            let length = CMBlockBufferGetDataLength(block) / MemoryLayout<Int16>.size
            guard length > 0 else { continue }

            var samples = [Int16](repeating: 0, count: length)
            let copied = samples.withUnsafeMutableBytes { raw -> OSStatus in
                guard let destination = raw.baseAddress else { return kCMBlockBufferBadPointerParameterErr }
                return CMBlockBufferCopyDataBytes(
                    block,
                    atOffset: 0,
                    dataLength: raw.count,
                    destination: destination
                )
            }
            guard copied == noErr else { continue }

            var index = (step - cursor % step) % step
            while index < length {
                peaks.append(abs(Double(samples[index])) / 32_768)
                index += step
            }
            cursor += length
        }

        return peaks
    }

    /// Пик по каждому отрезку: среднее сгладило бы речь в ровную кашу,
    /// а полосы нужны именно как рельеф.
    private static func downsample(_ peaks: [Double], to count: Int) -> [Double] {
        guard !peaks.isEmpty, count > 0 else { return [] }

        let width = Double(peaks.count) / Double(count)
        return (0 ..< count).map { index in
            let start = min(Int(Double(index) * width), peaks.count - 1)
            let end = min(max(Int(Double(index + 1) * width), start + 1), peaks.count)
            return peaks[start ..< end].max() ?? 0
        }
    }

    /// Тихая запись — тоже запись: рельеф растягиваем на всю высоту,
    /// иначе диктофонная дорожка выглядела бы пустой полосой.
    private static func normalized(_ bars: [Double]) -> [Double] {
        guard let loudest = bars.max(), loudest > 0 else { return [] }
        return bars.map { $0 / loudest }
    }
}
