import SlimlyDesignSystem
import SlimlyShortcuts
import SwiftUI

/// Инструмент в тесном ряду: иконка и короткое имя. Полное здесь не помещается,
/// поэтому каталог держит для таких мест отдельную подпись.
struct ToolChip: View {
    let shortcut: ToolShortcut

    var body: some View {
        Link(destination: shortcut.url) {
            VStack(spacing: 6) {
                SlimlyIcon(shortcut.icon, width: 22)
                    .foregroundStyle(SlimlyColor.neutral300)

                Text(shortcut.short)
                    .font(.slimlyNano)
                    .foregroundStyle(SlimlyColor.neutral400)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SlimlySpacing.x4)
            .background(
                SlimlyColor.surface,
                in: RoundedRectangle(cornerRadius: SlimlyRadius.tile, style: .continuous)
            )
            .slimlyElevation(.sm, cornerRadius: SlimlyRadius.tile)
        }
    }
}

/// Инструмент карточкой — тот же состав, что у плитки хаба: иконка сверху,
/// имя и подпись под ней.
struct ToolCardTile: View {
    let shortcut: ToolShortcut

    var body: some View {
        Link(destination: shortcut.url) {
            VStack(alignment: .leading, spacing: 0) {
                SlimlyIcon(shortcut.icon, width: 22)
                    .foregroundStyle(SlimlyColor.neutral300)

                Spacer(minLength: SlimlySpacing.x3)

                Text(shortcut.title)
                    .font(.slimlyBodySmall)
                    .lineLimit(1)

                Text(shortcut.subtitle)
                    .font(.slimlyNano)
                    .foregroundStyle(SlimlyColor.neutral500)
                    .lineLimit(1)
                    .padding(.top, 2)
            }
            // Высота — по макетной карточке хаба: три ряда таких карточек
            // как раз занимают большой виджет.
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
            .padding(.horizontal, SlimlySpacing.x4)
            .padding(.vertical, SlimlySpacing.x3)
            .background(
                SlimlyColor.surface,
                in: RoundedRectangle(cornerRadius: SlimlyRadius.tile, style: .continuous)
            )
            .slimlyElevation(.sm, cornerRadius: SlimlyRadius.tile)
        }
    }
}
