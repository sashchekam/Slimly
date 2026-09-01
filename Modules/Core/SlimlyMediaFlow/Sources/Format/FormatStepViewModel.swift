import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

/// Правила шага «в какой формат» для конкретного инструмента.
public struct FormatStepConfig: Sendable {
    public let title: String
    public let note: String
    /// Глагол на кнопке: «Конвертировать», «Извлечь звук», «Собрать скан».
    public let actionTitle: String
    /// Формат исходников — левая половина пары «из → в».
    public let sourceFormat: String
    public let formats: [MediaFormat]
    public let noun: CountFormatter.Noun
    /// Показывать ли вес: у скана результат ценен читаемостью, а не
    /// мегабайтами, и прогноз «5 МБ → ≈ 0,1 МБ» там ничего не решает.
    public let showsSize: Bool
    /// Что именно делать с выбранным форматом. Шаг один и тот же,
    /// а работа за ним разная — поэтому её задаёт инструмент.
    public let makeOperation: @Sendable (MediaFormat) -> ProcessingOperation

    public init(
        title: String,
        note: String,
        actionTitle: String,
        sourceFormat: String,
        formats: [MediaFormat],
        noun: CountFormatter.Noun,
        showsSize: Bool = true,
        makeOperation: @escaping @Sendable (MediaFormat) -> ProcessingOperation
    ) {
        self.title = title
        self.note = note
        self.actionTitle = actionTitle
        self.sourceFormat = sourceFormat
        self.formats = formats
        self.noun = noun
        self.showsSize = showsSize
        self.makeOperation = makeOperation
    }
}

@MainActor
@Observable
public final class FormatStepViewModel {
    public let config: FormatStepConfig
    public let items: [MediaItem]
    public private(set) var selectedFormat: MediaFormat

    private let router: Router
    private let run: (ProcessingRequest) -> any Route
    private let thumbnailLoader: MediaThumbnailLoader
    /// Просмотр исходника — не обязательная часть шага: без маршрута строка
    /// списка остаётся подписью, а не кнопкой.
    private let preview: ((MediaItem) -> FlowDestination)?

    public init(
        config: FormatStepConfig,
        items: [MediaItem],
        router: Router,
        thumbnails: @escaping MediaThumbnailLoader,
        preview: ((MediaItem) -> FlowDestination)? = nil,
        run: @escaping (ProcessingRequest) -> any Route
    ) {
        self.config = config
        self.items = items
        self.router = router
        thumbnailLoader = thumbnails
        self.preview = preview
        self.run = run
        // Исходный формат из списка убираем: «сконвертировать HEIC в HEIC» —
        // не выбор, а недоразумение.
        selectedFormat = config.formats.first { $0.id != config.sourceFormat }
            ?? config.formats[0]
    }

    public var thumbnails: MediaThumbnailLoader { thumbnailLoader }

    public var formats: [MediaFormat] {
        config.formats.filter { $0.id != config.sourceFormat }
    }

    public func select(_ format: MediaFormat) {
        selectedFormat = format
    }

    public func isSelected(_ format: MediaFormat) -> Bool {
        format == selectedFormat
    }

    // MARK: Показатели

    public var summary: String {
        let count = CountFormatter.string(items.count, config.noun)
        guard config.showsSize else { return count }
        return "\(count) · \(FileSizeFormatter.string(bytes: items.totalByteCount))"
    }

    public var targetTitle: String { selectedFormat.id }

    /// Строка под именем файла: у звука это отдельная дорожка, у остальных —
    /// «было → станет». Там, где вес не показываем, остаётся размер кадра:
    /// по нему видно, что за страница, а число мегабайт — нет.
    public func detail(for item: MediaItem) -> String {
        guard config.showsSize else {
            // Размер кадра система сообщает не всегда, а пустая вторая строка
            // роняет высоту строки списка — тогда подписываем хотя бы тип.
            let size = item.pixelSizeText
            return size.isEmpty ? MediaItemFormatter.kindLabel(item) : size
        }

        let estimate = FileSizeFormatter.string(bytes: request.estimatedByteCount(for: item))

        if request.kind == .audioExtraction {
            return "дорожка ≈ \(estimate)"
        }
        return "\(FileSizeFormatter.string(bytes: item.byteCount)) → ≈ \(estimate)"
    }

    public var ctaTitle: String {
        "\(config.actionTitle) · \(CountFormatter.string(items.count, config.noun))"
    }

    // MARK: Навигация

    public var request: ProcessingRequest {
        ProcessingRequest(
            items: items,
            operation: config.makeOperation(selectedFormat),
            sourceFormat: config.sourceFormat
        )
    }

    public var allowsPreview: Bool { preview != nil }

    /// Кадр в списке — 33 пункта: по нему видно, что файл выбран, но не то,
    /// что на нём. Поэтому строка открывает оригинал целиком.
    public func openPreview(_ item: MediaItem) {
        guard let preview else { return }
        router.go(to: preview(item))
    }

    public func goBack() {
        router.pop()
    }

    public func start() {
        router.push(run(request))
    }
}
