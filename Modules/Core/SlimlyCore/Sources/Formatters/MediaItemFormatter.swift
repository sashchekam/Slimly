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
    ///
    /// Вес нужен не везде: скану безразлично, сколько весит снимок страницы, —
    /// там это число ни на что не влияет и только шумит.
    public static func meta(_ item: MediaItem, showsSize: Bool = true) -> String {
        let size = showsSize ? FileSizeFormatter.string(bytes: item.byteCount) : ""
        guard let duration = item.duration else { return size }
        let time = DurationFormatter.string(duration)
        return size.isEmpty ? time : "\(time) · \(size)"
    }

    /// «840 МБ → 302 МБ».
    public static func sizeTransition(from: Int64, to: Int64) -> String {
        "\(FileSizeFormatter.string(bytes: from)) → \(FileSizeFormatter.string(bytes: to))"
    }

    /// «−64%».
    public static func reduction(_ result: ProcessingResult) -> String {
        percent(result.reduction)
    }

    /// Доля в процентах со знаком: «−58%», «+140%».
    public static func percent(_ fraction: Double) -> String {
        let value = Int((fraction * 100).rounded())
        return value < 0 ? "+\(-value)%" : "−\(value)%"
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

    /// Суммарная длительность: «46 мин», «2 ч 14 мин», «5 ч 02 мин».
    ///
    /// Секунд здесь нет: это итог за месяцы, и точность до секунды в нём
    /// была бы шумом. Минуты у часов дополнены нулём, чтобы столбик чисел
    /// не прыгал при смене среза.
    public static func total(seconds: Double) -> String {
        let minutes = max(0, Int((seconds / 60).rounded()))
        let hours = minutes / 60

        guard hours > 0 else { return "\(minutes) мин" }
        return String(format: "%d ч %02d мин", hours, minutes % 60)
    }

    /// «12 с», «3 мин» — грубая оценка, поэтому без долей и без секунд
    /// после минуты: точность, которой у прогноза всё равно нет.
    public static func remaining(_ duration: Duration) -> String {
        let seconds = max(1, Int(duration.components.seconds))
        guard seconds >= 60 else { return "\(seconds) с" }
        return "\(Int((Double(seconds) / 60).rounded(.up))) мин"
    }
}
