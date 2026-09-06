import SlimlyCore
import SlimlyDesignSystem
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
    /// Ширина списка: по ней сетка выбирает число колонок. Приходит тем же
    /// замером, что и низ окна, — геометрия у них одна.
    var width: CGFloat = 0

    /// Плитку считаем видимой и по краю: иначе на границе строки дата
    /// менялась бы раньше, чем сама картинка уедет за шапку.
    ///
    /// Пока окно не измерено, видимых плиток нет: без этого первая же
    /// прокрутка сообщила бы даты всей отрисованной сетки.
    func shows(_ frame: CGRect) -> Bool {
        bottom > top && frame.maxY > top && frame.minY < bottom
    }
}

/// Что списку известно про свой кадр: где окно и какие даты в него попали.
///
/// Объект, а не пара `@State` у экрана: даты меняются на каждом кадре
/// прокрутки, и с состоянием во вью на каждый из них пересчитывалась бы
/// вся сетка. Наблюдение адресное — обновится только та вью, которая
/// даты читает.
@MainActor
@Observable
final class MediaScrollState {
    var window = MediaScrollWindow()
    var visibleDates: MediaDateSpan?
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
        value.width = max(value.width, next.width)
    }
}

extension View {
    /// Отдать наверх дату плитки, если она сейчас в кадре.
    func reportsVisibleDate(_ date: Date?, in window: MediaScrollWindow) -> some View {
        background {
            GeometryReader { proxy in
                let isVisible = window.shows(proxy.frame(in: .named(MediaScrollWindow.space)))

                Color.clear.preference(
                    key: MediaVisibleDatesKey.self,
                    value: date.flatMap { isVisible ? MediaDateSpan($0) : nil }
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

    /// Низ окна — высота списка, ширина окна — его ширина. Модификатор
    /// вешается на сам скролл, а не на его содержимое: содержимое длиннее
    /// экрана.
    func reportsWindowSize() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: MediaScrollWindowKey.self,
                    value: MediaScrollWindow(bottom: proxy.size.height, width: proxy.size.width)
                )
            }
        }
    }
}

/// Даты плиток, которые сейчас в кадре, — как в системной галерее.
/// Медиатека идёт от свежих файлов к старым, поэтому надпись читается
/// как «докуда долистали», и по ней видно, что листать дальше.
///
/// Отдельная вью, а не кусок экрана: только так перерисовка достаётся
/// одной надписи, а не всей сетке под ней.
struct MediaVisibleDatesLabel: View {
    let scroll: MediaScrollState

    var body: some View {
        Group {
            if let dates = scroll.visibleDates {
                Text(MediaDateFormatter.string(from: dates.earliest, to: dates.latest))
                    .font(.slimlyCaptionSmall)
                    .monospacedDigit()
                    .foregroundStyle(SlimlyColor.neutral500)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: scroll.visibleDates == nil)
    }
}
