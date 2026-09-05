import SlimlyShortcuts
import SwiftUI
import WidgetKit

/// Один инструмент на выбор пользователя.
struct ToolWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "SlimlyTool",
            intent: SelectToolIntent.self,
            provider: ToolProvider()
        ) { entry in
            ToolWidgetView(shortcut: entry.shortcut)
        }
        .configurationDisplayName("Tool")
        .description("Opens the chosen Slimly tool with a single tap.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct ToolEntry: TimelineEntry {
    let date: Date
    let shortcut: ToolShortcut
}

struct ToolProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ToolEntry {
        ToolEntry(date: .now, shortcut: .default)
    }

    func snapshot(for configuration: SelectToolIntent, in context: Context) async -> ToolEntry {
        entry(for: configuration)
    }

    /// Ярлык не устаревает: одна запись без обновления, чтобы система не будила
    /// расширение впустую. Содержимое меняется только сменой настройки, а её
    /// WidgetKit перезапрашивает сам.
    func timeline(for configuration: SelectToolIntent, in context: Context) async -> Timeline<ToolEntry> {
        Timeline(entries: [entry(for: configuration)], policy: .never)
    }

    /// Варианты в галерее: по плитке на каждый инструмент, с готовой
    /// настройкой и своим именем. Без них система показала бы один ярлык
    /// с инструментом по умолчанию, а остальные пришлось бы искать
    /// в настройке уже поставленного виджета.
    func recommendations() -> [AppIntentRecommendation<SelectToolIntent>] {
        ToolShortcut.all.map { shortcut in
            AppIntentRecommendation(
                intent: SelectToolIntent(tool: shortcut),
                description: Text(shortcut.title)
            )
        }
    }

    /// Виджет только что поставили и ещё не настроили — показываем первый
    /// инструмент каталога, а не пустую плитку.
    private func entry(for configuration: SelectToolIntent) -> ToolEntry {
        ToolEntry(date: .now, shortcut: configuration.tool?.shortcut ?? .default)
    }
}
