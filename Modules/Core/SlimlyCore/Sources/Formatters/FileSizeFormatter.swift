import Foundation

/// Размеры файлов словами.
///
/// Точность падает вместе с ростом числа: гигабайты и мелкие мегабайты
/// показываем с десятой, крупные мегабайты округляем целиком — на глаз
/// «186,4 МБ» не полезнее «186 МБ», а строка длиннее.
/// Локаль фиксирована: интерфейс русский, десятичная запятая обязательна
/// независимо от настроек устройства.
public enum FileSizeFormatter {
    public enum Unit: Sendable {
        case automatic
        case megabytes
        case gigabytes
    }

    private static let locale = Locale(identifier: "ru_RU")
    private static let bytesInMegabyte = 1024.0 * 1024
    private static let megabytesInGigabyte = 1024.0

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
            return (number(megabytes / megabytesInGigabyte, fraction: 0 ... 1), "ГБ")
        }
        return (number(megabytes, fraction: megabytes >= 100 ? 0 ... 0 : 0 ... 1), "МБ")
    }

    private static func number(_ value: Double, fraction: ClosedRange<Int>) -> String {
        value.formatted(.number.precision(.fractionLength(fraction)).locale(locale))
    }
}
