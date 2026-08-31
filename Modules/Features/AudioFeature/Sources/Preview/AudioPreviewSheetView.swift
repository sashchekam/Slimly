import SwiftUI
import SlimlyDesignSystem
import SlimlyMediaFlow

/// Шторка с готовой дорожкой: огибающая и одна кнопка — больше о звуке
/// сказать нечем, а вес и формат уже стоят в строке итога.
public struct AudioPreviewSheetView: View {
    /// Плееру нужен свой рост: сам он растягивается на всё предложенное
    /// место, а в шторке предложить ему нечего — она по нему и меряется.
    private static let playerHeight: CGFloat = 150

    @State private var viewModel: AudioPreviewSheetViewModel
    /// Чем играть дорожку. Плеер собирает модуль системной обработки —
    /// про AVFoundation фича не знает.
    private let viewer: MediaFileViewerFactory

    public init(viewModel: AudioPreviewSheetViewModel, viewer: @escaping MediaFileViewerFactory) {
        _viewModel = State(wrappedValue: viewModel)
        self.viewer = viewer
    }

    public var body: some View {
        SlimlySheetScaffold(
            title: viewModel.title,
            height: 262,
            closeTitle: "Готово",
            onCancel: { viewModel.close() }
        ) {
            player
        }
    }

    @ViewBuilder
    private var player: some View {
        if let url = viewModel.url, let view = viewer(url) {
            view
                .frame(height: Self.playerHeight)
                .background(
                    SlimlyColor.text.opacity(0.045),
                    in: RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
                )
        } else {
            Text("Дорожка недоступна")
                .font(.slimlyCaption)
                .foregroundStyle(SlimlyColor.neutral600)
                .frame(maxWidth: .infinity, minHeight: Self.playerHeight)
        }
    }
}
