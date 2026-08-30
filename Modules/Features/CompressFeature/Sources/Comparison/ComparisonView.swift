import SwiftUI
import UIKit
import SlimlyCore
import SlimlyDesignSystem

/// Сравнение «до / после» одного файла.
public struct ComparisonView: View {
    @State private var viewModel: ComparisonViewModel

    public init(viewModel: ComparisonViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar(onBack: { viewModel.goBack() })

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    sidePicker
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
                .init(id: ComparisonViewModel.Side.before.rawValue, title: "Оригинал · \(viewModel.beforeText)"),
                .init(id: ComparisonViewModel.Side.after.rawValue, title: "Сжатое · \(viewModel.afterText)"),
            ],
            selection: Binding(
                get: { viewModel.side.rawValue },
                set: { viewModel.side = ComparisonViewModel.Side(rawValue: $0) ?? .after }
            )
        )
    }

    private var preview: some View {
        SlimlyStripes(light: SlimlyColor.stripeLight, dark: SlimlyColor.stripeDark, band: 9)
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .overlay {
                if let data = viewModel.currentData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Text(viewModel.placeholderLabel)
                        .font(.slimlyCaptionSmall)
                        .tracking(0.66)
                        .foregroundStyle(SlimlyColor.neutral600)
                }
            }
            .clipped()
            .overlay(alignment: .topLeading) {
                Text(viewModel.chipText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        viewModel.isShowingAfter ? SlimlyColor.accent200 : SlimlyColor.neutral300
                    )
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(SlimlyColor.tileCaption, in: Capsule())
                    .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous))
    }

    private var sizes: some View {
        SlimlyCard(padding: EdgeInsets(top: 13, leading: 15, bottom: 13, trailing: 15)) {
            HStack(spacing: 12) {
                Text(viewModel.beforeText)
                    .font(.system(size: 17))
                    .foregroundStyle(SlimlyColor.neutral500)
                    .strikethrough(true, color: SlimlyColor.neutral700)

                SlimlyIcon(.arrowRight, width: 16)
                    .foregroundStyle(SlimlyColor.neutral600)

                Text(viewModel.afterText)
                    .font(.system(size: 22, weight: .medium))
                    .tracking(-0.5)
                    .foregroundStyle(SlimlyColor.accent300)
                    .frame(maxWidth: .infinity, alignment: .leading)

                SlimlyDeltaBadge(viewModel.deltaText)
            }
        }
    }
}
