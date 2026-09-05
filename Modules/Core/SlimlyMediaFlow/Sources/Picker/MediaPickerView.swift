import SlimlyCore
import SlimlyDesignSystem
import SwiftUI
import UIKit

/// Общий шаг выбора файлов: альбом, сетка, лимит и кнопка «Далее».
/// Инструменты различаются заголовками и правилами выборки, а не экраном.
public struct MediaPickerView: View {
    @State
    private var viewModel: MediaPickerViewModel
    @Environment(\.openURL)
    private var openURL

    /// Где у списка кадр и какие даты в него попали — считается по геометрии
    /// плиток, поэтому живёт во вью, а не в модели.
    @State
    private var scroll = MediaScrollState()

    /// Чем оживить превью в контекстном меню. Без фабрики оно остаётся
    /// кадром — так экран работает и там, где играть нечего.
    private let player: MediaItemPlayerFactory?

    /// Сколько плиток в ряду. Держится во вью: перестроение сетки — дело
    /// вёрстки, и модель о нём не знает.
    @State
    private var density = MediaGridDensity.large

    @State
    private var isConfiguringGrid = false

    public init(viewModel: MediaPickerViewModel, player: MediaItemPlayerFactory? = nil) {
        _viewModel = State(wrappedValue: viewModel)
        self.player = player
    }

