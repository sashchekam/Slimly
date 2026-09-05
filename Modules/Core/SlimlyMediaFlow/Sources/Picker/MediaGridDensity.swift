import SlimlyDesignSystem
import SwiftUI

/// Плотность сетки выбора: сколько плиток помещается в ряд.
///
/// Значение живёт во вью, а не в модели: это привычка смотреть, а не часть
/// выбора файлов, и на то, что уйдёт в обработку, она не влияет.
enum MediaGridDensity: Int, CaseIterable, Identifiable {
    /// Меньше трёх колонок — плитки размером с карточку и медиатека
    /// пролистывается вечность, больше пяти — подпись с весом файла
    /// на кадре уже не читается.
    case large = 3
    case medium = 4
    case small = 5

    var id: Int { rawValue }

    var columns: Int { rawValue }

    var title: String { L10n.Grid.density(rawValue) }

    /// Просветы между плитками сужаются вместе с ними: на пяти колонках
    /// прежние семь пунктов съедали бы заметную часть ряда.
    var spacing: CGFloat {
        switch self {
        case .large: 7
        case .medium: 6
        case .small: 5
        }
    }

    var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
}

/// Сетка в миниатюре: столько же квадратов в ряду, сколько будет на экране.
///
/// Ширина постоянна, меняется размер квадратов — ровно то, что произойдёт
/// с плитками, поэтому подписи к выбору не нужны.
struct MediaGridPreview: View {
    let columns: Int
    let width: CGFloat

    private let rows = 2
    private let spacing: CGFloat = 1.5

    private var side: CGFloat {
        (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0 ..< rows, id: \.self) { _ in
                HStack(spacing: spacing) {
                    ForEach(0 ..< columns, id: \.self) { _ in
                        // Заливка не задана: квадраты берут цвет у вызывающей
                        // стороны, и один и тот же значок годится и кнопке,
                        // и строке выбора.
                        RoundedRectangle(cornerRadius: 1, style: .continuous)
                            .frame(width: side, height: side)
                    }
                }
            }
        }
        .frame(width: width, height: side * CGFloat(rows) + spacing)
        .accessibilityHidden(true)
    }
}

/// Шторка настройки сетки. Пока в ней одно — плотность, но это то место,
/// где появится остальное про показ файлов, а не про их выбор.
struct MediaGridSettingsSheet: View {
    /// Высота живёт рядом с вёрсткой: столько занимают ручка, заголовок
    /// и три строки выбора.
    static let height: CGFloat = 285

    @Binding
    var density: MediaGridDensity
    let onClose: () -> Void

    var body: some View {
        SlimlySheetScaffold(
            title: L10n.Picker.grid,
            closeTitle: L10n.Common.done,
            onCancel: onClose
        ) {
            SlimlyRowGroup {
                ForEach(MediaGridDensity.allCases) { option in
                    Button {
                        density = option
                    } label: {
                        row(for: option)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func row(for option: MediaGridDensity) -> some View {
        let isSelected = option == density

        return HStack(spacing: 14) {
            MediaGridPreview(columns: option.columns, width: 26)
                .foregroundStyle(isSelected ? SlimlyColor.accent : SlimlyColor.neutral500)
                .frame(width: 26)

            Text(option.title)
                .font(.slimlyBody)
                .foregroundStyle(SlimlyColor.text)

            Spacer(minLength: 0)

            if isSelected {
                SlimlyIcon(.check, width: 13)
                    .foregroundStyle(SlimlyColor.accent)
            }
        }
        .slimlyRow(vertical: 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
