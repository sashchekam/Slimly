import SwiftUI
import SlimlyCore
import SlimlyDesignSystem

/// Строка файла в списке: превью, имя, что с ним стало, и опциональная дельта.
/// Одна и та же в предпросмотре конвертации и в итоге обработки.
struct MediaFileRow: View {
    let item: MediaItem
    let name: String
    let detail: String
    let thumbnail: MediaThumbnailLoader
    var delta: String?
    var showsComparison = false

    var body: some View {
        HStack(spacing: 12) {
            MediaThumbnail(item: item, pointSize: 33, load: thumbnail)
                .frame(width: 33, height: 33)
                .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.thumbnail, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.slimlyBodySmall)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(detail)
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral500)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let delta {
                SlimlyDeltaBadge(delta)
            }

            if showsComparison {
                SlimlyIcon(.eye, width: 17)
                    .foregroundStyle(SlimlyColor.neutral500)
            }
        }
        .slimlyRow()
        .accessibilityElement(children: .combine)
    }
}
