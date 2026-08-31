import Foundation

/// Как обрабатываем страницу перед сборкой в PDF.
///
/// Это не «фильтр для красоты»: от режима зависит читаемость текста.
/// Скан договора и скан чека с печатью — разные задачи, и одним режимом
/// их не закрыть.
public enum ScanMode: String, Sendable, Hashable, CaseIterable, Identifiable {
    /// Цвет сохраняем — нужен печатям, подписям и иллюстрациям.
    case color
    /// Оттенки серого: текст читается так же, а лишний цвет не отвлекает.
    case grayscale
    /// Чистая двухцветная страница — самый контрастный вариант.
    case blackAndWhite

    public var id: String { rawValue }

    /// Подпись в списке форматов. Короткая: «PDF» повторяется во всех трёх
    /// вариантах, и длинные хвосты превратили бы выбор в стену текста.
    public var displayName: String {
        switch self {
        case .color: "цвет"
        case .grayscale: "серый"
        case .blackAndWhite: "ч/б"
        }
    }
}
