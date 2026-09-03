// Собирает реестр событий аналитики из модульных реализаций `FeatureAnalytics`.
//
//   swift Tools/AnalyticsRegistry.swift            # переписать ANALYTICS.md
//   swift Tools/AnalyticsRegistry.swift --check    # проверить, что он свежий
//
// Источник правды — код: имена событий живут в аналитике модуля, а таблица
// собирается из них. Поэтому ANALYTICS.md руками не правят: следующий запуск
// всё равно перепишет файл.
//
// Скрипт не входит ни в один таргет: Tuist собирает только `App/Sources/**`
// и `Modules/**`.

import Foundation

// MARK: - Модель

struct Event {
    let scope: String
    /// Короткое имя — то, что стоит в `track("...")`.
    let name: String
    let parameters: [String]
    let summary: String

    var fullName: String { "\(scope)_\(name)" }
}

struct Catalog {
    let scope: String
    let file: String
    let events: [Event]
}

// MARK: - Разбор Swift

/// Строка в кавычках и первый значащий символ после неё. По этому символу
/// имя параметра (`"count":`) отличается от имени события (`"picked",`).
struct Quoted {
    let value: String
    let next: Character?
}

func quoted(in text: String) -> [Quoted] {
    var result: [Quoted] = []
    let characters = Array(text)
    var index = 0

    while index < characters.count {
        guard characters[index] == "\"" else {
            index += 1
            continue
        }

        var value = ""
        index += 1
        while index < characters.count, characters[index] != "\"" {
            value.append(characters[index])
            index += 1
        }
        index += 1

        var next = index
        while next < characters.count, characters[next].isWhitespace {
            next += 1
        }
        result.append(Quoted(value: value, next: next < characters.count ? characters[next] : nil))
    }

    return result
}

/// Текст вызова целиком: словарь параметров часто переносят на другие строки,
/// и по одной строке его не собрать.
func call(in lines: [String], from index: Int) -> String? {
    guard let start = lines[index].range(of: "track(") else { return nil }

    var text = ""
    var depth = 0
    var opened = false
    var line = index

    while line < lines.count {
        let piece = line == index ? String(lines[index][start.lowerBound...]) : lines[line]
        for character in piece {
            text.append(character)
            if character == "(" {
                depth += 1
                opened = true
            }
            if character == ")" {
                depth -= 1
            }
            if opened, depth == 0 {
                return text
            }
        }
        text.append(" ")
        line += 1
    }

    return nil
}

/// Первое предложение документации метода: в таблице нужна одна строка,
/// а в коде у события обычно развёрнутый комментарий про «почему».
func summary(of documentation: [String]) -> String {
    let text = documentation.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    guard !text.isEmpty else { return "—" }
    // Вертикальная черта развалила бы строку таблицы на две ячейки.
    let escaped = text.replacingOccurrences(of: "|", with: "\\|")
    guard let stop = escaped.range(of: ". ") else { return escaped }
    return String(escaped[..<stop.lowerBound]) + "."
}

func scope(in text: String) -> String? {
    for line in text.components(separatedBy: .newlines) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("static let scope"), trimmed.contains("=") else { continue }
        return quoted(in: trimmed).first?.value
    }
    return nil
}

func catalog(inFile path: String, named relative: String) -> Catalog? {
    guard
        let text = try? String(contentsOfFile: path, encoding: .utf8),
        text.contains("FeatureAnalytics"),
        let scope = scope(in: text)
    else { return nil }

    let lines = text.components(separatedBy: .newlines)
    var events: [Event] = []
    var documentation: [String] = []
    var pending = "—"
    var index = 0

    while index < lines.count {
        let line = lines[index].trimmingCharacters(in: .whitespaces)
        defer { index += 1 }

        if line.hasPrefix("///") {
            documentation.append(String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces))
            continue
        }

        // Документация относится к ближайшему методу под собой; всё остальное
        // её сбрасывает, иначе комментарий уехал бы к чужому событию.
        if line.contains("func ") {
            pending = summary(of: documentation)
        }
        if !line.isEmpty {
            documentation = []
        }

        // Комментарии пропускаем целиком: в документации `FeatureAnalytics`
        // лежит пример с `track(...)`, и он не событие.
        guard !line.hasPrefix("//"), line.contains("track("), let text = call(in: lines, from: index) else {
            continue
        }

        let tokens = quoted(in: text)
        guard let name = tokens.first?.value else { continue }

        events.append(
            Event(
                scope: scope,
                name: name,
                parameters: tokens.dropFirst().filter { $0.next == ":" }.map(\.value).sorted(),
                summary: pending
            )
        )
    }

    guard !events.isEmpty else { return nil }
    return Catalog(scope: scope, file: relative, events: events.sorted { $0.name < $1.name })
}

