// Собирает структуру `L10n` из строковых каталогов модулей.
//
//   swift Tools/L10nGenerator.swift            # переписать Sources/Generated/L10n.swift
//   swift Tools/L10nGenerator.swift --check    # проверить, что они свежие
//
// Источник правды — каталог: ключ вида `section.name` становится свойством
// `L10n.Section.name`, а английское значение — документирующим комментарием
// над ним. Поэтому `L10n.swift` руками не правят: следующий запуск всё равно
// перепишет файл.
//
// Зачем это вместо `String(localized:)`: тот игнорирует переданную локаль
// и не перехватывается подменой бандла, поэтому язык меняется только
// при следующем запуске. Сгенерированный `tr` ходит через
// `L10nBundle.localizedString(...)` — один funnel на модуль, который
// разворачивается на выбранный язык сразу.
//
// Скрипт не входит ни в один таргет: Tuist собирает только `App/Sources/**`,
// `Widget/Sources/**` и `Modules/**`.

import Foundation

/// Модуль, в котором живёт `L10nBundle`: остальные импортируют его ради него.
let coreModule = "SlimlyCore"

// MARK: - Модель

/// Аргумент строки: место в списке подстановок и тип, который увидит вызывающий.
struct Argument {
    /// Номер подстановки, начиная с единицы, — он же порядок в сигнатуре.
    let position: Int
    let type: String
}

/// Одна строка каталога: ключ, разобранный на раздел и имя, плюс всё,
/// что нужно для объявления.
struct Entry {
    let key: String
    let section: String
    let name: String
    /// Английское значение — оно уходит в документирующий комментарий.
    let text: String
    let arguments: [Argument]
}

/// Каталог одного модуля.
struct Catalog {
    /// Имя модуля — оно же имя фреймворка: `SlimlyCore`, `ScanFeature`.
    let module: String
    /// Папка модуля относительно корня.
    let path: String
    let entries: [Entry]

    var sections: [String] {
        Array(Set(entries.map(\.section))).sorted()
    }

    func entries(in section: String) -> [Entry] {
        entries.filter { $0.section == section }.sorted { $0.name < $1.name }
    }
}

// MARK: - Ошибки

/// Ошибка разбора с адресом: и файл, и ключ, иначе в каталоге на сотню строк
/// её не найти.
struct Failure {
    let file: String
    let key: String?
    let message: String

    var text: String {
        guard let key else { return "\(file): \(message)" }
        return "\(file): ключ «\(key)» — \(message)"
    }
}

// MARK: - Разбор ключа

/// Ключ — это ровно `section.name`, обе части в lowerCamelCase.
///
/// Два уровня, а не сколько угодно: глубже вложенные типы не пропустит
/// SwiftLint (`nesting: type_level: 2`), да и адрес из четырёх частей
/// на месте вызова уже не читается.
func parts(ofKey key: String) -> (section: String, name: String)? {
    let pieces = key.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
    guard pieces.count == 2, pieces.allSatisfy(isIdentifier) else { return nil }
    return (pieces[0], pieces[1])
}

func isIdentifier(_ piece: String) -> Bool {
    guard let first = piece.first, first.isLowercase, first.isASCII else { return false }
    return piece.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) }
}

/// Имя раздела с большой буквы: `count` → `Count`, `audioFormat` → `AudioFormat`.
func typeName(of section: String) -> String {
    section.prefix(1).uppercased() + section.dropFirst()
}

/// Слова, которые в Swift заняты: имя строки `default` без обратных кавычек
/// не скомпилируется.
let keywords: Set<String> = [
    "as", "associatedtype", "break", "case", "catch", "class", "continue", "default",
    "defer", "deinit", "do", "else", "enum", "extension", "fallthrough", "false", "for",
    "func", "guard", "if", "import", "in", "init", "inout", "internal", "is", "let", "nil",
    "operator", "private", "protocol", "public", "repeat", "rethrows", "return", "self",
    "static", "struct", "subscript", "super", "switch", "throw", "throws", "true", "try",
    "typealias", "var", "where", "while",
]

func escaped(_ name: String) -> String {
    keywords.contains(name) ? "`\(name)`" : name
}

// MARK: - Разбор каталога

