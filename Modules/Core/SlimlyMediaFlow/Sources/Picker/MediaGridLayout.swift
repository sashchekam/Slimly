import SwiftUI

/// Раскладка сетки выбора: сколько плиток помещается в ряд.
///
/// Свойство экрана, а не настройка: колонка добавляется ровно там, где плитка
/// иначе стала бы заметно крупнее, поэтому её размер от ширины телефона почти
/// не зависит — 89 pt на самом узком экране против 84 на самом широком.
/// Выбирать тут не из чего, и настройки у сетки нет.
struct MediaGridLayout {
    /// Ниже этой ширины ряд теряет плитку: у SE и mini экран 320 и 375 pt,
    /// у остальных телефонов — 390 и шире.
    private static let narrowScreen: CGFloat = 380

    let columns: Int
    let spacing: CGFloat = 6

    /// Ширина здесь — вся ширина списка: поля экрана держит содержимое,
    /// и на выбор числа колонок они не влияют.
    init(width: CGFloat) {
        columns = width < Self.narrowScreen ? 3 : 4
    }

    var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
}
