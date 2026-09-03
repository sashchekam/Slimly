import Foundation

/// Привести имя события или свойства к тому, что принимает Firebase.
protocol AnalyticsNameNormalizing: Sendable {
    func normalized(_ name: String) -> String
}

/// Firebase молча выбрасывает событие с недопустимым именем: только латиница,
/// цифры и подчёркивания, не длиннее сорока символов, первый символ — буква.
/// Проверять это глазами по всем модулям не выйдет, поэтому имя чинится
/// на выходе.
struct AnalyticsNameNormalizer: AnalyticsNameNormalizing {
    private static let limit = 40
    private static let separator: Character = "_"

    func normalized(_ name: String) -> String {
        let cleaned = name.lowercased().map(Self.allowed)
        // Имя, начавшееся с цифры или подчёркивания, Firebase не примет,
        // а срезать первый символ — значит потерять смысл имени.
        let prefixed = cleaned.first?.isLetter == true ? cleaned : [Self.separator] + cleaned
        return String(prefixed.prefix(Self.limit))
    }

    private static func allowed(_ character: Character) -> Character {
        character.isASCII && (character.isLetter || character.isNumber) ? character : separator
    }
}