// MARK: - Проверки

/// Ограничения Firebase: имя длиннее сорока символов или с посторонним
/// символом событие не отбрасывает с ошибкой, а молча теряет.
func problems(in catalogs: [Catalog]) -> [String] {
    var problems: [String] = []
    var seen: [String: String] = [:]

    func valid(_ name: String) -> Bool {
        guard let first = name.first, first.isLetter, first.isASCII else { return false }
        return name.allSatisfy { $0.isASCII && ($0.isLetter && $0.isLowercase || $0.isNumber || $0 == "_") }
    }

    for catalog in catalogs {
        for event in catalog.events {
            if let other = seen[event.fullName] {
                problems.append("событие \(event.fullName) объявлено дважды: \(other) и \(catalog.file)")
            }
            seen[event.fullName] = catalog.file

            if event.fullName.count > 40 {
                problems.append("имя \(event.fullName) длиннее 40 символов (\(catalog.file))")
            }
            if !valid(event.fullName) {
                problems.append("имя \(event.fullName) не из строчной латиницы, цифр и подчёркиваний (\(catalog.file))")
            }
            if event.parameters.count > 25 {
                problems.append("у \(event.fullName) больше 25 параметров (\(catalog.file))")
            }
            for parameter in event.parameters where !valid(parameter) || parameter.count > 40 {
                problems.append("параметр \(parameter) события \(event.fullName) Firebase не примет (\(catalog.file))")
            }
        }
    }

    return problems.sorted()
}

// MARK: - Разметка

func markdown(for catalogs: [Catalog]) -> String {
    var text = """
    # События аналитики

    <!-- Файл собран автоматически: `swift Tools/AnalyticsRegistry.swift`.
         Руками не правят — источник правды в коде. -->

    Имя события целиком — это префикс модуля плюс имя из `track(...)`.
    Как завести новое, описано в скилле `analytics-event`.


    """

    for catalog in catalogs {
        text += "## \(catalog.scope) · `\(catalog.file)`\n\n"
        text += "| Событие | Параметры | Что значит |\n| --- | --- | --- |\n"
        for event in catalog.events {
            let parameters = event.parameters.isEmpty
                ? "—"
                : event.parameters.map { "`\($0)`" }.joined(separator: ", ")
            text += "| `\(event.fullName)` | \(parameters) | \(event.summary) |\n"
        }
        text += "\n"
    }

    return text
}

// MARK: - Запуск

let arguments = Array(CommandLine.arguments.dropFirst())
let isCheck = arguments.contains("--check")
let root = arguments.first { !$0.hasPrefix("--") } ?? FileManager.default.currentDirectoryPath
let registry = "\(root)/ANALYTICS.md"

func swiftFiles(under directory: String) -> [String] {
    guard let walker = FileManager.default.enumerator(atPath: "\(root)/\(directory)") else { return [] }
    return walker
        .compactMap { $0 as? String }
        .filter { $0.hasSuffix(".swift") }
        .map { "\(directory)/\($0)" }
}

let sources = (swiftFiles(under: "App/Sources") + swiftFiles(under: "Modules")).sorted()
let catalogs = sources
    .compactMap { catalog(inFile: "\(root)/\($0)", named: $0) }
    .sorted { $0.scope < $1.scope }

let found = problems(in: catalogs)
guard found.isEmpty else {
    for problem in found {
        FileHandle.standardError.write(Data("error: \(problem)\n".utf8))
    }
    exit(1)
}

let text = markdown(for: catalogs)
let current = try? String(contentsOfFile: registry, encoding: .utf8)

if isCheck {
    guard current == text else {
        let message = "ANALYTICS.md устарел — выполни: swift Tools/AnalyticsRegistry.swift"
        FileHandle.standardError.write(Data("error: \(message)\n".utf8))
        exit(1)
    }
    print("ANALYTICS.md актуален: событий — \(catalogs.reduce(0) { $0 + $1.events.count })")
} else {
    try text.write(toFile: registry, atomically: true, encoding: .utf8)
    print("ANALYTICS.md собран: событий — \(catalogs.reduce(0) { $0 + $1.events.count })")
}
