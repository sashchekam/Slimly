import AppIntents
import SlimlyShortcuts

/// Настройка виджета: какой инструмент он открывает.
///
/// Один настраиваемый виджет вместо пяти отдельных — так на экран можно
/// положить сразу несколько ярлыков и каждый настроить по-своему, а список
/// в галерее остаётся коротким.
struct SelectToolIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Инструмент"
    static let description = IntentDescription("Инструмент Slimly, который открывает виджет.")

    @Parameter(title: "Инструмент")
    var tool: ToolEntity?

    init() { }

    /// Готовая настройка для варианта в галерее.
    init(tool: ToolShortcut) {
        self.tool = ToolEntity(shortcut: tool)
    }
}

/// Пункт списка в настройке виджета. Значения приходят из общего каталога,
/// поэтому новый инструмент появляется в списке сам.
struct ToolEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Инструмент")
    static let defaultQuery = ToolQuery()

    let shortcut: ToolShortcut

    /// Система хранит в настройке виджета строку, а не значение перечисления.
    var id: String { shortcut.id.rawValue }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(shortcut.title)", subtitle: "\(shortcut.subtitle)")
    }
}

struct ToolQuery: EntityQuery {
    func entities(for identifiers: [ToolEntity.ID]) async throws -> [ToolEntity] {
        identifiers
            .compactMap { ToolShortcut.named($0) }
            .map { ToolEntity(shortcut: $0) }
    }

    func suggestedEntities() async throws -> [ToolEntity] {
        ToolShortcut.all.map { ToolEntity(shortcut: $0) }
    }
}
