import SwiftUI

/// Переход при смене корня слоя: тур → приложение, логаут → вход.
///
/// Корень меняется, когда меняется «мир», и показывать это подменой кадра
/// нельзя — переход должен читаться как уход, а не как перерисовка. Движение
/// то же, что у системного push, только целым экраном: новый приезжает справа,
/// старый уводится влево с отставанием и уходит в тень.
///
/// Отставание обязательно: без него два экрана едут одной плитой, и глаз
/// не понимает, какой из них новый.
struct RootSlideTransition: Transition {
    /// Доля ширины, на которую уходящий экран отстаёт от приходящего.
    /// Столько же отыгрывает UIKit на своём push.
    private static let parallax: CGFloat = 0.28

    func body(content: Content, phase: TransitionPhase) -> some View {
        // Сдвиг считаем до `visualEffect`: в замыкание должно попасть готовое
        // число, а не фаза перехода — оно уходит на другой поток отрисовки.
        let shift = Self.shift(for: phase)
        let isLeaving = phase == .didDisappear
        let isArriving = phase == .willAppear

        return content
            // Уходящий не растворяется, а темнеет: прозрачный экран показал бы
            // сквозь себя пустоту слева от приходящего.
            .brightness(isLeaving ? -0.14 : 0)
            // Тень под ведущим краем отделяет приходящий экран от уходящего —
            // без неё два тёмных кадра сливаются в один.
            .shadow(color: .black.opacity(isArriving ? 0.5 : 0), radius: 20, x: -10)
            .visualEffect { effect, proxy in
                effect.offset(x: shift * proxy.size.width)
            }
    }

    private static func shift(for phase: TransitionPhase) -> CGFloat {
        switch phase {
        case .willAppear: 1
        case .identity: 0
        case .didDisappear: -parallax
        }
    }
}

extension Animation {
    /// Ход смены корня: длинный и без пружины на конце. Едет целый экран,
    /// а не элемент внутри него, и отскок на такой массе читается как сбой.
    static let rootChange = Animation.spring(response: 0.52, dampingFraction: 0.95)
}
