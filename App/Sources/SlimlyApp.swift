import SlimlyCore
import SwiftUI

@main
struct SlimlyApp: App {
    @UIApplicationDelegateAdaptor(QuickActionAppDelegate.self)
    private var appDelegate

    @State
    private var container = AppContainer()
    @State
    private var quickActions = QuickActionInbox.shared

    var body: some Scene {
        WindowGroup {
            AppRootView(container: container)
                .onOpenURL { url in
                    guard let deeplink = DeeplinkURL(url: url) else { return }
                    container.handle(deeplink)
                }
                // Холодный старт: действие уже лежит в ящике к моменту,
                // когда появляется сцена. Показать его вовремя — забота
                // контейнера: до конца заставки открывать ещё нечего.
                .task { openQuickAction() }
                // Приложение уже работало — действие приходит на живую сцену.
                .onChange(of: quickActions.pending) { openQuickAction() }
        }
    }

    private func openQuickAction() {
        guard let deeplink = quickActions.take() else { return }
        container.handle(deeplink, from: .shortcut)
    }
}
