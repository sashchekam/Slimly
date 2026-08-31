import SwiftUI
import SlimlyCore
import SlimlyDesignSystem

/// Плитка файла в сетке выбора.
struct MediaTile: View {
    let item: MediaItem
    let isSelected: Bool
    let thumbnail: MediaThumbnailLoader
    var showsSize = true

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                MediaThumbnail(item: item, pointSize: 140, load: thumbnail, placeholder: .tile)
            }
            .overlay(alignment: .bottomLeading) {
                // У фото без веса подписи не остаётся вовсе — пустая плашка
                // на кадре выглядела бы обрезком интерфейса.
                if !caption.isEmpty {
                    Text(caption)
                        .font(.slimlyNano)
                        .foregroundStyle(SlimlyColor.neutral300)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(SlimlyColor.tileCaption, in: RoundedRectangle(cornerRadius: SlimlyRadius.sm))
                        .padding(5)
                }
            }
            .overlay {
                if isSelected {
                    SlimlyColor.accentTint(15)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.tile, style: .continuous))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: SlimlyRadius.tile, style: .continuous)
                        .strokeBorder(SlimlyColor.accent, lineWidth: 2)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    SlimlyIcon(.check, width: 11)
                        .foregroundStyle(SlimlyColor.onAccent)
                        .frame(width: 19, height: 19)
                        .background(SlimlyColor.accent, in: Circle())
                        .padding(5)
                }
            }
            // Миниатюра растянута по `scaledToFill`, поэтому вертикальный кадр
            // вылезает за пределы квадрата вверх и вниз. `clipShape` прячет его
            // визуально, но не в хит-тесте: без явной формы соседняя плитка
            // ниже (она выше по z-порядку) перехватывает тап и долгое нажатие.
            .contentShape(RoundedRectangle(cornerRadius: SlimlyRadius.tile, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(caption.isEmpty ? item.fileName : "\(item.fileName), \(caption)")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var caption: String {
        MediaItemFormatter.meta(item, showsSize: showsSize)
    }
}

/// Превью плитки для контекстного меню: кадр целиком и подпись с параметрами
/// файла. В сетке кадр обрезан до квадрата, поэтому по ней не всегда понятно,
/// тот ли это файл, — долгое нажатие показывает исходные пропорции до выбора.
/// Ролик и живое фото здесь играют: по одному кадру их не отличить друг
/// от друга, а выбирают именно по движению.
struct MediaTilePreview: View {
    let item: MediaItem
    let thumbnail: MediaThumbnailLoader
    var showsSize = true
    /// Без фабрики превью остаётся картиночным — снимку этого и достаточно.
    var player: MediaItemPlayerFactory?

    /// Систему интересуют пропорции превью, а не пункты: платтер меню всё
    /// равно масштабирует его под свою ширину.
    private let width: CGFloat = 280

    /// Высота по кадру, но в разумных пределах: панорама и вертикальное видео
    /// иначе вырождаются в полоску или занимают весь экран.
    private var height: CGFloat {
        guard item.pixelWidth > 0, item.pixelHeight > 0 else { return width }
        let ratio = CGFloat(item.pixelHeight) / CGFloat(item.pixelWidth)
        return min(max(width * ratio, 180), 360)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Кадр под плеером — не заглушка на время, а честный первый
                // кадр: ролик из iCloud система отдаёт с задержкой, и до
                // этого момента превью не должно быть пустым.
                MediaThumbnail(item: item, pointSize: 700, load: thumbnail, placeholder: .thumbnail)

                if let player, let view = player(item) {
                    view
                }
            }
            .frame(width: width, height: height)
            .clipped()

            VStack(alignment: .leading, spacing: 3) {
                Text(item.fileName)
                    .font(.slimlyBodySmall)
                    .foregroundStyle(SlimlyColor.text)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(caption)
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral500)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(width: width, alignment: .leading)
        }
        .background(SlimlyColor.surface)
    }

    /// «ФОТО · 4032 × 3024 · 3,1 МБ» — пустые части выпадают, если система
    /// не сообщила размер кадра или инструменту не нужен вес.
    private var caption: String {
        [
            MediaItemFormatter.kindLabel(item),
            item.pixelSizeText,
            MediaItemFormatter.meta(item, showsSize: showsSize),
        ]
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }
}
