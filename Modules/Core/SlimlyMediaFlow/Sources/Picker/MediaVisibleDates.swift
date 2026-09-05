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

    /// Середина окна — та высота, на которую пользователь и смотрит.
    var center: CGFloat { (top + bottom) / 2 }

    /// Плитку считаем видимой и по краю: иначе на границе строки дата
    /// менялась бы раньше, чем сама картинка уедет за шапку.
    ///
    /// Пока окно не измерено, видимых плиток нет: без этого первая же
    /// прокрутка сообщила бы даты всей отрисованной сетки.
    func shows(_ frame: CGRect) -> Bool {
        bottom > top && frame.maxY > top && frame.minY < bottom
    }
}

/// Плитка, оказавшаяся ближе всех к середине окна.
///
/// К ней сетка возвращается, сменив плотность. Держаться за верхнюю плитку
/// нельзя: её закрывает прилипшая шапка, и «вернуть на место» означало бы
/// увести кадр под неё, а середина видна всегда.
struct MediaAnchor: Equatable {
    let id: String
    /// Насколько плитка отстоит от середины — по нему и выбирается ближайшая.
    let distance: CGFloat
}

struct MediaAnchorKey: PreferenceKey {
    static let defaultValue: MediaAnchor? = nil

    static func reduce(value: inout MediaAnchor?, nextValue: () -> MediaAnchor?) {
        guard let next = nextValue() else { return }
        guard let current = value else {
            value = next
            return
        }

        if next.distance < current.distance { value = next }
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
    /// Читается только из обработчика жеста, поэтому на перерисовку сетки
    /// не влияет, хотя и меняется на каждом кадре прокрутки.
    var anchorID: String?
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
    /// Отдать наверх дату плитки и её место в кадре.
    ///
    /// Один `GeometryReader` на плитку, а не два: геометрия у обоих замеров
    /// одна и та же, и второй проход стоил бы ровно столько же, сколько первый.
    func reportsGridPosition(id: String, date: Date?, in window: MediaScrollWindow) -> some View {
        background {
            GeometryReader { proxy in
                let frame = proxy.frame(in: .named(MediaScrollWindow.space))
                let isVisible = window.shows(frame)

                Color.clear
                    .preference(
                        key: MediaVisibleDatesKey.self,
                        value: date.flatMap { isVisible ? MediaDateSpan($0) : nil }
                    )
                    .preference(
                        key: MediaAnchorKey.self,
                        value: isVisible
                            ? MediaAnchor(id: id, distance: abs(frame.midY - window.center))
                            : nil
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