/// Значение ключа на языке разработки вместе с раскрытыми подстановками.
///
/// Формы множественного числа сворачиваются к `other`: в комментарии нужен
/// пример строки, а не весь набор вариантов.
func sourceValue(_ localization: [String: Any]) -> (value: String, substitutions: [String: [String: Any]])? {
    let substitutions = localization["substitutions"] as? [String: [String: Any]] ?? [:]

    if let unit = localization["stringUnit"] as? [String: Any], let value = unit["value"] as? String {
        return (value, substitutions)
    }
    if let variations = localization["variations"] as? [String: Any], let value = plural(variations) {
        return (value, substitutions)
    }
    return nil
}

/// Вариант `other` — он есть в любом языке, в отличие от `one`, `few` и `many`.
func plural(_ variations: [String: Any]) -> String? {
    guard let plural = variations["plural"] as? [String: Any] else { return nil }
    let variant = plural["other"] ?? plural.values.first
    guard
        let variant = variant as? [String: Any],
        let unit = variant["stringUnit"] as? [String: Any]
    else { return nil }
    return unit["value"] as? String
}

/// Тип аргумента по спецификатору формата.
func type(ofSpecifier specifier: String) -> String? {
    switch specifier {
    case "@": "String"
    case "d", "i", "u", "ld", "lu", "lld", "llu": "Int"
    case "f", "lf", "e", "g": "Double"
    default: nil
    }
}

/// Разбирает значение на аргументы и заодно собирает текст для комментария.
///
/// Токен подстановки (`%#@count@`) в комментарии разворачивается в её вариант
/// `other`: `%#@count@` человеку ничего не говорит, а «files» говорит.
func scan(
    value: String,
    substitutions: [String: [String: Any]]
) -> (text: String, arguments: [Argument], problem: String?) {
    var text = ""
    var arguments: [Int: String] = [:]
    var problem: String?
    var next = 1

    let characters = Array(value)
    var index = 0

    while index < characters.count {
        guard characters[index] == "%" else {
            text.append(characters[index])
            index += 1
            continue
        }

        index += 1
        guard index < characters.count else {
            text.append("%")
            break
        }

        // `%%` — это просто процент, аргумента за ним нет.
        if characters[index] == "%" {
            text.append("%")
            index += 1
            continue
        }

        // Явный номер подстановки: `%2$@` ставит аргумент на второе место.
        var position: Int?
        var digits = ""
        var lookahead = index
        while lookahead < characters.count, characters[lookahead].isNumber {
            digits.append(characters[lookahead])
            lookahead += 1
        }
        if lookahead < characters.count, characters[lookahead] == "$", let number = Int(digits) {
            position = number
            index = lookahead + 1
        }

        // Токен подстановки: `%#@count@`.
        if index + 1 < characters.count, characters[index] == "#", characters[index + 1] == "@" {
            var name = ""
            index += 2
            while index < characters.count, characters[index] != "@" {
                name.append(characters[index])
                index += 1
            }
            index += 1

            guard let substitution = substitutions[name] else {
                problem = problem ?? "подстановка «\(name)» объявлена в значении, но не описана"
                continue
            }
            guard
                let specifier = substitution["formatSpecifier"] as? String,
                let type = type(ofSpecifier: specifier)
            else {
                problem = problem ?? "у подстановки «\(name)» нет formatSpecifier"
                continue
            }

            let number = substitution["argNum"] as? Int ?? position ?? next
            arguments[number] = type
            next = max(next, number + 1)

            if let variations = substitution["variations"] as? [String: Any], let example = plural(variations) {
                text += example
            } else {
                text += "%\(specifier)"
            }
            continue
        }

        // Обычный спецификатор: `%@`, `%lld`, `%.2f`.
        var specifier = ""
        while index < characters.count, "0123456789.-+ #'".contains(characters[index]) {
            index += 1
        }
        while index < characters.count {
            specifier.append(characters[index])
            let character = characters[index]
            index += 1
            if character.isLetter, character != "l", character != "h", character != "z" {
                break
            }
            if character == "@" {
                break
            }
        }

        guard let type = type(ofSpecifier: specifier) else {
            problem = problem ?? "спецификатор «%\(specifier)» не поддержан"
            continue
        }

        let number = position ?? next
        arguments[number] = type
        next = max(next, number + 1)
        text += "%\(specifier)"
    }

    let sorted = arguments.keys.sorted().map { Argument(position: $0, type: arguments[$0] ?? "String") }
    return (text, sorted, problem)
}

