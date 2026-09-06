import SlimlyCore
import SlimlyDesignSystem
import SwiftUI
import UIKit

/// Просмотр готового файла: у сжатого снимка — шторка «до / после»,
/// у сжатого ролика — переключатель сторон, у остальных инструментов —
/// один кадр результата.
public struct ResultPreviewView: View {
    /// Доля окна, при которой подпись стороны уже не помещается над своей
    /// половиной и гаснет.
    private static let chipFade: Double = 0.18

    @State
    private var viewModel: ResultPreviewViewModel
    /// Чем показывать ролик и документ. Без фабрики экран остаётся
    /// картиночным — для фото этого и достаточно.
    private let viewer: MediaFileViewerFactory?

    public init(viewModel: ResultPreviewViewModel, viewer: MediaFileViewerFactory? = nil) {
        _viewModel = State(wrappedValue: viewModel)
        self.viewer = viewer
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar(onBack: { viewModel.goBack() })

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header

                    if viewModel.showsSidePicker {
                        sidePicker
                    }

                    preview
                    sizes

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

    private var sidePicker: some View {
        SlimlySegmentedControl(
            options: [
                .init(id: ResultPreviewViewModel.Side.before.rawValue, title: viewModel.beforeTitle),
                .init(id: ResultPreviewViewModel.Side.after.rawValue, title: viewModel.afterTitle),
            ],
            selection: Binding(
                get: { viewModel.side.rawValue },
                set: { viewModel.side = ResultPreviewViewModel.Side(rawValue: $0) ?? .after }
            )
        )
    }

    private var preview: some View {
        SlimlyStripes(light: SlimlyColor.stripeLight, dark: SlimlyColor.stripeDark, band: 9)
            .aspectRatio(viewModel.previewAspectRatio, contentMode: .fit)
            .overlay { content }
            .clipped()
            .overlay { chips }
            .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        // Ролик и документ показываем их собственным экраном: у сжатого
        // видео разница с оригиналом видна в движении, а не на стоп-кадре,
        // а у скана страниц больше одной.
        if let viewer, let url = viewModel.viewerURL, let view = viewer(url) {
            view
        } else if viewModel.showsComparison {
            comparison
        } else {
            still(viewModel.currentData, placeholder: viewModel.placeholderLabel)
        }
    }

    /// Оба кадра в одном окне, а не по очереди: разница между оригиналом
    /// и сжатой копией держится в мелочах, и, подменяя картинку целиком,
    /// её приходится держать в памяти.
    private var comparison: some View {
        SlimlyCompareSlider(position: $viewModel.comparePosition) {
            still(viewModel.beforeData, placeholder: viewModel.beforePlaceholderLabel)
        } after: {
            still(viewModel.afterData, placeholder: viewModel.placeholderLabel)
        }
    }

    @ViewBuilder
    private func still(_ data: Data?, placeholder: String) -> some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                // Кадр вертикального ролика в окне 16:9 свисает за края на
                // сотни пунктов, и `clipped` убирает свес только с картинки,
                // но не из хит-теста: невидимая часть накрывает переключатель
                // «до / после» над окном и глушит его нажатия.
                .allowsHitTesting(false)
        } else {
            Text(placeholder)
                .font(.slimlyCaptionSmall)
                .tracking(0.66)
                .foregroundStyle(SlimlyColor.neutral600)
        }
    }

    /// Подписи сторон. У шторки их две — каждая над своей половиной — и
    /// гаснут, когда половина сжимается в полоску: подпись без картинки
    /// под ней читалась бы как подпись к соседней.
    @ViewBuilder
    private var chips: some View {
        if viewModel.showsComparison {
            chip(viewModel.beforeChipText, isAfter: false)
                .opacity(viewModel.comparePosition > Self.chipFade ? 1 : 0)
                .animation(.easeOut(duration: 0.15), value: viewModel.comparePosition > Self.chipFade)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            chip(viewModel.afterChipText, isAfter: true)
                .opacity(viewModel.comparePosition < 1 - Self.chipFade ? 1 : 0)
                .animation(.easeOut(duration: 0.15), value: viewModel.comparePosition < 1 - Self.chipFade)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        } else {
            chip(viewModel.chipText, isAfter: viewModel.isShowingAfter)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func chip(_ text: String, isAfter: Bool) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(isAfter ? SlimlyColor.accent200 : SlimlyColor.neutral300)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(SlimlyColor.tileCaption, in: Capsule())
            .padding(12)
            // Подпись лежит поверх плеера — нажатия должна пропускать
            // к его собственным кнопкам.
            .allowsHitTesting(false)
    }

    private var sizes: some View {
        SlimlyCard(padding: EdgeInsets(top: 13, leading: 15, bottom: 13, trailing: 15)) {
            HStack(spacing: 12) {
                Text(viewModel.beforeText)
                    .font(.system(size: 17))
                    .foregroundStyle(SlimlyColor.neutral500)
                    .strikethrough(viewModel.showsDelta, color: SlimlyColor.neutral700)

                SlimlyIcon(.arrowRight, width: 16)
                    .foregroundStyle(SlimlyColor.neutral600)

                Text(viewModel.afterText)
                    .font(.system(size: 22, weight: .medium))
                    .tracking(-0.5)
                    .foregroundStyle(SlimlyColor.accent300)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.showsDelta {
                    SlimlyDeltaBadge(viewModel.deltaText)
                } else if !viewModel.outputFormat.isEmpty {
                    SlimlyDeltaBadge(viewModel.outputFormat)
                }
            }
        }
    }
}
