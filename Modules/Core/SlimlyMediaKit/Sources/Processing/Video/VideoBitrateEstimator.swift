import Foundation

/// Битрейт результата: доля от исходного, но не ниже разумного дна.
protocol VideoBitrateEstimating: Sendable {
    /// - Parameter dataRate: битрейт исходной дорожки по данным системы.
    ///   Ноль означает, что система его не сообщила.
    func bitrate(source: URL, dataRate: Float, seconds: Double, factor: Double) -> Int
}

struct VideoBitrateEstimator: VideoBitrateEstimating {
    /// Ниже 400 кбит/с картинка рассыпается независимо от разрешения.
    private static let floor = 400_000.0
    /// Битрейт «обычного» ролика: им подменяем неизвестный, когда не выходит
    /// посчитать даже по весу файла.
    private static let unknownBitrate = 8_000_000.0

    func bitrate(source: URL, dataRate: Float, seconds: Double, factor: Double) -> Int {
        let sourceBitrate = Double(dataRate) > 1
            ? Double(dataRate)
            : fallbackBitrate(source: source, seconds: seconds)

        return Int(max(Self.floor, sourceBitrate * factor))
    }

    /// Битрейт по весу файла — на случай, если система его не сообщила.
    private func fallbackBitrate(source: URL, seconds: Double) -> Double {
        guard seconds > 0 else { return Self.unknownBitrate }
        let size = (try? FileManager.default.attributesOfItem(atPath: source.path)[.size] as? Int64)
        guard let size, size > 0 else { return Self.unknownBitrate }
        return Double(size) * 8 / seconds
    }
}