func catalog(atPath path: String, module: String, relative: String) -> (Catalog?, [Failure]) {
    guard
        let data = FileManager.default.contents(atPath: "\(path)/Resources/Localizable.xcstrings"),
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let strings = json["strings"] as? [String: Any]
    else {
        return (nil, [Failure(file: relative, key: nil, message: "каталог не читается")])
    }

    let source = json["sourceLanguage"] as? String ?? "en"
    let keys = strings.keys.sorted()
    let plain = keys.filter { parts(ofKey: $0) == nil }

    // Модуль, который ещё не переехал, пропускаем целиком: ключом у него
    // стоит английский текст, и адреса из него не собрать. А вот каталог,
    // где переехала только часть строк, — это чья-то опечатка в имени.
    guard plain.count != keys.count else { return (nil, []) }
    guard plain.isEmpty else {
        return (nil, plain.map {
            Failure(file: relative, key: $0, message: "ключ пишется как «section.name», обе части в lowerCamelCase")
        })
    }

    var entries: [Entry] = []
    var failures: [Failure] = []

    for key in keys {
        guard let parsed = parts(ofKey: key) else { continue }

        let string = strings[key] as? [String: Any] ?? [:]
        let localizations = string["localizations"] as? [String: Any] ?? [:]

        guard
            let localization = localizations[source] as? [String: Any],
            let (value, substitutions) = sourceValue(localization)
        else {
            failures.append(Failure(file: relative, key: key, message: "нет значения на языке «\(source)»"))
            continue
        }

        let scanned = scan(value: value, substitutions: substitutions)
        if let problem = scanned.problem {
            failures.append(Failure(file: relative, key: key, message: problem))
            continue
        }

        entries.append(
            Entry(
                key: key,
                section: parsed.section,
                name: parsed.name,
                text: scanned.text,
                arguments: scanned.arguments
            )
        )
    }

    guard entries.isEmpty == false else { return (nil, failures) }
    return (Catalog(module: module, path: relative, entries: entries), failures)
}

// MARK: - Разметка

/// Комментарий не длиннее строки, которую пропускает линтер: длинный текст
/// переносится по словам.
func documentation(for text: String, indent: String) -> String {
    let limit = 100 - indent.count
    var lines: [String] = []

    for paragraph in text.components(separatedBy: "\n") {
        var line = ""
        for word in paragraph.split(separator: " ", omittingEmptySubsequences: false) {
            let candidate = line.isEmpty ? String(word) : line + " " + word
            if candidate.count > limit, !line.isEmpty {
                lines.append(line)
                line = String(word)
            } else {
                line = candidate
            }
        }
        lines.append(line)
    }

    return lines.map { "\(indent)/// \($0)\n" }.joined()
}

func declaration(for entry: Entry, indent: String) -> String {
    var text = documentation(for: entry.text, indent: indent)
    let name = escaped(entry.name)

    guard !entry.arguments.isEmpty else {
        text += "\(indent)static var \(name): String {\n"
        text += "\(indent)    tr(\"\(entry.key)\")\n"
        text += "\(indent)}\n"
        return text
    }

    let parameters = entry.arguments.map { "_ p\($0.position): \($0.type)" }.joined(separator: ", ")
    let values = entry.arguments.map { "p\($0.position)" }.joined(separator: ", ")
    text += "\(indent)static func \(name)(\(parameters)) -> String {\n"
    text += "\(indent)    tr(\"\(entry.key)\", \(values))\n"
    text += "\(indent)}\n"
    return text
}

