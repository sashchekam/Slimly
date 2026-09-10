import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

@MainActor
@Observable
public final class OutcomeViewModel {
    /// Итог меняется на месте: сохранение переписывает ссылки на файлы,
    /// а то, что сохранить не удалось, переезжает в список отказов.
    public private(set) var outcome: ProcessingOutcome
    /// Что пошло не так при удалении оригиналов. Системный запрос можно
    /// и отклонить — тогда это не ошибка, но сказать об этом нужно.
    public private(set) var deletionMessage: String?
    public private(set) var isDeleting = false
    public private(set) var isSaving = false
    public private(set) var isSaved = false
    /// Подтверждение сохранения. Живёт пару секунд: где искать файлы,
    /// написано и в подписи под списком — тост только отмечает момент.
    public private(set) var toast: String?
    /// Пора просить оценку: система показывает своё окно, а экран лишь
    /// говорит, что момент настал. Флаг гаснет сразу после показа —
    /// второй раз за экран просить нечего.
    public private(set) var isAskingReview = false
    /// Файл, которому прямо сейчас меняют имя. Ввод идёт в системном алерте:
    /// заводить своё поле ради одной правки на экране незачем.
    public private(set) var renamedID: String?

    /// Новое имя, пока его набирают. Без расширения: формат правкой имени
    /// не меняют, и «.png», стёртое случайно, сломало бы файл.
    public var nameDraft = ""

    private let library: any MediaLibrary
    private let service: any MediaProcessingService
    private let filesApp: any FilesAppLinking
    private let review: any ReviewPrompting
    private let analytics: FlowAnalytics
    private let router: Router
    /// Просмотр результата — не обязательная часть флоу: маршрут приходит
    /// опциональным, и без него нет ни перехода по строке, ни подсказки
    /// под списком.
    private let preview: ((ProcessingResult) -> FlowDestination)?

    @ObservationIgnored
    private var toastTask: Task<Void, Never>?

    @ObservationIgnored
    private var reviewTask: Task<Void, Never>?

    public init(
        outcome: ProcessingOutcome,
        library: any MediaLibrary,
        service: any MediaProcessingService,
        filesApp: any FilesAppLinking = FilesAppLink(),
        review: any ReviewPrompting = NoReviewPrompt(),
        analytics: FlowAnalytics,
        router: Router,
        preview: ((ProcessingResult) -> FlowDestination)? = nil
    ) {
        self.outcome = outcome
        self.library = library
        self.service = service
        self.filesApp = filesApp
        self.review = review
        self.analytics = analytics
        self.router = router
        self.preview = preview
    }

    public var results: [ProcessingResult] { outcome.results }

    public var failures: [ProcessingFailure] { outcome.failures }

    public var thumbnails: MediaThumbnailLoader { library.thumbnailLoader }

    // MARK: Заголовок

    public var kicker: String {
        outcome.isEmpty
            ? L10n.Outcome.nothing
            : FlowCopy.doneKicker(outcome.kind)
    }

    /// У сжатия итог — это вес, у остальных — формат: показываем ту пару,
    /// ради которой всё затевалось.
    public var showsSizeHeadline: Bool { outcome.kind == .compression }

    public var beforeText: String {
        FileSizeFormatter.string(bytes: results.originalByteCount)
    }

    public var afterText: String {
        FileSizeFormatter.string(bytes: results.outputByteCount)
    }

    public var sourceFormat: String { outcome.request.sourceFormat }

    public var targetFormat: String { outcome.request.targetFormat?.id ?? "" }

    public var summary: String {
        guard !outcome.isEmpty else {
            return L10n.Outcome.allFailed
        }
        return FlowCopy.summary(outcome)
    }

    /// В список отказов попадает и то, что не обработалось, и то, что
    /// не сохранилось, — поэтому в заголовке нет ни того ни другого слова.
    public var failureSummary: String? {
        guard !failures.isEmpty else { return nil }
        let files = CountFormatter.string(failures.count, .file)
        return L10n.Outcome.failed(files)
    }

    // MARK: Список файлов

    public func name(for result: ProcessingResult) -> String { result.outputName }

    public func detail(for result: ProcessingResult) -> String {
        switch outcome.kind {
        case .compression:
            MediaItemFormatter.sizeTransition(
                from: result.item.byteCount,
                to: result.outputByteCount
            )
        case .audioExtraction:
            L10n.Outcome.trackSize(FileSizeFormatter.string(bytes: result.outputByteCount))
        case .conversion, .scan:
            "\(sourceFormat) → \(outcome.request.targetFormat?.shortName ?? "")"
        }
    }

    public func delta(for result: ProcessingResult) -> String {
        outcome.kind == .compression
            ? MediaItemFormatter.reduction(result)
            : (outcome.request.targetFormat?.shortName ?? "")
    }

