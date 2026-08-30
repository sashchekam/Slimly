import SwiftUI
import UIKit
import SlimlyCore
import SlimlyDesignSystem

/// Общий шаг выбора файлов: альбом, сетка, лимит и кнопка «Далее».
/// Инструменты различаются заголовками и правилами выборки, а не экраном.
public struct MediaPickerView: View {
    @State private var viewModel: MediaPickerViewModel
    @Environment(\.openURL) private var openURL

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 3)

    public init(viewModel: MediaPickerViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    header

                    if viewModel.access.allowsBrowsing {
                        albumMenu
                    }

                    content

                    Text(viewModel.config.footnote)
                        .font(.slimlyCaptionSmall)
                        .foregroundStyle(SlimlyColor.neutral600)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, SlimlySpacing.screenHorizontal)
                .padding(.bottom, 6)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if viewModel.hasSelection {
                    SlimlyBottomAction {
                        Button(viewModel.ctaTitle) { viewModel.proceed() }
                            .buttonStyle(.slimlyPrimary)
                    }
                }
            }
        }
        .slimlyScreen()
        .task { await viewModel.load() }
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            SlimlyNavigationBar(onBack: { viewModel.goBack() })

            SlimlyLimitPill(
                title: viewModel.limitTitle,
                fraction: viewModel.limitFraction,
                isAtLimit: viewModel.isAtLimit
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.config.title)
                .font(.slimlyTitle)
                .tracking(SlimlyTracking.title)
            Text(viewModel.config.hint)
                .font(.slimlyBodySmall)
                .foregroundStyle(SlimlyColor.neutral400)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isDenied {
            notice(
                title: "Нет доступа к Фото",
                text: "Без доступа к медиатеке выбирать нечего. Разрешение включается в настройках.",
                actionTitle: "Открыть настройки"
            ) {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }
        } else if viewModel.isEmpty {
            notice(title: viewModel.emptyTitle, text: viewModel.emptyHint)
        } else {
            if viewModel.showsLimitedNotice {
                limitedAccessHint
            }
            grid
        }
    }

    /// Список альбомов — системное меню: у него готовы блюр, галочка
    /// выбранного пункта и поведение при промахе мимо пункта.
    private var albumMenu: some View {
        Menu {
            ForEach(viewModel.albums) { album in
                Button {
                    viewModel.select(album)
                } label: {
                    if album.id == viewModel.albumID {
                        Label("\(album.title)  \(album.itemCount)", systemImage: "checkmark")
                    } else {
                        Text("\(album.title)  \(album.itemCount)")
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                SlimlyIcon(.folder, width: 15)
                    .foregroundStyle(SlimlyColor.neutral400)

                Text(viewModel.currentAlbum?.title ?? "Недавние")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SlimlyColor.text)

                Text(CountFormatter.string(viewModel.currentAlbum?.itemCount ?? 0))
                    .font(.slimlyCaptionSmall)
                    .foregroundStyle(SlimlyColor.neutral600)

                SlimlyIcon(.chevronDown, width: 9)
                    .foregroundStyle(SlimlyColor.neutral500)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(SlimlyColor.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(SlimlyColor.text.opacity(0.1), lineWidth: 1))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel("Альбом")
    }

    private var limitedAccessHint: some View {
        Text("Открыта часть медиатеки — здесь только те файлы, к которым вы дали доступ.")
            .font(.slimlyCaptionSmall)
            .foregroundStyle(SlimlyColor.neutral500)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 7) {
            ForEach(viewModel.items) { item in
                Button {
                    viewModel.toggle(item)
                } label: {
                    MediaTile(
                        item: item,
                        isSelected: viewModel.isSelected(item),
                        thumbnail: viewModel.thumbnails
                    )
                    .opacity(viewModel.isBlocked(item) ? 0.4 : 1)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isBlocked(item))
                .contextMenu {
                    // Меню без пунктов система не показывает, поэтому выбор
                    // продублирован здесь: из превью его тоже видно.
                    Button {
                        viewModel.toggle(item)
                    } label: {
                        Label(
                            viewModel.isSelected(item) ? "Снять выбор" : "Выбрать",
                            systemImage: viewModel.isSelected(item) ? "checkmark.circle" : "circle"
                        )
                    }
                    .disabled(viewModel.isBlocked(item))
                } preview: {
                    MediaTilePreview(item: item, thumbnail: viewModel.thumbnails)
                }
            }
        }
    }

    private func notice(
        title: String,
        text: String,
        actionTitle: String? = nil,
        action: @escaping () -> Void = {}
    ) -> some View {
        SlimlyCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))

                Text(text)
                    .font(.slimlyBodySmall)
                    .foregroundStyle(SlimlyColor.neutral400)
                    .fixedSize(horizontal: false, vertical: true)

                if let actionTitle {
                    Button(actionTitle, action: action)
                        .buttonStyle(.slimlyOutline)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
