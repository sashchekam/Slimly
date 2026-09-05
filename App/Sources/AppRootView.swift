import SlimlyCore
import SlimlyDesignSystem
import SlimlyNavigation
import SwiftUI

struct AppRootView: View {
    let container: AppContainer

    @State
    private var isSplashVisible = true
    /// Заставка остаётся в иерархии до конца растворения — снимаем её только
    /// после, иначе гаснуть будет уже нечему.
    @State
    private var isSplashMounted = true
    @State
    private var isAppVisible = false

    var body: some View {
        ZStack {
            // Подложка не участвует в передаче кадра: пока заставка гаснет, а
            // первый экран ещё не проявился, между ними виден фон приложения,
            // а не чёрное окно.
            SlimlyScreenBackground()

            RouterHost(router: container.router, registry: container.registry)
                .opacity(isAppVisible ? 1 : 0)
                // Смена языка пересобирает дерево целиком: строки приходят
                // из бандла обычным `String`, и сама по себе замена языка
                // ни один экран не перерисует. Стек при этом остаётся —
                // путь живёт в роутере, а не в снесённых вью.
                .id(container.localization.current)
                // Системным форматам (дата в `Text`, `.formatted`) язык
                // приложения не виден: они идут за локалью окружения.
                .environment(\.locale, L10nBundle.locale)

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

        // Отложенная ссылка открывается только после проявления: шторка,
        // выехавшая на полупрозрачном экране, читается как сбой, а не как
        // открытый инструмент.
        withAnimation(.easeInOut(duration: 0.35).delay(0.26)) {
            isAppVisible = true
        } completion: {
            container.screenDidAppear()
        }
    }
}
