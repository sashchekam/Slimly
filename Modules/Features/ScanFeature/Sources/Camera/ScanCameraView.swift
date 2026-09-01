import SwiftUI
import UIKit
import SlimlyCore
import SlimlyDesignSystem
import SlimlyMediaKit

/// Съёмка страниц документа.
///
/// Единственный экран приложения без общей обвязки: под кадром камеры
/// градиентный фон и поля Nocturne только мешали бы — здесь весь контраст
/// держится на самом кадре, а интерфейс живёт поверх него.
public struct ScanCameraView: View {
    @State private var viewModel: ScanCameraViewModel
    @Environment(\.openURL) private var openURL

    public init(viewModel: ScanCameraViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Color.viewfinder
                .ignoresSafeArea()

            if viewModel.isDenied {
                deniedNotice
            } else {
                viewfinder
            }

            controls
        }
        // Экран приезжает поверх стека, а свой стек рисует системную панель:
        // над кадром камеры ей места нет.
        .toolbar(.hidden, for: .navigationBar)
        // Отклик на снятый кадр: затвора не слышно, а глаз в этот момент
        // в видоискателе — счётчик и тост он заметит уже потом. Триггер по
        // счётчику, поэтому автосъёмка отзывается так же, как ручная.
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.pageCount) { before, after in
            after > before
        }
        .task { await viewModel.appear() }
        .onDisappear { viewModel.disappear() }
    }

    // MARK: Кадр

    private var viewfinder: some View {
        GeometryReader { geometry in
            ZStack {
                DocumentCameraPreview(camera: viewModel.camera)

                if let quad = viewModel.quad {
                    DocumentFrame(
                        quad: quad,
                        frameAspectRatio: viewModel.frameAspectRatio,
                        size: geometry.size
                    )
                }
            }
        }
        .ignoresSafeArea()
    }

    /// Без доступа камера не покажет ничего, поэтому вместо чёрного
    /// прямоугольника — прямая дорога в настройки.
    private var deniedNotice: some View {
        VStack(spacing: 14) {
            SlimlyIcon(.camera, width: 34)
                .foregroundStyle(SlimlyColor.neutral500)

            Text("Нет доступа к камере")
                .font(.slimlySectionTitle)

            Text("Разрешите съёмку в настройках — страницы можно снять или выбрать из галереи")
                .font(.slimlyBodySmall)
                .foregroundStyle(SlimlyColor.neutral400)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Открыть настройки") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }
            .buttonStyle(.slimlyCompact)
            .padding(.top, 2)
        }
        .padding(.horizontal, 44)
    }

    // MARK: Управление

    private var controls: some View {
        VStack(spacing: 0) {
            topBar

            Spacer(minLength: 0)

            // Тост живёт над подсказкой, а не у нижнего края: низ экрана
            // занят затвором, и общий `slimlyToast` накрыл бы его.
            if let toast = viewModel.toast {
                SlimlyToast(toast)
                    .padding(.horizontal, SlimlySpacing.screenHorizontal)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            hint
                .padding(.bottom, 14)

            shutterBar
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: viewModel.toast)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button("Отмена") { viewModel.cancel() }
                .buttonStyle(SlimlyLinkButtonStyle(color: SlimlyColor.text, font: .system(size: 16)))

            Spacer(minLength: 0)

            Button {
                viewModel.toggleFlash()
            } label: {
                HStack(spacing: 6) {
                    SlimlyIcon(.flash, width: 13)
                    Text(viewModel.flashLabel)
                }
            }
            .buttonStyle(ModeChipStyle(isOn: viewModel.isFlashOn))
            .accessibilityLabel("Вспышка: \(viewModel.flashLabel)")

            Button(viewModel.automaticLabel) {
                viewModel.toggleAutomatic()
            }
            .buttonStyle(ModeChipStyle(isOn: viewModel.isAutomatic))
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private var hint: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(SlimlyColor.accent)
                .frame(width: 6, height: 6)

            Text(viewModel.hintText)
                .font(.slimlyBodySmall)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(Color.viewfinder.opacity(0.62), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(SlimlyColor.accent.opacity(0.35), lineWidth: 1))
        .padding(.horizontal, SlimlySpacing.screenHorizontal)
    }

    private var shutterBar: some View {
        HStack(spacing: 14) {
            counter
                .frame(maxWidth: .infinity, alignment: .leading)

            shutter

            Button(viewModel.doneTitle) { viewModel.finish() }
                .buttonStyle(
                    SlimlyLinkButtonStyle(
                        color: viewModel.hasPages ? SlimlyColor.accent200 : SlimlyColor.neutral600,
                        font: .system(size: 15, weight: .medium)
                    )
                )
                .disabled(!viewModel.hasPages)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                colors: [Color.viewfinder.opacity(0), Color.viewfinder.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    @ViewBuilder
    private var counter: some View {
        if viewModel.hasPages {
            HStack(spacing: 9) {
                PageStack(count: viewModel.pageCount)

                Text(viewModel.pagesText)
                    .font(.slimlyCaption)
                    .foregroundStyle(SlimlyColor.neutral400)
            }
        } else {
            Text("Снимите первую страницу")
                .font(.slimlyCaption)
                .foregroundStyle(SlimlyColor.neutral500)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var shutter: some View {
        Button {
            Task { await viewModel.shoot() }
        } label: {
            Circle()
                .strokeBorder(SlimlyColor.text, lineWidth: 3)
                .frame(width: 70, height: 70)
                .overlay {
                    Circle()
                        .fill(SlimlyColor.text)
                        .frame(width: 56, height: 56)
                }
        }
        .buttonStyle(ShutterButtonStyle())
        .disabled(viewModel.camera.isAtLimit || viewModel.camera.isBusy)
        .opacity(viewModel.camera.isAtLimit ? 0.4 : 1)
        .accessibilityLabel("Снять страницу")
    }
}

// MARK: - Рамка страницы

/// Найденные границы листа поверх кадра.
///
/// Рисуем сам четырёхугольник, а не прямоугольник вокруг него: обещание
/// рамки должно совпадать с тем, что потом вырежется, иначе кадр выравнивают
/// по одной границе, а получают другую.
private struct DocumentFrame: View {
    let quad: DocumentQuad
    /// Ширина кадра к его высоте — превью растянуто по этой пропорции.
    let frameAspectRatio: CGFloat
    let size: CGSize

    /// Длина уголка. Ограничена долей стороны, иначе на маленьком листе
    /// четыре уголка сомкнулись бы в сплошной контур.
    private static let cornerLength: CGFloat = 22
    private static let cornerShare: CGFloat = 0.25

    var body: some View {
        ZStack {
            outline
                .fill(SlimlyColor.accentTint(12))

            outline
                .stroke(SlimlyColor.accent, lineWidth: 2)

            corners
                .stroke(
                    SlimlyColor.accent200,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
        }
        .shadow(color: SlimlyColor.accent.opacity(0.35), radius: 13)
        .animation(.easeOut(duration: 0.12), value: quad)
        .allowsHitTesting(false)
    }

    private var outline: Path {
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        return path
    }

    private var corners: Path {
        var path = Path()
        for (index, corner) in points.enumerated() {
            for neighbour in [points[(index + 3) % 4], points[(index + 1) % 4]] {
                path.move(to: corner)
                path.addLine(to: corner.approaching(neighbour, by: Self.cornerLength, share: Self.cornerShare))
            }
        }
        return path
    }

    /// Превью заполняет экран целиком, поэтому кадр обрезан по короткой
    /// стороне — доли переводим в точки по тому же правилу.
    private var points: [CGPoint] {
        var width = size.width
        var height = size.height
        if size.width / size.height > frameAspectRatio {
            height = size.width / frameAspectRatio
        } else {
            width = size.height * frameAspectRatio
        }

        let left = (size.width - width) / 2
        let top = (size.height - height) / 2

        return quad.corners.map {
            CGPoint(x: left + $0.x * width, y: top + $0.y * height)
        }
    }
}

private extension CGPoint {
    /// Точка на отрезке к соседу: длиной в `distance`, но не длиннее доли стороны.
    func approaching(_ other: CGPoint, by distance: CGFloat, share: CGFloat) -> CGPoint {
        let side = hypot(other.x - x, other.y - y)
        guard side > 0 else { return self }
        let fraction = min(distance / side, share)
        return CGPoint(x: x + (other.x - x) * fraction, y: y + (other.y - y) * fraction)
    }
}

// MARK: - Мелочи экрана

/// Стопка снятых страниц: верхний лист с номером и краешек нижнего.
private struct PageStack: View {
    let count: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(SlimlyColor.neutral500)
                .padding(.vertical, 2)
                .padding(.leading, 4)
                .rotationEffect(.degrees(4))

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.86), Color(white: 0.69)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(SlimlyColor.text.opacity(0.5), lineWidth: 1)
                }
                .overlay {
                    Text("\(count)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SlimlyColor.onAccent)
                }
        }
        .frame(width: 44, height: 44)
    }
}

/// Чип режима в шапке камеры: включённый берёт акцентный тинт, выключенный —
/// нейтральную подложку. Рамки нет: поверх живого кадра она читается хуже,
/// чем заливка.
private struct ModeChipStyle: ButtonStyle {
    let isOn: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(isOn ? SlimlyColor.accent100 : SlimlyColor.text)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(
                isOn ? SlimlyColor.accentTint(26) : SlimlyColor.text.opacity(0.12),
                in: Capsule()
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Затвор откликается уменьшением: подсветить его нечем — он и так белый.
private struct ShutterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private extension Color {
    /// Фон видоискателя темнее основного: под живым кадром любой оттенок
    /// фона читается как засветка по краям.
    static let viewfinder = Color(red: 10 / 255, green: 11 / 255, blue: 16 / 255)
}
