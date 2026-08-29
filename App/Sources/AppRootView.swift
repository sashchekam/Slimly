import SwiftUI
import SlimlyDesignSystem
import SlimlyNavigation

struct AppRootView: View {
    let container: AppContainer

    var body: some View {
        TabRouterHost(tabRouter: container.tabRouter, registry: container.registry) { tabRouter in
            SqueezeTabBar(tabRouter: tabRouter)
        }
        // Nocturne — тёмная система без светлого варианта, поэтому схему
        // фиксируем: иначе системные элементы приедут светлыми.
        .preferredColorScheme(.dark)
    }
}

/// Панель табов. Рисуется в App, а не в навигации: как выглядит таб-бар —
/// продуктовая деталь, а не свойство роутинга.
struct SqueezeTabBar: View {
    let tabRouter: TabRouter

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(SlimlyColor.text.opacity(0.08))
                .frame(height: 1)

            HStack(spacing: 0) {
                ForEach(SqueezeTab.allCases) { tab in
                    button(for: tab)
                }
            }
            .padding(.vertical, 6)
        }
        .background {
            SlimlyColor.chrome
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func button(for tab: SqueezeTab) -> some View {
        let isSelected = tabRouter.selection == tab.id

        return Button {
            tabRouter.select(tab.id)
        } label: {
            VStack(spacing: 4) {
                SlimlyIcon(tab.icon, width: 24)
                Text(tab.title).font(.slimlyTabLabel)
            }
            .foregroundStyle(isSelected ? SlimlyColor.accent300 : SlimlyColor.neutral600)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
