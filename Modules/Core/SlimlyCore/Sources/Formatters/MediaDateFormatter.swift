import Foundation

/// Даты медиатеки словами.
///
/// Промежуток пишется как в системной галерее: общая часть не повторяется —
/// «2–5 мая 2025» вместо «2 мая 2025 — 5 мая 2025». Год текущего года
/// опускаем: он ничего не уточняет, а места над сеткой мало.
public enum MediaDateFormatter {
    /// Календарь и часовой пояс берём пользовательские: месяцы теперь
    /// подписывает система, и подменять календарь григорианским больше
    /// незачем — где в году тринадцать месяцев, там их и покажут.
    private static let calendar = Calendar.autoupdatingCurrent

    /// Промежуток между двумя датами: «Сегодня», «5 мая», «2–5 мая 2025»,
    /// «28 апреля — 3 мая 2025», «28 декабря 2024 — 3 января 2025».
    ///
    /// Сокращает промежуток система: где именно опустить общий месяц и как
    /// развернуть тире, в каждом языке решено по-своему.
    public static func string(from earliest: Date, to latest: Date, now: Date = .now) -> String {
        let start = min(earliest, latest)
        let end = max(earliest, latest)

        guard !calendar.isDate(start, inSameDayAs: end) else {
            // День назван словом, только когда он вообще подписан словом:
            // «Сегодня» рядом с числом соседнего дня выглядело бы разнобоем.
            if calendar.isDateInToday(end) { return L10n.Date.today }
            if calendar.isDateInYesterday(end) { return L10n.Date.yesterday }
            return day(end, now: now)
        }

        // Локаль ставим сами: месяц называет система, а язык приложения ей
        // после ручного выбора не виден.
        let style = Date.IntervalFormatStyle(locale: L10nBundle.locale).day().month(.wide)
        let showsYear = !isCurrentYear(start, now: now) || !isCurrentYear(end, now: now)
        return (start ..< end).formatted(showsYear ? style.year() : style)
    }

    /// Одна дата числом и месяцем: «12 января», «12 января 2024».
    ///
    /// Без «сегодня» и «вчера»: строка идёт внутри фразы («с 12 января»),
    /// где относительное слово теряет падеж.
    public static func day(_ date: Date, now: Date = .now) -> String {
        let style = Date.FormatStyle(locale: L10nBundle.locale).day().month(.wide)
        return date.formatted(isCurrentYear(date, now: now) ? style : style.year())
    }

    private static func isCurrentYear(_ date: Date, now: Date) -> Bool {
        calendar.component(.year, from: date) == calendar.component(.year, from: now)
    }
}
