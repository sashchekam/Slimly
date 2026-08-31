import SlimlyDesignSystem
import SlimlyNavigation
import SwiftUI

struct AppRootView: View {
    /// Смещение, с которого первый экран выезжает вверх. Ход заметный —
    /// экран именно подаётся снизу, а не подрагивает на месте.
    private static let appEntryOffset: CGFloat = 130

    let container: AppContainer

    @State private var isSplashVisible = true
    /// Заставка остаётся в иерархии до конца растворения — снимаем её только
    /// после, иначе гаснуть будет уже нечему.
    @State private var isSplashMounted = true
    @State private var isAppVisible = false

    var body: some View {
        ZStack {
            // Подложка не участвует в передаче кадра: пока заставка гаснет, а
            // первый экран ещё не проявился, между ними виден фон приложения,
            // а не чёрное окно.
            SlimlyScreenBackground()

            RouterHost(router: container.router, registry: container.registry)
                .opacity(isAppVisible ? 1 : 0)
                // Экран не проявляется на месте, а подаётся снизу: движение
                // задаёт направление передачи от заставки к приложению.
                .offset(y: isAppVisible ? 0 : Self.appEntryOffset)

            #if DEBUG
            DebugAccessOverlay(container: container)
            #endif

            if isSplashMounted {
                SplashView(onFinish: hideSplash)
                    .opacity(isSplashVisible ? 1 : 0)
                    .allowsHitTesting(false)
            }
        }
        // Nocturne — тёмная система без светлого варианта, поэтому схему
        // фиксируем: иначе системные элементы приедут светлыми.
        .preferredColorScheme(.dark)
        // Мягкий удар в момент передачи: он тяжелее ударов по углам, поэтому
        // круг заканчивается не затиханием, а точкой.
        .sensoryFeedback(trigger: isSplashVisible) { _, isVisible in
            isVisible ? nil : .impact(flexibility: .soft, intensity: 0.9)
        }
    }

    /// Заставка сначала полностью уходит и только потом проявляется первый
    /// экран: одновременный кроссфейд смешал бы два кадра в мутную середину.
    ///
    /// Прозрачность анимируем на самой заставке, а не переходом при удалении:
    /// уход запускает её собственная задача, и вью снимается вместе с задачей —
    /// отыграть `.transition` SwiftUI уже не успевает.
    private func hideSplash() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isSplashVisible = false
        } completion: {
            isSplashMounted = false
        }

        // Пружина с перелётом: экран проскакивает конечную позицию и
        // возвращается — так подъём читается как живое движение, а не как
        // равномерная подача кадра по прямой.
        withAnimation(.smooth(duration: 0.55).delay(0.26)) { isAppVisible = true }
    }
}
