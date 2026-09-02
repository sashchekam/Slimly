import Foundation

/// Замеры громкости → полосы на экране.
protocol WaveformShaping: Sendable {
    func shape(_ peaks: [Double], to count: Int) -> [Double]
}

struct WaveformShaper: WaveformShaping {
    func shape(_ peaks: [Double], to count: Int) -> [Double] {
        normalized(downsampled(peaks, to: count))
    }

    /// Пик по каждому отрезку: среднее сгладило бы речь в ровную кашу,
    /// а полосы нужны именно как рельеф.
    private func downsampled(_ peaks: [Double], to count: Int) -> [Double] {
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
    private func normalized(_ bars: [Double]) -> [Double] {
        guard let loudest = bars.max(), loudest > 0 else { return [] }
        return bars.map { $0 / loudest }
    }
}
