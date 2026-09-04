/// Пара фабрик просмотра: чем показать готовый файл и чем оживить исходник
/// из медиатеки.
///
/// Ходят вместе: экраны просмотра общие у всех инструментов, и раздавать
/// эти фабрики по одной значило бы носить обе через каждый резолвер
/// отдельными параметрами.
public struct MediaViewers {
    public let file: MediaFileViewerFactory
    public let player: MediaItemPlayerFactory

    public init(
        file: @escaping MediaFileViewerFactory,
        player: @escaping MediaItemPlayerFactory
    ) {
        self.file = file
        self.player = player
    }
}
