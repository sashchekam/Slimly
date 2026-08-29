import SwiftUI
import CompressFeatureInterface
import SlimlyCore
import SlimlyDesignSystem
import SlimlyNavigation

public struct GalleryView: View {
    @State private var viewModel: GalleryViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 3)

    public init(viewModel: GalleryViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                header
                savedCard
                entryTiles
                sectionHeader
                grid

                Text("Последние сжатия")
                    .font(.slimlySectionTitle)
                    .padding(.top, 3)

                SlimlyRowGroup {
                    ForEach(viewModel.recent) { CompressionResultRow(result: $0) }
                }
            }
            .padding(.horizontal, SlimlySpacing.screenHorizontal)
            .padding(.bottom, 6)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.hasSelection {
                SlimlyBottomAction {
                    Button(viewModel.ctaTitle) { viewModel.openSetup() }
                        .buttonStyle(.slimlyPrimary)
                }
            }
        }
        .slimlyScreen()
        .task { await viewModel.load() }
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Text("Сжать")
                .font(.slimlyLargeTitle)
                .tracking(SlimlyTracking.largeTitle)

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 0) {
                Text("свободно на iPhone")
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral500)
                Text(viewModel.freeSpaceText)
                    .font(.slimlyBodySmall)
                    .foregroundStyle(SlimlyColor.neutral300)
            }
            .multilineTextAlignment(.trailing)
            .padding(.bottom, 5)
        }
    }

    private var savedCard: some View {
        SlimlyCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("освобождено всего").slimlyKicker()

                HStack(alignment: .lastTextBaseline, spacing: 9) {
                    Text(viewModel.savedText)
                        .font(.slimlyStatL)
                        .tracking(SlimlyTracking.statL)
                        .foregroundStyle(SlimlyColor.accent300)
                    Text(viewModel.savedSubtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(SlimlyColor.neutral400)
                }
                .padding(.top, 9)

                SlimlyFadingRule().padding(.top, 13)

                Text(viewModel.savedTransition)
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral500)
                    .padding(.top, 9)
            }
        }
    }

    private var entryTiles: some View {
        HStack(spacing: 9) {
            Button {
                Task { await viewModel.openPicker() }
            } label: {
                EntryTile(icon: .plus, title: "Выбрать\nфайлы", isAccented: true)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.openHEICConversion()
            } label: {
                EntryTile(icon: .convert, title: "HEIC\n→ JPEG", isAccented: false)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasHEICShortcut)
            .opacity(viewModel.hasHEICShortcut ? 1 : 0.45)
        }
    }

    private var sectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Недавнее").font(.slimlySectionTitle)
            Spacer()
            Button("Вся галерея") {
                Task { await viewModel.openPicker() }
            }
            .buttonStyle(SlimlyLinkButtonStyle(color: SlimlyColor.accent300, font: .system(size: 12)))
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 7) {
            ForEach(viewModel.items) { item in
                Button {
                    viewModel.toggle(item)
                } label: {
                    MediaTile(item: item, isSelected: viewModel.isSelected(item))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Плитка входа во флоу: акцентная — для системного выбора файлов,
/// обычная — для конвертации HEIC.
private struct EntryTile: View {
    let icon: SlimlyIcon.Kind
    let title: String
    let isAccented: Bool

    var body: some View {
        HStack(spacing: 10) {
            SlimlyIcon(icon, width: 19)
                .foregroundStyle(isAccented ? SlimlyColor.accent300 : SlimlyColor.neutral300)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isAccented ? SlimlyColor.accent200 : SlimlyColor.neutral200)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(
            isAccented ? SlimlyColor.accentTint(9) : SlimlyColor.surface,
            in: RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
        )
        .overlay {
            // Акцентная плитка держится на своей рамке, обычная — на кромке
            // высоты: две обводки сразу дали бы двойной контур.
            if isAccented {
                RoundedRectangle(cornerRadius: SlimlyRadius.lg, style: .continuous)
                    .strokeBorder(SlimlyColor.accent600, lineWidth: 1)
            }
        }
        .slimlyElevation(isAccented ? .flat : .sm)
    }
}

private struct MediaTile: View {
    let item: MediaItem
    let isSelected: Bool

    var body: some View {
        SlimlyStripes.tile
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Text(MediaItemFormatter.kindLabel(item))
                    .font(.slimlyNano)
                    .tracking(0.57)
                    .foregroundStyle(SlimlyColor.neutral700)
            }
            .overlay(alignment: .bottomLeading) {
                Text(MediaItemFormatter.meta(item))
                    .font(.slimlyNano)
                    .foregroundStyle(SlimlyColor.neutral300)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(SlimlyColor.tileCaption, in: RoundedRectangle(cornerRadius: SlimlyRadius.sm))
                    .padding(5)
            }
            .overlay {
                if isSelected {
                    SlimlyColor.accentTint(15)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: SlimlyRadius.tile, style: .continuous))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: SlimlyRadius.tile, style: .continuous)
                        .strokeBorder(SlimlyColor.accent, lineWidth: 2)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    SlimlyIcon(.check, width: 11)
                        .foregroundStyle(SlimlyColor.onAccent)
                        .frame(width: 19, height: 19)
                        .background(SlimlyColor.accent, in: Circle())
                        .padding(5)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(item.fileName), \(MediaItemFormatter.meta(item))")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
