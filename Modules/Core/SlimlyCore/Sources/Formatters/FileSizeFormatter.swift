import Foundation

/// Размеры файлов словами.
///
/// Точность падает вместе с ростом числа: гигабайты и мелкие мегабайты
/// показываем с десятой, крупные мегабайты округляем целиком — на глаз
/// «186,4 МБ» не полезнее «186 МБ», а строка длиннее.
/// Разделитель дробной части и сокращение единицы берём из локали:
/// «186,4 МБ» по-русски и «186.4 MB» по-английски.
public enum FileSizeFormatter {
    public enum Unit: Sendable {
        case automatic
        case megabytes
        case gigabytes
    }

    // Десятичные мегабайты, а не двоичные: так считают и Photos, и Настройки,
    // и Finder. С делением на 1024² тот же файл выглядел бы на 5% легче,
    // чем в системной галерее, — и пользователь решил бы, что мы врём.
    private static let bytesInMegabyte = 1_000_000.0
    private static let megabytesInGigabyte = 1000.0

    public static func string(bytes: Int64, unit: Unit = .automatic) -> String {
        let formatted = parts(bytes: bytes, unit: unit)
        return "\(formatted.value) \(formatted.unit)"
    }

    /// Число и единица по отдельности — в профиле единица набирается
    /// мельче, чем сама цифра.
    public static func parts(bytes: Int64, unit: Unit = .automatic) -> (value: String, unit: String) {
        let megabytes = Double(bytes) / bytesInMegabyte
        let usesGigabytes = switch unit {
        case .gigabytes: true
        case .megabytes: false
        case .automatic: megabytes >= megabytesInGigabyte
        }

        if usesGigabytes {
            return (
                number(megabytes / megabytesInGigabyte, fraction: 0 ... 1),
                L10n.Size.gigabyte
            )
        }
        return (
            number(megabytes, fraction: megabytes >= 100 ? 0 ... 0 : 0 ... 1),
            L10n.Size.megabyte
        )
    }

    /// Локаль берём у выбранного языка, а не системную: после ручного выбора
    /// система про него не знает, и русская строка приехала бы с точкой.
    private static func number(_ value: Double, fraction: ClosedRange<Int>) -> String {
        value.formatted(.number.precision(.fractionLength(fraction)).locale(L10nBundle.locale))
    }
}
