import SwiftUI
import SlimlyNavigation

struct AppRootView: View {
    let container: AppContainer

    var body: some View {
        RouterHost(router: container.rootRouter, registry: container.registry)
    }
}
