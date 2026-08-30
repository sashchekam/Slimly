import SlimlyNavigation
import SwiftUI

struct AppRootView: View {
    let container: AppContainer

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isSplashVisible = true

    var body: some View {
        ZStack {
            RouterHost(router: container.router, registry: container.registry)
                // Приложение подъезжает навстречу зрителю, пока заставка уходит
                // вперёд. Разъезд в разные стороны читается как «открылось»,
                // тогда как простое растворение — как «подгрузилось».
                .scaleEffect(isSplashVisible && !reduceMotion ? 0.96 : 1)
                .opacity(isSplashVisible ? 0 : 1)

            if isSplashVisible {
                SplashView(onFinish: hideSplash)
                    .transition(splashExit)
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

    private var splashExit: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 1.08))
    }

    private func hideSplash() {
        withAnimation(.easeInOut(duration: 0.42)) { isSplashVisible = false }
    }
}
