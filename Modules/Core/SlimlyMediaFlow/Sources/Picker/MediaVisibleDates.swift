import SwiftUI

/// Отрезок дат, попавших в кадр.
///
/// Медиатека отсортирована от свежих файлов к старым, поэтому крайние плитки
/// экрана и задают границы: всё, что между ними, снято внутри отрезка.
struct MediaDateSpan: Equatable {
    private(set) var earliest: Date
    private(set) var latest: Date

    init(_ date: Date) {
        earliest = date
        latest = date
    }

    mutating func formUnion(_ other: Self) {
        earliest = min(earliest, other.earliest)
        latest = max(latest, other.latest)
    }
}

/// Полоса списка, в которой плитку видно: от низа прилипшей шапки до низа
/// скролла. Меряется в системе координат самого скролла — она стоит на месте,
/// пока содержимое едет мимо, поэтому границы окна от прокрутки не зависят.
struct MediaScrollWindow: Equatable {
    static let space = "mediaPicker"

    var top: CGFloat = 0
    var bottom: CGFloat = 0

    /// Плитку считаем видимой и по краю: иначе на границе строки дата
    /// менялась бы раньше, чем сама картинка уедет за шапку.
    ///
    /// Пока окно не измерено, видимых плиток нет: без этого первая же
    /// прокрутка сообщила бы даты всей отрисованной сетки.
    func shows(_ frame: CGRect) -> Bool {
        bottom > top && frame.maxY > top && frame.minY < bottom
    }
}

struct MediaVisibleDatesKey: PreferenceKey {
    static let defaultValue: MediaDateSpan? = nil

    static func reduce(value: inout MediaDateSpan?, nextValue: () -> MediaDateSpan?) {
        guard let next = nextValue() else { return }
        guard var span = value else {
            value = next
            return
        }

        span.formUnion(next)
        value = span
    }
}

/// Границы окна приходят из разных мест — низ шапки и высота скролла, —
/// поэтому каждое сообщает свою половину, а `reduce` собирает целое.
struct MediaScrollWindowKey: PreferenceKey {
    static let defaultValue = MediaScrollWindow()

    static func reduce(value: inout MediaScrollWindow, nextValue: () -> MediaScrollWindow) {
        let next = nextValue()
        value.top = max(value.top, next.top)
        value.bottom = max(value.bottom, next.bottom)
    }
}

extension View {
    /// Отдать наверх дату плитки, пока она в кадре.
    func reportsVisibleDate(_ date: Date?, in window: MediaScrollWindow) -> some View {
        background {
            GeometryReader { proxy in
                let frame = proxy.frame(in: .named(MediaScrollWindow.space))

                Color.clear.preference(
                    key: MediaVisibleDatesKey.self,
                    value: date.flatMap { window.shows(frame) ? MediaDateSpan($0) : nil }
                )
            }
        }
    }

    /// Верх окна — низ прилипшей шапки: под ней плиток не видно.
    func reportsWindowTop() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: MediaScrollWindowKey.self,
                    value: MediaScrollWindow(top: proxy.frame(in: .named(MediaScrollWindow.space)).maxY)
                )
            }
        }
    }

    /// Низ окна — высота списка. Модификатор вешается на сам скролл,
    /// а не на его содержимое: содержимое длиннее экрана.
    func reportsWindowBottom() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: MediaScrollWindowKey.self,
                    value: MediaScrollWindow(bottom: proxy.size.height)
                )
            }
        }
    }
}
