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
        // Кадр лежит именно оверлеем: `scaledToFill` сообщает размер больше
        // предложенного, и в `ZStack` этот размер стал бы размером всей вью —
        // кадр вылезал бы за плитку и перехватывал нажатия у соседей.
        // Оверлей на размер не влияет, а `clipped` убирает свес и из хит-теста.
        placeholder
            .overlay {
                if let image {
                    image
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .task(id: item.id) {
                guard image == nil else { return }
                guard let data = await load(item, pointSize), let decoded = UIImage(data: data) else { return }
                image = Image(uiImage: decoded)
            }
    }
}