    public var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 9, pinnedViews: [.sectionHeaders]) {
                        header
                            .padding(.horizontal, SlimlySpacing.screenHorizontal)

                        Section {
                            VStack(alignment: .leading, spacing: 15) {
                                content
                            }
                            .padding(.horizontal, SlimlySpacing.screenHorizontal)
                            .padding(.bottom, 6)
                        } header: {
                            if viewModel.access.allowsBrowsing {
                                stickyAlbumMenu
                            }
                        }
                    }
                }
                .sheet(isPresented: $isConfiguringGrid) {
                    MediaGridSettingsSheet(
                        density: Binding { density } set: { apply($0, with: proxy) },
                        onClose: { isConfiguringGrid = false }
                    )
                    .presentationDetents([.height(MediaGridSettingsSheet.height)])
                    .presentationBackground(SlimlyColor.sheet)
                }
            }
            .sensoryFeedback(.selection, trigger: density)
            .coordinateSpace(.named(MediaScrollWindow.space))
            .reportsWindowBottom()
            .onPreferenceChange(MediaScrollWindowKey.self) { scroll.window = $0 }
            .onPreferenceChange(MediaVisibleDatesKey.self) { scroll.visibleDates = $0 }
            .onPreferenceChange(MediaAnchorKey.self) { scroll.anchorID = $0?.id }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Панель появляется вместе с первым выбранным файлом, поэтому
                // выезжает снизу: резкое появление читалось бы как скачок вёрстки.
                if viewModel.hasSelection {
                    SlimlyBottomAction {
                        Button(viewModel.ctaTitle) { viewModel.proceed() }
                            .buttonStyle(.slimlyPrimary)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.34, dampingFraction: 0.86), value: viewModel.hasSelection)
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
                title: L10n.Picker.deniedTitle,
                text: L10n.Picker.deniedNote,
                actionTitle: L10n.Picker.openSettings
            ) {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }
        } else if viewModel.isLoading {
            loader
        } else if viewModel.isEmpty {
            notice(title: viewModel.emptyTitle, text: viewModel.emptyHint)
        } else {
            if viewModel.showsLimitedNotice {
                limitedAccessHint
            }
            grid
        }
    }

    /// Пока медиатека читается, сетки нет — вместо неё держим место высотой
    /// примерно в один ряд плиток, чтобы контент под ней не прыгал.
    private var loader: some View {
        VStack(spacing: 12) {
            SlimlySpinner()

            Text(L10n.Picker.loading)
                .font(.slimlyBodySmall)
                .foregroundStyle(SlimlyColor.neutral500)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
    }

    /// Меню альбомов прилипает к верху списка: пролистав сетку, всё ещё видно,
    /// какой альбом открыт, и сменить его можно не возвращаясь наверх.
    private var stickyAlbumMenu: some View {
        HStack(spacing: 10) {
            albumMenu

            MediaVisibleDatesLabel(scroll: scroll)
                .frame(maxWidth: .infinity, alignment: .trailing)

            densityButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SlimlySpacing.screenHorizontal)
        .padding(.vertical, 6)
        .slimlyStickyBackground()
        .reportsWindowTop()
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
                        Label {
                            Text(verbatim: "\(album.title)  \(album.itemCount)")
                        } icon: {
                            Image(systemName: "checkmark")
                        }
                    } else {
                        Text(verbatim: "\(album.title)  \(album.itemCount)")
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                SlimlyIcon(.folder, width: 15)
                    .foregroundStyle(SlimlyColor.neutral400)

                Text(viewModel.currentAlbum?.title ?? L10n.Picker.recents)
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
        .accessibilityLabel(Text(L10n.Picker.album))
    }

    /// Кнопка плотности показывает саму сетку: значок повторяет ряд плиток,
    /// поэтому и до нажатия видно, что именно настраивается.
    private var densityButton: some View {
        Button {
            isConfiguringGrid = true
        } label: {
            MediaGridPreview(columns: density.columns, width: 16)
                .foregroundStyle(SlimlyColor.neutral400)
                .padding(.horizontal, 11)
                .padding(.vertical, 11)
                .background(SlimlyColor.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(SlimlyColor.text.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.Picker.grid))
        .accessibilityValue(density.title)
    }

    private var limitedAccessHint: some View {
        Text(L10n.Picker.limitedNote)
            .font(.slimlyCaptionSmall)
            .foregroundStyle(SlimlyColor.neutral500)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var grid: some View {
        LazyVGrid(columns: density.gridItems, spacing: density.spacing) {
            ForEach(viewModel.items) { item in
                // Не `Button`: у плитки есть и контекстное меню, а его длинное
                // нажатие живёт в UIKit-интеракции и постоянно отбирает у кнопки
                // отслеживание касания — тап то срабатывает, то нет. Отдельный
                // жест нажатия с интеракцией уживается.
                MediaTile(
                    item: item,
                    isSelected: viewModel.isSelected(item),
                    thumbnail: viewModel.thumbnails,
                    showsSize: viewModel.config.showsSize
                )
                .opacity(viewModel.isBlocked(item) ? 0.4 : 1)
                .onTapGesture { viewModel.toggle(item) }
                .disabled(viewModel.isBlocked(item))
                .contextMenu {
                    // Меню без пунктов система не показывает, поэтому выбор
                    // продублирован здесь: из превью его тоже видно.
                    Button {
                        viewModel.toggle(item)
                    } label: {
                        Label(
                            viewModel.isSelected(item)
                                ? L10n.Picker.deselect
                                : L10n.Picker.select,
                            systemImage: viewModel.isSelected(item) ? "checkmark.circle" : "circle"
                        )
                    }
                    .disabled(viewModel.isBlocked(item))
                } preview: {
                    MediaTilePreview(
                        item: item,
                        thumbnail: viewModel.thumbnails,
                        showsSize: viewModel.config.showsSize,
                        player: player
                    )
                }
                .reportsGridPosition(id: item.id, date: item.creationDate, in: scroll.window)
                .onAppear { viewModel.willShow(item) }
            }
        }

        if viewModel.hasMore {
            gridFooter
        }
    }

    /// Подвал сетки: пока медиатека дочитывается, под последним рядом видно,
    /// что список не кончился. Он же просит следующую страницу — на случай,
    /// если быстрая прокрутка проскочила плитку-триггер.
    private var gridFooter: some View {
        SlimlySpinner()
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .onAppear { viewModel.loadMoreIfNeeded() }
    }

    /// Сменить плотность, оставив на месте ту плитку, на которую пользователь
    /// смотрел. От плотности зависит высота всей ленты, и без возврата кадр
    /// уезжает тем дальше, чем ниже пролистан список.
    ///
    /// Обе правки — и раскладка, и прокрутка — идут без анимации: сетка
    /// перестраивается вся разом, и любое движение здесь читалось бы как
    /// рябь, а не как переход.
    private func apply(_ newDensity: MediaGridDensity, with proxy: ScrollViewProxy) {
        guard newDensity != density else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            density = newDensity
            if let anchorID = scroll.anchorID {
                proxy.scrollTo(anchorID, anchor: .center)
            }
        }
    }

    private func notice(
        title: String,
        text: String,
        actionTitle: String? = nil,
        action: @escaping () -> Void = { }
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