    public var allowsPreview: Bool { preview != nil }

    public func canPreview(_ result: ProcessingResult) -> Bool {
        allowsPreview && result.outputURL != nil
    }

    public var previewHint: String? {
        guard allowsPreview, !results.isEmpty else { return nil }
        return FlowCopy.previewHint(outcome.kind)
    }

    // MARK: Имя файла

    /// Пока файл не сохранён, имя — это просто строчка в кэше, и менять её
    /// свободно. После сохранения копия уже разложена по месту: там имя
    /// правят «Файлы», а в медиатеке его и не видно.
    public var canRename: Bool { !isSaved && !isSaving }

    /// Алерт правки. Закрыть его может и система — нажатием мимо кнопок,
    /// поэтому закрытие снимает правку, а не только кнопка «Отмена».
    public var isRenaming: Bool {
        get { renamedID != nil }
        set {
            guard !newValue else { return }
            renamedID = nil
        }
    }

    /// Чем кончится имя, что бы ни набрали в поле. `nil` — расширения нет,
    /// и обещать в подсказке нечего.
    public var renameNote: String? {
        let ext = renamedResult.map { ($0.outputName as NSString).pathExtension } ?? ""
        guard !ext.isEmpty else { return nil }

        return L10n.Rename.note(".\(ext)")
    }

    public func rename(_ result: ProcessingResult) {
        guard canRename else { return }

        renamedID = result.id
        nameDraft = (result.outputName as NSString).deletingPathExtension
    }

    public func applyRename() {
        guard let target = renamedResult, canRename else { return }
        renamedID = nil

        let ext = (target.outputName as NSString).pathExtension
        guard
            let name = Self.fileName(from: nameDraft, extension: ext),
            name != target.outputName
        else {
            return
        }

        Task {
            do {
                let renamed = try await service.rename(target, to: name)
                outcome = outcome.replacing(renamed)
                analytics.didRenameResult()
            } catch {
                say(L10n.Rename.failed)
            }
        }
    }

    private var renamedResult: ProcessingResult? {
        results.first { $0.id == renamedID }
    }

    /// Набранное превращаем в имя файла: разделители пути и точки по краям
    /// увели бы файл из своей папки или спрятали бы его от системы, а длину
    /// ограничиваем, потому что дальше имя всё равно обрежется в интерфейсе.
    /// `nil` — набрано пустое: тогда имя остаётся прежним.
    private static func fileName(from draft: String, extension ext: String) -> String? {
        let base = draft
            .components(separatedBy: CharacterSet(charactersIn: "/\\:").union(.controlCharacters))
            .joined(separator: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: ".").union(.whitespacesAndNewlines))
        guard !base.isEmpty else { return nil }