func source(for catalog: Catalog) -> String {
    var text = """
    // Файл собран автоматически: `swift Tools/L10nGenerator.swift`.
    // Руками не правят — источник правды в `Resources/Localizable.xcstrings`.

    import Foundation\n
    """

    // Сам core объявляет `L10nBundle` у себя, импортировать ему нечего.
    if catalog.module != coreModule {
        text += "import \(coreModule)\n"
    }

    text += """

    /// Строки модуля.
    ///
    /// Свойство берёт перевод на языке, который выбран сейчас, — поэтому
    /// строка читается на месте показа, а не сохраняется в поле.
    enum L10n {\n
    """

    for (index, section) in catalog.sections.enumerated() {
        if index > 0 {
            text += "\n"
        }
        text += "    enum \(typeName(of: section)) {\n"
        let declarations = catalog.entries(in: section).map { declaration(for: $0, indent: "        ") }
        text += declarations.joined(separator: "\n")
        text += "    }\n"
    }

    text += """
    }

    /// Один вход за переводом на весь модуль.
    ///
    /// `locale` обязателен: без него `String(format:)` выбирает форму слова
    /// по правилам английского, и русское «5 файлов» превращается в «5 файла».
    private func tr(_ key: String, _ arguments: CVarArg...) -> String {
        let format = L10nBundle.localizedString(forKey: key, in: .module)
        guard !arguments.isEmpty else { return format }

        return String(format: format, locale: L10nBundle.locale, arguments: arguments)
    }\n
    """

    return text
}

// MARK: - Запуск

let arguments = Array(CommandLine.arguments.dropFirst())
let isCheck = arguments.contains("--check")
let root = arguments.first { !$0.hasPrefix("--") } ?? FileManager.default.currentDirectoryPath

/// Папки, у которых есть свой строковый каталог: и модули, и цели верхнего
/// уровня вроде виджета. Раскладка у всех одна — `Sources` рядом с `Resources`.
func directories(under root: String) -> [String] {
    let manager = FileManager.default
    var found: [String] = []

    for place in ["Modules/Core", "Modules/Features", "."] {
        let base = place == "." ? root : "\(root)/\(place)"
        guard let names = try? manager.contentsOfDirectory(atPath: base) else { continue }

        for name in names.sorted() {
            let relative = place == "." ? name : "\(place)/\(name)"
            guard manager.fileExists(atPath: "\(root)/\(relative)/Resources/Localizable.xcstrings") else { continue }
            found.append(relative)
        }
    }

    return found
}

/// Имя модуля — имя папки, кроме фичи: там в одной папке и модуль фичи,
/// и её интерфейс, а каталог принадлежит фиче.
func moduleName(of relative: String) -> String {
    relative.components(separatedBy: "/").last ?? relative
}

var catalogs: [Catalog] = []
var failures: [Failure] = []

for relative in directories(under: root) {
    let (catalog, found) = catalog(
        atPath: "\(root)/\(relative)",
        module: moduleName(of: relative),
        relative: relative
    )
    failures += found
    if let catalog {
        catalogs.append(catalog)
    }
}

guard failures.isEmpty else {
    for failure in failures.sorted(by: { $0.text < $1.text }) {
        FileHandle.standardError.write(Data("error: \(failure.text)\n".utf8))
    }
    exit(1)
}

var stale: [String] = []

for catalog in catalogs {
    let file = "\(root)/\(catalog.path)/Sources/Generated/L10n.swift"
    let text = source(for: catalog)
    let current = try? String(contentsOfFile: file, encoding: .utf8)
    guard current != text else { continue }

    if isCheck {
        stale.append(catalog.path)
        continue
    }

    try FileManager.default.createDirectory(
        atPath: "\(root)/\(catalog.path)/Sources/Generated",
        withIntermediateDirectories: true
    )
    try text.write(toFile: file, atomically: true, encoding: .utf8)
}

let count = catalogs.reduce(0) { $0 + $1.entries.count }
let skipped = directories(under: root).filter { relative in
    !catalogs.contains { $0.path == relative }
}

if !skipped.isEmpty {
    print("ещё не переехали: \(skipped.joined(separator: ", "))")
}

if isCheck {
    guard stale.isEmpty else {
        let message = "L10n отстал от каталогов (\(stale.joined(separator: ", "))) — "
            + "выполни: swift Tools/L10nGenerator.swift"
        FileHandle.standardError.write(Data("error: \(message)\n".utf8))
        exit(1)
    }
    print("L10n актуален: модулей — \(catalogs.count), строк — \(count)")
} else {
    print("L10n собран: модулей — \(catalogs.count), строк — \(count)")
}
