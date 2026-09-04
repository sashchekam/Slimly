import Foundation

/// Количества словами.
///
/// Русское число согласуется с существительным по трём формам, а инструменты
/// считают разные вещи — файлы, фото, страницы, дорожки. Поэтому форма
/// выбирается таблицей, а не «файл(ов)» в скобках.
public enum CountFormatter {
    public enum Noun: Sendable {
        case file
        case photo
        case video
        case page
        case track
        case conversion
        case scan

        /// Формы для 1, 2–4 и 5+ — в этом порядке.
        var forms: (one: String, few: String, many: String) {
            switch self {
            case .file: ("файл", "файла", "файлов")
            // «Фото» и «видео» не склоняются: одна форма на все числа.
            case .photo: ("фото", "фото", "фото")
            case .video: ("видео", "видео", "видео")
            case .page: ("страница", "страницы", "страниц")
            case .track: ("дорожка", "дорожки", "дорожек")
            case .conversion: ("конвертация", "конвертации", "конвертаций")
            case .scan: ("скан", "скана", "сканов")
            }
        }
    }

    private static let locale = Locale(identifier: "ru_RU")

    /// Крупные количества с разрядами: «12 480».
    public static func string(_ count: Int) -> String {
        count.formatted(.number.locale(locale))
    }

    /// «1 файл», «3 файла», «128 файлов».
    public static func string(_ count: Int, _ noun: Noun) -> String {
        "\(count) \(word(count, noun))"
    }

    public static func word(_ count: Int, _ noun: Noun) -> String {
        let forms = noun.forms
        let tens = abs(count) % 100
        let ones = abs(count) % 10

        if (11 ... 14).contains(tens) { return forms.many }
        switch ones {
        case 1: return forms.one
        case 2 ... 4: return forms.few
        default: return forms.many
        }
    }
}
