import AppIntents
import SlimlyShortcuts

/// Настройка виджета: какой инструмент он открывает.
///
/// Один настраиваемый виджет вместо пяти отдельных — так на экран можно
/// положить сразу несколько ярлыков и каждый настроить по-своему, а список
/// в галерее остаётся коротким.
struct SelectToolIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Tool"
    static let description = IntentDescription("The Slimly tool the widget opens.")

    @Parameter(title: "Tool")
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
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tool")
    static let defaultQuery = ToolQuery()

    let shortcut: ToolShortcut

    /// Система хранит в настройке виджета строку, а не значение перечисления.
    var id: String { shortcut.id.rawValue }

    var displayRepresentation: DisplayRepresentation {
        // Подписи уже переведены каталогом инструментов — здесь они данные,
        // и второй раз через каталог их пропускать не нужно.
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: shortcut.title),
            subtitle: LocalizedStringResource(stringLiteral: shortcut.subtitle)
        )
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
