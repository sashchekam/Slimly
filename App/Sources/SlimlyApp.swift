import SlimlyCore
import SwiftUI

@main
struct SlimlyApp: App {
    @State
    private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            AppRootView(container: container)
                .onOpenURL { url in
                    guard let deeplink = DeeplinkURL(url: url) else { return }
                    container.handle(deeplink)
                }
        }
    }
}