        let clipped = String(base.prefix(60))
        return ext.isEmpty ? clipped : "\(clipped).\(ext)"
    }

    // MARK: Шаринг

    /// Отдаём в системную шторку копию из кэша, а не ассет медиатеки:
    /// файл на диске делится как файл — с именем и весом, — а идентификатор
    /// ассета за пределами приложения ничего не значит.
    public func shareURL(for result: ProcessingResult) -> URL? { result.outputURL }

    public var shareURLs: [URL] { results.compactMap(\.outputURL) }

    /// Общая кнопка нужна, только когда файлов больше одного: при единственном
    /// результате она повторяла бы иконку в строке.
    public var showsShareAll: Bool { shareURLs.count > 1 }

    public var shareAllTitle: String {
        L10n.Outcome.shareAll(shareURLs.count)
    }

    // MARK: Сохранение

    /// Куда уедут файлы. Внутри одного заказа место всегда одно: у сжатия
    /// и конвертации — медиатека, у дорожек и сканов — «Файлы».
    public var destination: OutputDestination {
        results.first?.destination ?? .photoLibrary
    }

    /// Кнопка живёт до первого успеха: второй раз она сохранила бы вторую
    /// копию, а выключенная с надписью «Сохранено» осталась бы на экране
    /// мёртвой. После сохранения её место занимает «Готово».
    public var showsSaveButton: Bool { !results.isEmpty && !isSaved }

    /// Подпись под списком, наоборот, никуда не уходит: до сохранения она
    /// предупреждает, после — остаётся единственным местом, где написано,
    /// куда легли файлы, когда тост погаснет.
    public var showsSaveNote: Bool { !results.isEmpty }

    public var saveTitle: String {
        switch destination {
        case .photoLibrary: L10n.Save.gallery
        case .files: L10n.Save.files
        }
    }

    /// Подпись у кнопки. До сохранения важнее предупредить, после —
    /// сказать, где искать файлы.
    public var saveNote: String {
        guard isSaved else {
            return L10n.Save.hint
        }

        switch destination {
        case .photoLibrary: return L10n.Save.galleryDone
        case .files: return L10n.Save.filesFolder
        }
    }

    /// Сохранение — отдельное действие человека, а не хвост обработки:
    /// до нажатия ни один готовый файл наружу не выходит.
    public func save() {
        guard !isSaving, !isSaved, !results.isEmpty else { return }
        isSaving = true

        let requested = results.count

        Task {
            let stored = await service.save(outcome)
            outcome = stored
            isSaving = false

            guard !stored.results.isEmpty else {
                analytics.didFailSaving(requested)
                say(L10n.Save.failed)
                return
            }

            isSaved = true
            analytics.didSaveResults(stored)

            let lost = requested - stored.results.count
            guard lost == 0 else {
                analytics.didFailSaving(lost)
                say(L10n.Save.partial)
                return
            }

            say(savedTitle)
            // Оценку просим только после сохранения целиком: после потери
            // части файлов вопрос «нравится ли приложение» звучит издёвкой.
            askForReview()
        }
    }

    /// Куда именно легли файлы — в тосте это главное: подтверждение без места
    /// ничем не отличалось бы от «готово».
    private var savedTitle: String {
        switch destination {
        case .photoLibrary: L10n.Save.galleryDone
        case .files: L10n.Save.filesDone
        }
    }

    // MARK: Оценка

    /// Просьба оценить приходит после сохранения, а не вместо него: окно
    /// системы накрывает экран, и появиться оно должно тогда, когда тост
    /// уже подтвердил то, ради чего человек сюда шёл. Отсюда пауза —
    /// и её отмена на выходе: спрашивать про сохранение с главного экрана,
    /// куда человек уже ушёл, поздно.
    private func askForReview() {
        guard review.shouldAskAfterSave() else { return }

        reviewTask = Task {
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }

            isAskingReview = true
        }
    }

    /// Окно оценки показано. Считает показ экран, а не система: ответа
    /// она не сообщает, и другого места отметить попытку нет.
    public func didAskReview() {
        isAskingReview = false
        review.didAsk()
        analytics.didAskForReview()
    }

    /// Тост уходит сам: следующий показ отменяет прошлый отсчёт, иначе
    /// старый таймер погасил бы новое сообщение раньше срока.
    private func say(_ text: String) {
        toastTask?.cancel()
        toast = text
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    // MARK: «Файлы»

    /// Куда ведёт кнопка «Открыть в Файлах». Есть только после сохранения
    /// и только у того, что легло в папку приложения: до сохранения
    /// открывать нечего, а ушедшее в медиатеку «Файлы» не покажут.
    public var filesAppURL: URL? {
        guard isSaved, destination == .files, let file = results.first?.outputURL else { return nil }

        return filesApp.url(for: file)
    }

    /// Система ответила на попытку открыть «Файлы».
    ///
    /// Отказ — не ошибка человека, но и не событие: схема у «Файлов»
    /// недокументированная, и перестань она работать, отчёт показал бы
    /// всплеск интереса к папке вместо сломанной кнопки. Поэтому наверх
    /// уходит только удавшийся переход, а немой тап объясняет тост.
    public func didOpenFilesApp(_ opened: Bool) {
        guard opened else {
            say(L10n.Save.openFailed)
            return
        }

        analytics.didOpenFilesApp()
    }

    // MARK: Удаление оригиналов

    /// Пока результат не сохранён, оригинал — единственная копия:
    /// предлагать его удалить в этот момент нельзя.
    public var showsDeleteOriginals: Bool {
        FlowCopy.offersDeletingOriginals(outcome.kind) && !outcome.isEmpty && isSaved
    }

    public var deleteSubtitle: String {
        let size = FileSizeFormatter.string(bytes: results.originalByteCount)
        let files = CountFormatter.string(results.count, .file)
        return L10n.Outcome.deletePrompt(files, size)
    }

    // MARK: Действия

    public func finish() {
        reviewTask?.cancel()
        router.popToRoot()
    }

    public func openPreview(_ result: ProcessingResult) {
        guard let preview, canPreview(result) else { return }

        analytics.didPreviewResult()
        router.go(to: preview(result))
    }

    /// Удаление — отдельный шаг после итога, а не часть обработки:
    /// подтверждение показывает система, и до её запроса оригиналы должны
    /// быть уже заменены готовыми файлами.
    public func deleteOriginals() {
        guard !isDeleting, isSaved else { return }
        isDeleting = true
        deletionMessage = nil

        Task {
            do {
                try await library.deleteOriginals(results.map(\.item))
                isDeleting = false
                reviewTask?.cancel()
                analytics.didDeleteOriginals(results.count)
                router.popToRoot()
            } catch {
                isDeleting = false
                deletionMessage = L10n.Outcome.originalsKept
            }
        }
    }
}
