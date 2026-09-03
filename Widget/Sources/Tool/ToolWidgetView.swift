import SlimlyDesignSystem
import SlimlyShortcuts
import SwiftUI
import WidgetKit

struct ToolWidgetView: View {
    @Environment(\.widgetFamily)
    private var family

    let shortcut: ToolShortcut

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        default: tile
        }
    }

    /// Мелкий виджет — карточка хаба, растянутая на плитку: та же иконка,
    /// то же имя, та же подпись, чтобы ярлык узнавался с первого взгляда.
    private var tile: some View {
        VStack(alignment: .leading, spacing: 0) {
            SlimlyIcon(shortcut.icon, width: 26)
                .foregroundStyle(SlimlyColor.neutral300)

            Spacer(minLength: SlimlySpacing.x4)

            Text(shortcut.title)
                .font(.slimlySectionTitle)
                .fixedSize(horizontal: false, vertical: true)

            Text(shortcut.subtitle)
                .font(.slimlyCaptionSmall)
                .foregroundStyle(SlimlyColor.neutral500)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(SlimlyColor.text)
        .containerBackground(for: .widget) { WidgetBackground() }
        .widgetURL(shortcut.url)
    }

    /// На экране блокировки цвет задаёт система — от Nocturne здесь остаётся
    /// только форма иконки.
    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            SlimlyIcon(shortcut.icon, width: 22)
        }
        .containerBackground(.clear, for: .widget)
        .widgetURL(shortcut.url)
    }
}
