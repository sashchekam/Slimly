import SlimlyDesignSystem
import SlimlyShortcuts
import SwiftUI
import WidgetKit

struct ToolBoardView: View {
    @Environment(\.widgetFamily)
    private var family

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: SlimlySpacing.x3) {
            Text("Инструменты")
                .slimlyKicker()

            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(SlimlyColor.text)
        .containerBackground(for: .widget) { WidgetBackground() }
    }

    /// На среднем виджете инструменты стоят рядом иконок: карточка с подписью
    /// в такую высоту не влезает, а обрезанная подпись хуже её отсутствия.
    /// На большом места хватает на полные карточки — как на главной.
    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemLarge:
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(ToolShortcut.all) { shortcut in
                    ToolCardTile(shortcut: shortcut)
                }
            }

        default:
            HStack(spacing: 8) {
                ForEach(ToolShortcut.all) { shortcut in
                    ToolChip(shortcut: shortcut)
                }
            }
            // Ряд стоит по центру оставшейся высоты: растянутые до краёв
            // пилюли получаются вдвое выше своего содержимого и выглядят
            // пустыми.
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
}
