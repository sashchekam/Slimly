import SwiftUI
import WidgetKit

/// Набор виджетов Slimly.
///
/// Виджет здесь — ярлык: он ничего не считает и ни за чем не следит, а только
/// открывает инструмент по адресу `slimly://`. Поэтому их два и они про разное:
/// один инструмент крупно и настраиваемо — и вся полка инструментов сразу.
@main
struct SlimlyWidgets: WidgetBundle {
    var body: some Widget {
        ToolWidget()
        ToolBoardWidget()
    }
}
