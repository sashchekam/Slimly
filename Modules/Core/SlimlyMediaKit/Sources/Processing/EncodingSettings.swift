import Foundation
import SlimlyCore

/// Как степень сжатия превращается в настройки кодировщиков.
///
/// Ползунок пользователь понимает как «сильнее / слабее», а кодировщику
/// нужны качество, разрешение и битрейт — перевод живёт здесь, рядом
/// с кодированием, а не в модели.
enum EncodingSettings {
    /// Качество JPEG/HEIC. Ниже 0,35 артефакты видны на глаз даже
    /// в мессенджере, поэтому шкала там и заканчивается.
    static func imageQuality(_ level: CompressionLevel) -> Double {
        interpolate(level.value, from: 0.85, to: 0.35)
    }

    /// Длинная сторона кадра. Верх шкалы — примерно 12 Мп, низ — 2 Мп:
    /// именно уменьшение кадра, а не качество, даёт основной выигрыш в весе.
    static func imageMaxPixelSize(_ level: CompressionLevel) -> Int {
        Int(interpolate(level.value, from: 4032, to: 1600).rounded())
    }

    /// Короткая сторона видео: до середины шкалы держим 1080p,
    /// дальше уходим в 720p — ровно то, что обещают подписи пресетов.
    static func videoShortSide(_ level: CompressionLevel) -> Int {
        level.value < 0.66 ? 1080 : 720
    }

    /// Доля исходного битрейта. Вес результата задаёт именно она:
    /// разрешение влияет на то, как этот битрейт выглядит, а не на объём.
    static func videoBitrateFactor(_ level: CompressionLevel) -> Double {
        level.ratio
    }

    private static func interpolate(_ value: Double, from: Double, to: Double) -> Double {
        from + (to - from) * min(max(value, 0), 1)
    }
}
