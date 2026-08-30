#if DEBUG
import DebugFeature
import SwiftUI
import UIKit

/// Вход в отладочное меню поверх всего приложения: невидимый приёмник тряски
/// и метка DEBUG, пока включена хоть одна подмена.
///
/// Лежит над `RouterHost`, а не в шапке экрана: подмены действуют везде,
/// и попасть в меню нужно с любого места, включая шаг внутри флоу.
struct DebugAccessOverlay: View {
    let container: AppContainer

    var body: some View {
        VStack(spacing: 0) {
            if container.debugSettings.isOverridden {
                DebugStatusChip { container.openDebugMenu() }
                    .padding(.top, 7)
            }

            Spacer(minLength: 0)
        }
        .background(alignment: .top) {
            ShakeReporter { container.openDebugMenu() }
                .frame(width: 0, height: 0)
        }
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

        override var canBecomeFirstResponder: Bool { true }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
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
