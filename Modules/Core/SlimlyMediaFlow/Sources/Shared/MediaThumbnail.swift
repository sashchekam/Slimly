import SwiftUI
import SlimlyCore
import SlimlyDesignSystem

/// Загрузчик миниатюр.
///
/// Замыкание, а не сама медиатека: строке списка нужен ровно один метод,
/// и тащить ради него весь протокол в каждую ViewModel незачем.
public typealias MediaThumbnailLoader = @Sendable (MediaItem, Int) async -> Data?

public extension MediaLibrary {
    var thumbnailLoader: MediaThumbnailLoader {
        { [self] item, size in await thumbnail(for: item, size: size) }
    }
}

/// Превью файла. Пока картинка едет — штриховка: она честнее серого
/// прямоугольника, потому что видно, что это заглушка, а не «не загрузилось».
struct MediaThumbnail: View {
    let item: MediaItem
    /// Подсказка загрузчику, какого размера кадр нужен, — в пунктах.
    let pointSize: Int
    let load: MediaThumbnailLoader
    var placeholder: SlimlyStripes = .thumbnail

    @State private var image: Image?

    var body: some View {
        ZStack {
            placeholder

            if let image {
                image
                    .resizable()
                    .scaledToFill()
            }
        }
        // Кадр по `scaledToFill` выходит за рамку, и вырезание его только
        // прячет: в хит-тесте он остаётся и перехватывает нажатия у соседей.
        .contentShape(Rectangle())
        .task(id: item.id) {
            guard image == nil else { return }
            guard let data = await load(item, pointSize), let decoded = UIImage(data: data) else { return }
            image = Image(uiImage: decoded)
        }
    }
}
