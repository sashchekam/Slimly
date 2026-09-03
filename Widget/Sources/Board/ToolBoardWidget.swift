import SwiftUI
import WidgetKit

/// Полка инструментов: все ярлыки сразу, каждый открывает свой.
///
/// Настройки у виджета нет — список берётся из каталога целиком, и настраивать
/// в нём нечего.
struct ToolBoardWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SlimlyToolBoard", provider: ToolBoardProvider()) { _ in
            ToolBoardView()
        }
        .configurationDisplayName("Инструменты")
        .description("Все инструменты Slimly под рукой.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

/// Содержимое полки не зависит ни от времени, ни от данных приложения,
/// поэтому провайдер отдаёт одну запись и больше о себе не напоминает.
struct ToolBoardProvider: TimelineProvider {
    func placeholder(in context: Context) -> ToolBoardEntry {
        ToolBoardEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (ToolBoardEntry) -> Void) {
        completion(ToolBoardEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ToolBoardEntry>) -> Void) {
        completion(Timeline(entries: [ToolBoardEntry(date: .now)], policy: .never))
    }
}

struct ToolBoardEntry: TimelineEntry {
    let date: Date
}
