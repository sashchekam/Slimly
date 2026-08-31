import Foundation
import Observation
import SlimlyCore
import SlimlyNavigation

/// Прослушивание готовой дорожки.
///
/// Общий экран просмотра дорожке не подходит: сравнивать её не с чем,
/// а кадра у неё нет — от целого экрана осталась бы одна панель плеера.
/// Поэтому дорожка приезжает шторкой поверх итога.
@MainActor
@Observable
public final class AudioPreviewSheetViewModel {
    public let result: ProcessingResult

    private let router: Router

    public init(result: ProcessingResult, router: Router) {
        self.result = result
        self.router = router
    }

    /// В заголовке — имя готового файла: именно его пользователь будет
    /// искать в «Файлах».
    public var title: String { result.outputName }

    public var url: URL? { result.outputURL }

    public func close() {
        router.dismiss()
    }
}
