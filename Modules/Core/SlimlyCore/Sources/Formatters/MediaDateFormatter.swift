import Foundation

/// Даты медиатеки словами.
///
/// Промежуток пишется как в системной галерее: общая часть не повторяется —
/// «2–5 мая 2025» вместо «2 мая 2025 — 5 мая 2025». Год текущего года
/// опускаем: он ничего не уточняет, а места над сеткой мало.
public enum MediaDateFormatter {
    /// Календарь фиксирован григорианским: месяцы подписаны русскими
    /// названиями, а в календаре пользователя их может быть и тринадцать.
    /// Часовой пояс — самообновляющийся: даты снимков считаются по месту.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }()

    /// Месяцы в родительном падеже: дата всегда идёт с числом — «5 мая».
    private static let months = [
        "января", "февраля", "марта", "апреля", "мая", "июня",
        "июля", "августа", "сентября", "октября", "ноября", "декабря",
    ]

    /// Промежуток между двумя датами: «Сегодня», «5 мая», «2–5 мая 2025»,
    /// «28 апреля — 3 мая 2025», «28 декабря 2024 — 3 января 2025».
    public static func string(from earliest: Date, to latest: Date, now: Date = .now) -> String {
        let start = parts(of: earliest)
        let end = parts(of: latest)
        let currentYear = calendar.component(.year, from: now)

        guard start != end else {
            // День назван словом, только когда он вообще подписан словом:
            // «Сегодня» рядом с числом соседнего дня выглядело бы разнобоем.
            if calendar.isDateInToday(latest) { return "Сегодня" }
            if calendar.isDateInYesterday(latest) { return "Вчера" }
            return string(end, showsYear: end.year != currentYear)
        }

        let showsYear = start.year != currentYear || end.year != currentYear

        // Внутри одного месяца хватает двух чисел: «2–5 мая 2025».
        if start.year == end.year, start.month == end.month {
            return "\(start.day)–\(string(end, showsYear: showsYear))"
        }

        // Год у левой даты нужен, только если он другой.
        let head = string(start, showsYear: showsYear && start.year != end.year)
        return "\(head) — \(string(end, showsYear: showsYear))"
    }

    /// Одна дата числом и месяцем: «12 января», «12 января 2024».
    ///
    /// Без «сегодня» и «вчера»: строка идёт внутри фразы («с 12 января»),
    /// где относительное слово теряет падеж.
    public static func day(_ date: Date, now: Date = .now) -> String {
        let parts = parts(of: date)
        return string(parts, showsYear: parts.year != calendar.component(.year, from: now))
    }

    private struct Parts: Equatable {
        let day: Int
        let month: Int
        let year: Int
    }

    private static func parts(of date: Date) -> Parts {
        Parts(
            day: calendar.component(.day, from: date),
            month: calendar.component(.month, from: date),
            year: calendar.component(.year, from: date)
        )
    }

    private static func string(_ parts: Parts, showsYear: Bool) -> String {
        let month = months[parts.month - 1]
        return showsYear ? "\(parts.day) \(month) \(parts.year)" : "\(parts.day) \(month)"
    }
}
