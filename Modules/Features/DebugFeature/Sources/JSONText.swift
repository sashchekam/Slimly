import Foundation

/// Значение конфига, которое на самом деле объект.
///
/// Конфиг отдаёт всё строкой, и объект приезжает одной строкой без переносов:
/// прочитать в ней вложенность нельзя, а править её в поле — тем более.
protocol JSONTextFormatting: Sendable {
    /// Тот же объект, разложенный по строкам. `nil` — текст не разобрался
    /// или в нём вовсе не объект: раскладывать число или флаг не по чему.
    func pretty(_ text: String) -> String?

    /// Текст начинается со скобки — его писали как объект, и неразобранный
    /// текст здесь ошибка, а не «просто строка».
    func looksLikeObject(_ text: String) -> Bool
}

struct JSONText: JSONTextFormatting {
    func pretty(_ text: String) -> String? {
        guard looksLikeObject(text),
              let data = Self.straightQuotes(in: text).data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: Self.options) else {
            return nil
        }

        return String(data: pretty, encoding: .utf8)
    }

    func looksLikeObject(_ text: String) -> Bool {
        let first = text.trimmingCharacters(in: .whitespacesAndNewlines).first

        return first == "{" || first == "["
    }

    /// Ключи упорядочены: словарь порядок полей не хранит, и без сортировки
    /// одно и то же значение раскладывалось бы каждый раз по-новому.
    private static var options: JSONSerialization.WritingOptions {
        [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    }

    /// Клавиатура ставит «ёлочки» вместо кавычек, и набранный руками объект
    /// из-за них не разбирается. Правим до разбора, а не после: иначе экран
    /// ругался бы на текст, в котором с виду всё верно.
    private static func straightQuotes(in text: String) -> String {
        text.replacingOccurrences(
            of: "[\u{201C}\u{201D}\u{201E}\u{00AB}\u{00BB}]",
            with: "\"",
            options: .regularExpression
        )
    }
}
