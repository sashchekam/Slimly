import SwiftUI
import UIKit
import SlimlyCore
import SlimlyDesignSystem

/// Просмотр исходного файла: кадр целиком, а у ролика — плеер.
public struct SourcePreviewView: View {
    /// Выше кадр не растёт: вертикальный снимок иначе выдавливал бы подписи
    /// за нижний край, и о файле опять пришлось бы судить по одной картинке.
    private static let maxPreviewHeight: CGFloat = 460

    @State private var viewModel: SourcePreviewViewModel
    /// Чем показать ролик. Без фабрики экран остаётся картиночным —
    /// для снимка этого и достаточно.
    private let viewer: MediaFileViewerFactory?
    /// Чем оживить живое фото: у него есть движение, но нет файла,
    /// который можно было бы отдать плееру ссылкой.
    private let player: MediaItemPlayerFactory?

    public init(
        viewModel: SourcePreviewViewModel,
        viewer: MediaFileViewerFactory? = nil,
        player: MediaItemPlayerFactory? = nil
    ) {
        _viewModel = State(wrappedValue: viewModel)
        self.viewer = viewer
        self.player = player
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar(onBack: { viewModel.goBack() })

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    preview

                    Text(viewModel.note)
                        .font(.slimlyCaption)
                        .foregroundStyle(SlimlyColor.neutral600)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 6)
            }
        }
        .slimlyScreen()
        .task { await viewModel.load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(viewModel.title)
                .font(.system(size: 22, weight: .medium))
                .tracking(-0.4)
                .lineLimit(1)
                .truncationMode(.middle)

            Text(viewModel.subtitle)
                .font(.system(size: 12))
                .foregroundStyle(SlimlyColor.neutral500)
        }
    }

    private var preview: some View {
        SlimlyStripes(light: SlimlyColor.stripeLight, dark: SlimlyColor.stripeDark, band: 9)
            .aspectRatio(viewModel.previewAspectRatio, contentMode: .fit)
            .frame(maxHeight: Self.maxPreviewHeight)
            .overlay { content }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous))
            // Кадр уже квадратного экрана: без этого он прижался бы влево,
            // а подписи под ним остались бы во всю ширину.
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        // Ролик показываем плеером: по стоп-кадру видео от видео не отличить,
        // а выбирают его как раз по движению и звуку.
        if let viewer, let url = viewModel.playbackURL, let view = viewer(url) {
            view
        } else {
            ZStack {
                if let data = viewModel.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Text(viewModel.placeholderLabel)
                        .font(.slimlyCaptionSmall)
                        .tracking(0.66)
                        .foregroundStyle(SlimlyColor.neutral600)
                }

                // Живое фото проигрывается поверх кадра: своего файла
                // у него нет, и плееру ссылкой его не передать.
                if viewModel.item.isLivePhoto, let player, let view = player(viewModel.item) {
                    view
                }
            }
        }
    }
}
