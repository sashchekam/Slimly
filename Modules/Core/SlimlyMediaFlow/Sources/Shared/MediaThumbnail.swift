import SlimlyCore
import SlimlyDesignSystem
import SwiftUI

/// Загрузчик миниатюр: кадры одного файла по мере готовности — сначала
/// грубый, следом чёткий.
///
/// Замыкание, а не сама медиатека: строке списка нужен ровно один метод,
/// и тащить ради него весь протокол в каждую ViewModel незачем.
public typealias MediaThumbnailLoader = @Sendable (MediaItem, Int) -> AsyncStream<Data>

public extension MediaLibrary {
    var thumbnailLoader: MediaThumbnailLoader {
        { [self] item, size in thumbnails(for: item, size: size) }
    }
}

public extension AsyncStream where Element == Data {
    /// Чёткий кадр из потока миниатюр. Он приходит последним: всё, что
    /// до него, — черновики ради скорости, и тому, кто ждёт картинку
    /// целиком, они не нужны.
    func sharpest() async -> Data? {
        var last: Data?
        for await data in self { last = data }
        return last
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

    @State
    private var image: Image?

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
                // Кадры приходят по возрастанию качества: показываем каждый,
                // чтобы вместо заглушки сразу стояла хоть мутная картинка.
                for await data in load(item, pointSize) {
                    guard let decoded = await Self.decode(data) else { continue }
                    image = Image(uiImage: decoded)
                }
            }
    }

    /// Распаковка кадра — вне главного потока: при быстрой прокрутке
    /// плиток декодируется десяток картинок в секунду, и на главном
    /// потоке это видно как рывки.
    private nonisolated static func decode(_ data: Data) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            await UIImage(data: data)?.byPreparingForDisplay()
        }.value
    }
}
