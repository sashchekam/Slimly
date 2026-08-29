import Foundation

public enum MediaItemFormatter {
    /// Подпись на плитке галереи.
    public static func kindLabel(_ item: MediaItem) -> String {
        switch item.kind {
        case .video: "ВИДЕО"
        case .photo: item.isHEIC ? "HEIC" : "ФОТО"
        }
    }

    /// Строка под плиткой: у видео — длительность и вес, у фото — только вес.
    public static func meta(_ item: MediaItem) -> String {
        guard let duration = item.duration else {
            return FileSizeFormatter.string(bytes: item.byteCount)
        }
        return "\(DurationFormatter.string(duration)) · \(FileSizeFormatter.string(bytes: item.byteCount))"
    }

    /// «840 МБ → 302 МБ».
    public static func sizeTransition(_ result: CompressionResult) -> String {
        let before = FileSizeFormatter.string(bytes: result.item.byteCount)
        let after = FileSizeFormatter.string(bytes: result.compressedByteCount)
        return "\(before) → \(after)"
    }

    /// «−64%».
    public static func reduction(_ result: CompressionResult) -> String {
        "−\(Int((result.reduction * 100).rounded()))%"
    }
}

public enum DurationFormatter {
    /// «0:42», «2:15». Часов у роликов из медиатеки практически не бывает,
    /// но если попадутся — покажем «1:02:15».
    public static func string(_ duration: Duration) -> String {
        let totalSeconds = Int(duration.components.seconds)
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
        let hours = totalSeconds / 3600

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// «Осталось 12 с» — грубая оценка, поэтому без долей секунды.
    public static func remaining(_ duration: Duration) -> String {
        let seconds = max(1, Int(duration.components.seconds))
        return "\(seconds) с"
    }
}
