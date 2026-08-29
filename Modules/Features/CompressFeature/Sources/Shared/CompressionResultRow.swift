import SwiftUI
import SlimlyCore
import SlimlyDesignSystem

/// Строка «файл → сколько стал весить». Одинаковая в недавних сжатиях
/// на главной и в списке результата — разница только в том, откуда данные.
struct CompressionResultRow: View {
    let result: CompressionResult

    var body: some View {
        HStack(spacing: 12) {
            SlimlyStripes.thumbnail
                .frame(width: 33, height: 33)
                .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.thumbnail, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(result.item.fileName)
                    .font(.slimlyBodySmall)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(MediaItemFormatter.sizeTransition(result))
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral500)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SlimlyDeltaBadge(MediaItemFormatter.reduction(result))
        }
        .slimlyRow()
        .accessibilityElement(children: .combine)
    }
}
