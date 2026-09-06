import Foundation
import SlimlyCore

/// Аналитика общего пути обработки: доступ → выбор файлов → запуск → итог →
/// сохранение.
///
/// Живёт рядом с шагами, а не в фичах: экраны у инструментов общие, и своя
/// копия тех же событий в каждой фиче означала бы четыре описания одной
/// воронки. Инструмент едет параметром `tool` — по нему отчёт режется, а
/// воронка остаётся одна.
///
/// Своё, чего у соседа нет, каждый инструмент пишет сам: степень сжатия —
/// в `CompressAnalytics`, съёмку страниц — в `ScanAnalytics`.
public struct FlowAnalytics: FeatureAnalytics {
    public static let scope = "flow"

    public let analytics: any AnalyticsService

    private let tool: FlowTool

    public init(analytics: any AnalyticsService, tool: FlowTool) {
        self.analytics = analytics
        self.tool = tool
    }

    // MARK: Выбор файлов

    /// Система ответила на запрос доступа к медиатеке — первая развилка
    /// любого инструмента: отказ обрывает флоу на самом входе, и без этого
    /// события такой уход выглядел бы как обычный отвал с экрана выбора.
    public func didAnswerAccess(_ access: MediaAccess) {
        track("access_answered", ["tool": toolValue, "status": .text(Self.code(of: access))])
    }

    /// Файлы выбраны, инструмент пошёл к настройкам.
    public func didPickFiles(_ items: [MediaItem]) {
        track(
            "files_picked",
            [
                "tool": toolValue,
                "count": .int(items.count),
                "input_mb": Self.megabytes(items.totalByteCount),
            ]
        )
    }

    // MARK: Обработка

    /// Обработка началась — настройки приняты, дальше работает устройство.
    public func didStartRun(_ request: ProcessingRequest) {
        track(
            "run_started",
            [
                "tool": toolValue,
                "count": .int(request.items.count),
                "format": .text(Self.code(of: request.targetFormat?.target)),
                "input_mb": Self.megabytes(request.originalByteCount),
            ]
        )
    }

    /// Обработка дошла до конца. Вес «до» и «после» отправляем парой:
    /// по ним видно и выигрыш сжатия, и то, что конвертация иногда
    /// утяжеляет файл.
    public func didFinishRun(_ outcome: ProcessingOutcome, duration: Duration) {
        track(
            "run_finished",
            [
                "tool": toolValue,
                "count": .int(outcome.results.count),
                "failed": .int(outcome.failures.count),
                "duration_ms": .int(Int(duration.seconds * 1000)),
                "input_mb": Self.megabytes(outcome.results.originalByteCount),
                "output_mb": Self.megabytes(outcome.results.outputByteCount),
            ]
        )
    }

    /// С экрана обработки ушли, не дождавшись конца: уход рвёт поток, и
    /// готовых файлов после него не остаётся. Процент говорит, терпения
    /// не хватило или что-то встало.
    public func didCancelRun(percent: Int) {
        track("run_cancelled", ["tool": toolValue, "percent": .int(percent)])
    }

    // MARK: Итог

    /// Готовые файлы сохранены — ради этого затевался весь флоу.
    ///
    /// Здесь же ставится свойство «дошёл до файла»: делить аудиторию
    /// на попробовавших и оставшихся на первом экране нужно ровно по этому
    /// моменту, и разносить его с событием было бы негде забыть.
    public func didSaveResults(_ outcome: ProcessingOutcome) {
        analytics.set(.hasSavedResult, to: "true")
        track(
            "result_saved",
            [
                "tool": toolValue,
                "count": .int(outcome.results.count),
                "destination": .text(Self.code(of: outcome.results.first?.destination)),
                "output_mb": Self.megabytes(outcome.results.outputByteCount),
            ]
        )
    }

    /// Часть файлов сохранить не удалось. Отдельным событием, а не полем
    /// в успехе: обработка прошла, а до диска файлы не дошли — это разные
    /// поломки и чинятся они в разных местах.
    public func didFailSaving(_ count: Int) {
        track("save_failed", ["tool": toolValue, "count": .int(count)])
    }

    /// Открыли просмотр готового файла — результату не поверили на слово.
    public func didPreviewResult() {
        track("result_previewed", ["tool": toolValue])
    }

    /// Готовому файлу поменяли имя. Событие редкое по замыслу: если имя
    /// правят часто, значит, автоматическое имя людям не подходит.
    public func didRenameResult() {
        track("result_renamed", ["tool": toolValue])
    }

    /// Из итога ушли в «Файлы» — сохранённый файл ещё нужно найти,
    /// и подписи под списком для этого не хватило.
    ///
    /// Событие живёт рядом с сохранением не случайно: рядом с ним видно,
    /// какую долю сохранений человек не считает законченным делом.
    public func didOpenFilesApp() {
        track("files_app_opened", ["tool": toolValue])
    }

    /// Оригиналы удалены после сохранения: место освобождено по-настоящему,
    /// а не «сжато и оставлено рядом».
    public func didDeleteOriginals(_ count: Int) {
        track("originals_deleted", ["tool": toolValue, "count": .int(count)])
    }

    // MARK: Свойства пользователя

    /// Доступ к медиатеке как срез: с ограниченным доступом человек видит
    /// не свою галерею, а отобранное однажды, и его поведение сравнивать
    /// с остальными нельзя.
    public func setAccess(_ access: MediaAccess) {
        analytics.set(.mediaAccess, to: Self.code(of: access))
    }

    // MARK: Значения

    private var toolValue: AnalyticsValue { .text(tool.rawValue) }

    /// Формат результата коротким кодом, а не подписью из интерфейса:
    /// в `displayName` живут точки-разделители и русские слова, а отчёт
    /// режется по значению целиком.
    private static func code(of target: ProcessingTarget?) -> String {
        switch target {
        // У сжатия формат не меняется — цели нет, и писать в отчёт нечего.
        case .none: "original"
        case let .image(format): format.rawValue
        case let .video(container, codec): "\(container.rawValue)_\(codec.rawValue)"
        case let .audio(.aac(kilobits)): "aac_\(kilobits)"
        case .audio(.linearPCM): "wav"
        case let .document(mode): "pdf_\(code(of: mode))"
        }
    }

    private static func code(of mode: ScanMode) -> String {
        switch mode {
        case .color: "color"
        case .grayscale: "grayscale"
        case .blackAndWhite: "bw"
        }
    }

    private static func code(of access: MediaAccess) -> String {
        switch access {
        case .notDetermined: "not_determined"
        case .denied: "denied"
        case .limited: "limited"
        case .authorized: "authorized"
        }
    }

    private static func code(of destination: OutputDestination?) -> String {
        switch destination {
        case .photoLibrary, .none: "photo_library"
        case .files: "files"
        }
    }

    /// Байты в мегабайты с одним знаком: в отчёте нужны сравнимые величины,
    /// а точное число байт всё равно никто не читает.
    private static func megabytes(_ bytes: Int64) -> AnalyticsValue {
        .double((Double(bytes) / 1_048_576 * 10).rounded() / 10)
    }
}

public extension AnalyticsUserProperty {
    /// Доступ к медиатеке: `authorized`, `limited`, `denied`.
    static var mediaAccess: AnalyticsUserProperty { AnalyticsUserProperty("media_access") }

    /// Человек хоть раз сохранил готовый файл.
    static var hasSavedResult: AnalyticsUserProperty { AnalyticsUserProperty("has_saved_result") }
}
