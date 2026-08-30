import ObjectiveC
import SwiftUI
import UIKit

/// Возврат свайпом: системный, но по всей ширине экрана.
///
/// Задач здесь две, и обе — из-за скрытой навигационной панели.
///
/// Первая: `slimlyScreen()` прячет панель, а `UINavigationController` вместе с
/// ней выключает свой `interactivePopGestureRecognizer` — жест назад пропадает
/// на всём стеке. Возвращаем его собственным делегатом.
///
/// Вторая: системный жест ловит полоску шириной около 20 pt у левого края — на
/// большом телефоне до неё нужно тянуться через весь экран. Рядом ставим свой
/// распознаватель на всю ширину и отдаём его события **тем же** обработчикам,
/// что и у системного. Отсюда и полная идентичность поведения: экран идёт за
/// пальцем, под ним настоящий предыдущий экран с параллаксом, и бросок на
/// полпути возвращает всё назад — этот переход ведёт UIKit, а не мы.
struct BackSwipeInstaller: UIViewControllerRepresentable {
    let isDisabled: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        Installer()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? Installer)?.isSwipeDisabled = isDisabled
    }

    /// Пустой контроллер нужен только ради `navigationController` — попасть в
    /// иерархию UIKit из SwiftUI иначе нечем.
    private final class Installer: UIViewController {
        var isSwipeDisabled = false {
            didSet { applyDisabled() }
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            install()
            applyDisabled()
        }

        private func install() {
            guard let navigationController,
                  let system = navigationController.interactivePopGestureRecognizer
            else { return }

            system.delegate = BackSwipeDelegate.shared
            system.isEnabled = true

            guard let host = system.view,
                  !host.gestureRecognizers.orEmpty.contains(where: { $0 is FullWidthBackSwipe }),
                  let targets = BackSwipeDelegate.targets(of: system)
            else { return }

            let fullWidth = FullWidthBackSwipe()
            // Свой обработчик мы не пишем: жест передаёт события внутренней
            // машине перехода UIKit — той самой, что ведёт краевой свайп.
            fullWidth.setValue(targets, forKey: BackSwipeDelegate.targetsKey)
            fullWidth.delegate = BackSwipeDelegate.shared
            fullWidth.maximumNumberOfTouches = 1
            host.addGestureRecognizer(fullWidth)
        }

        private func applyDisabled() {
            guard let owner = ownerViewController else { return }
            BackSwipeDelegate.shared.setDisabled(isSwipeDisabled, for: owner)
        }

        /// Экран, внутри которого мы живём, — тот предок, что лежит в стеке
        /// навигации. Запрет вешаем на него, а не на весь стек: соседние
        /// экраны про чужой запрет знать не должны.
        private var ownerViewController: UIViewController? {
            guard let stack = navigationController?.viewControllers else { return nil }

            var candidate: UIViewController? = parent
            while let current = candidate {
                if stack.contains(current) { return current }
                candidate = current.parent
            }
            return nil
        }
    }
}

/// Маркер: по типу находим свой распознаватель среди чужих и не ставим второй.
private final class FullWidthBackSwipe: UIPanGestureRecognizer {}

/// Общий делегат обоих жестов: экраны появляются и исчезают, а делегат у
/// распознавателя слабый — экземпляр, привязанный к экрану, умер бы вместе с
/// ним и обнулил делегат, после чего жест сработал бы и на корне стека.
@MainActor
private final class BackSwipeDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = BackSwipeDelegate()

    static let targetsKey = "targets"

    /// Экраны, которые запретили возврат свайпом. Ссылки слабые: снятый со
    /// стека экран уходит из набора сам.
    private let disabled = NSHashTable<UIViewController>.weakObjects()

    func setDisabled(_ isDisabled: Bool, for viewController: UIViewController) {
        if isDisabled {
            disabled.add(viewController)
        } else {
            disabled.remove(viewController)
        }
    }

    /// Список обработчиков системного жеста. Ключ недокументирован, поэтому
    /// сначала спрашиваем у рантайма, есть ли за ним поле: если Apple его
    /// переименует, мы просто останемся с краевым свайпом вместо падения.
    static func targets(of gestureRecognizer: UIGestureRecognizer) -> Any? {
        guard class_getInstanceVariable(UIGestureRecognizer.self, "_" + targetsKey) != nil else {
            return nil
        }
        return gestureRecognizer.value(forKey: targetsKey)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController = navigationController(of: gestureRecognizer),
              // На корневом экране возвращаться некуда: разрешённый там жест
              // роняет внутреннее состояние `UINavigationController`.
              navigationController.viewControllers.count > 1,
              // Второй возврат поверх уже идущего перехода ломает стек.
              navigationController.transitionCoordinator == nil,
              let top = navigationController.topViewController,
              !disabled.contains(top)
        else { return false }

        guard let pan = gestureRecognizer as? FullWidthBackSwipe else { return true }

        // Только вправо и заметно горизонтально — иначе это прокрутка списка,
        // и трогать её мы не должны.
        let translation = pan.translation(in: pan.view)
        return translation.x > 0 && abs(translation.x) > abs(translation.y)
    }

    /// Жест живёт на `view` навигационного контроллера, до самого контроллера
    /// добираемся по цепочке респондеров.
    private func navigationController(of gestureRecognizer: UIGestureRecognizer) -> UINavigationController? {
        var responder: UIResponder? = gestureRecognizer.view
        while let current = responder {
            if let navigationController = current as? UINavigationController {
                return navigationController
            }
            responder = current.next
        }
        return nil
    }
}

private extension Optional where Wrapped == [UIGestureRecognizer] {
    var orEmpty: [UIGestureRecognizer] { self ?? [] }
}

private struct BackSwipeDisabledKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isBackSwipeDisabled: Bool {
        get { self[BackSwipeDisabledKey.self] }
        set { self[BackSwipeDisabledKey.self] = newValue }
    }
}

public extension View {
    /// Ставит в иерархию невидимый контроллер, который включает свайп-возврат.
    func interactivePopGestureEnabled() -> some View {
        modifier(BackSwipeInstallerModifier())
    }

    /// Запрещает возврат свайпом на этом экране — для тех, у кого нет и кнопки
    /// «Назад» (идёт работа, и без своего экрана она осталась бы невидимой).
    /// Применяется снаружи `slimlyScreen()`.
    func backSwipeDisabled(_ disabled: Bool = true) -> some View {
        environment(\.isBackSwipeDisabled, disabled)
    }
}

private struct BackSwipeInstallerModifier: ViewModifier {
    @Environment(\.isBackSwipeDisabled) private var isDisabled

    func body(content: Content) -> some View {
        content.background {
            BackSwipeInstaller(isDisabled: isDisabled)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
