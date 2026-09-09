#if DEBUG
import DebugFeatureInterface
import SlimlyNavigation
import SwiftUI
import UIKit

/// Вход в отладочное меню поверх всего приложения: невидимый приёмник тряски.
///
/// Лежит над `RouterHost`, а не в шапке экрана: подмены действуют везде,
/// и попасть в меню нужно с любого места, включая шаг внутри флоу.
struct DebugAccessOverlay: View {
    let container: AppContainer

    var body: some View {
        ShakeReporter { container.openDebugMenu() }
            .frame(width: 0, height: 0)
            // Тряска — жест без визуального отклика: пока меню выезжает, удар
            // подтверждает, что система жест распознала, а не приложение зависло.
            .sensoryFeedback(trigger: isMenuPresented) { _, isPresented in
                isPresented ? .impact(weight: .medium) : nil
            }
    }

    private var isMenuPresented: Bool {
        container.router.fullScreenCover?.unwrap(as: DebugRoute.self) == .menu
    }
}

/// Приёмник тряски.
///
/// SwiftUI о событиях движения не знает: система шлёт их первому респондеру,
/// а respond-цепочка — это UIKit. Поэтому в иерархию встаёт вью нулевого
/// размера, которая забирает фокус на себя. Полей ввода в приложении нет,
/// так что отнимать фокус не у кого.
struct ShakeReporter: UIViewRepresentable {
    let onShake: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = ShakeView()
        view.onShake = onShake
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView as? ShakeView)?.onShake = onShake
    }

    private final class ShakeView: UIView {
        var onShake: (() -> Void)?

        private var isWatchingKeyboard = false

        override var canBecomeFirstResponder: Bool { true }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            becomeFirstResponder()
            watchKeyboard()
        }

        /// Поле ввода забирает фокус себе — например, подмена значения конфига
        /// в отладочном меню. Вернуть его система обязана не всегда, а без
        /// фокуса тряска перестаёт открывать меню до перезапуска.
        private func watchKeyboard() {
            guard !isWatchingKeyboard else { return }
            isWatchingKeyboard = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardDidHide),
                name: UIResponder.keyboardDidHideNotification,
                object: nil
            )
        }

        @objc
        private func keyboardDidHide() {
            becomeFirstResponder()
        }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            guard motion == .motionShake else {
                super.motionEnded(motion, with: event)
                return
            }
            onShake?()
        }
    }
}
#endif
