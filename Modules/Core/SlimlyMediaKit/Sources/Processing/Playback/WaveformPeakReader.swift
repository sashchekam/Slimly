import AVFoundation
import Foundation

/// Замеры громкости в порядке чтения дорожки.
protocol WaveformPeakReading: Sendable {
    /// Модуль каждого `step`-го отсчёта, 0…1.
    func peaks(from output: AVAssetReaderTrackOutput, every step: Int) -> [Double]
}

struct WaveformPeakReader: WaveformPeakReading {
    func peaks(from output: AVAssetReaderTrackOutput, every step: Int) -> [Double] {
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
}
