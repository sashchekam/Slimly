import Foundation
import SlimlyCore

/// Как степень сжатия превращается в настройки кодировщиков.
///
/// Ползунок пользователь понимает как «сильнее / слабее», а кодировщику
/// нужны качество, разрешение и битрейт — перевод живёт здесь, рядом
/// с кодированием, а не в модели.
protocol CompressionSettingsProviding: Sendable {
    func imageQuality(_ level: CompressionLevel) -> Double
    func imageMaxPixelSize(_ level: CompressionLevel) -> Int
    func imagePaletteColors(_ level: CompressionLevel) -> Int
    func videoShortSide(_ level: CompressionLevel) -> Int
    func videoBitrateFactor(_ level: CompressionLevel) -> Double
}

struct EncodingSettings: CompressionSettingsProviding {
    /// Качество JPEG/HEIC. Ниже 0,35 артефакты видны на глаз даже
    /// в мессенджере, поэтому шкала там и заканчивается.
    func imageQuality(_ level: CompressionLevel) -> Double {
        interpolate(level.value, from: 0.85, to: 0.35)
    }

    /// Длинная сторона кадра. Верх шкалы — примерно 12 Мп, низ — 2 Мп:
    /// именно уменьшение кадра, а не качество, даёт основной выигрыш в весе.
    func imageMaxPixelSize(_ level: CompressionLevel) -> Int {
        Int(interpolate(level.value, from: 4032, to: 1600).rounded())
    }

    /// Длина палитры PNG. У формата без потерь качество не работает, и вес
    /// задаёт именно она: 256 цветов плоская графика переживает без единого
    /// изменения, а 64 заметны только на плавных переходах.
    func imagePaletteColors(_ level: CompressionLevel) -> Int {
        Int(interpolate(level.value, from: 256, to: 64).rounded())
    }

    /// Короткая сторона видео: до середины шкалы держим 1080p,
    /// дальше уходим в 720p — ровно то, что обещают подписи пресетов.
    func videoShortSide(_ level: CompressionLevel) -> Int {
        level.value < 0.66 ? 1080 : 720
    }

    /// Доля исходного битрейта. Вес результата задаёт именно она:
    /// разрешение влияет на то, как этот битрейт выглядит, а не на объём.
    func videoBitrateFactor(_ level: CompressionLevel) -> Double {
        level.ratio
    }

    private func interpolate(_ value: Double, from: Double, to: Double) -> Double {
        from + (to - from) * min(max(value, 0), 1)
    }
}
