import SwiftUI

/// Палитра Nocturne: тёмная основа, один блюрпл-акцент, тональные рампы 100–900.
///
/// Рампы построены в OKLCH по общей шкале светлоты, поэтому одинаковый шаг
/// любой роли весит визуально одинаково. Контраст здесь берётся из рамп,
/// а не из насыщенности — акцентом красим линии и метки, но не заливаем площади.
public enum SlimlyColor {
    // MARK: Роли

    public static let background = Color(hex: 0x161826)
    public static let surface = Color(hex: 0x232532)
    public static let text = Color(hex: 0xE9E9ED)
    public static let accent = Color(hex: 0x9184D9)
    public static let divider = text.opacity(0.16)

    // MARK: Нейтральная рампа

    public static let neutral100 = Color(hex: 0xF3F5FE)
    public static let neutral200 = Color(hex: 0xE4E7F5)
    public static let neutral300 = Color(hex: 0xCFD3E5)
    public static let neutral400 = Color(hex: 0xB2B6CA)
    public static let neutral500 = Color(hex: 0x9397AB)
    public static let neutral600 = Color(hex: 0x75798C)
    public static let neutral700 = Color(hex: 0x595D6C)
    public static let neutral800 = Color(hex: 0x3F424D)
    public static let neutral900 = Color(hex: 0x292B31)

    // MARK: Акцентная рампа

    public static let accent100 = Color(hex: 0xF5F4FF)
    public static let accent200 = Color(hex: 0xE7E5FE)
    public static let accent300 = Color(hex: 0xD2CEFD)
    public static let accent400 = Color(hex: 0xB5ABFC)
    public static let accent500 = Color(hex: 0x968AE0)
    public static let accent600 = Color(hex: 0x796CBF)
    public static let accent700 = Color(hex: 0x5D5294)
    public static let accent800 = Color(hex: 0x423A6A)
    public static let accent900 = Color(hex: 0x2B2741)

    // MARK: Поверхности глубже основной

    /// Тёплое пятно в левом верхнем углу экрана — единственный источник
    /// «света» на фоне.
    public static let backgroundGlow = Color(hex: 0x1E2134)
    /// Подложка подписи под плиткой галереи: темнее фона, чтобы текст
    /// читался поверх любой картинки.
    public static let tileCaption = Color(hex: 0x0C0D14).opacity(0.74)
    /// Дно прогресс-кольца и другие «утопленные» участки.
    public static let surfaceSunken = Color(hex: 0x1A1C2B)
    /// Ячейка внутри карточки: на ступень темнее поверхности, но светлее
    /// фона экрана — так вложенный блок читается как часть карточки,
    /// а не как дырка в ней.
    public static let surfaceInset = Color(hex: 0x20222F)
    /// Верхний угол подсвеченной карточки: та же поверхность с акцентным
    /// подмесом. Ей отмечен блок, который сообщает о состоянии, а не
    /// о содержимом, — сейчас это подключённая подписка.
    public static let surfaceAccented = Color(hex: 0x20223A)
    /// Поверхность нижней шторки — на ступень светлее фона, чтобы её край
    /// читался поверх затемнённого экрана.
    public static let sheet = Color(hex: 0x1C1E2C)
    /// Всплывающее меню альбомов: полупрозрачная подложка под блюром —
    /// системные меню iOS ведут себя так же.
    public static let menu = Color(hex: 0x303242).opacity(0.72)
    /// Панель таб-бара — полупрозрачная, поверх неё работает блюр.
    public static let chrome = Color(hex: 0x141622).opacity(0.92)
    /// Подложка под кнопкой действия: контент под ней должен «уходить в туман».
    public static let scrim = Color(hex: 0x161826).opacity(0.96)

    // MARK: Знак приложения

    /// Приглушённые квадраты знака. Холоднее нейтральной рампы: рядом
    /// с акцентом чистый серый выглядит грязным.
    public static let markMuted = Color(hex: 0x5B5F80)
    /// Центр свечения на заставке. Ярче, чем `backgroundGlow` у экранов:
    /// на заставке нет контента, и вся глубина держится на этом пятне.
    public static let splashGlow = Color(hex: 0x24273D)

    /// Заливка галочки на акцентном кружке — тёмная, а не чёрная.
    public static let onAccent = Color(hex: 0x181A2C)

    // MARK: Вводный тур

    /// Центр свечения на экране тура. Оно идёт сверху по центру, а не от угла:
    /// на этих экранах смотрят в иллюстрацию, и свет собран вокруг неё.
    public static let tourGlow = Color(hex: 0x23253A)
    /// Низ экрана тура — темнее основного фона, чтобы кнопка внизу лежала
    /// на самом глухом участке и читалась без подложки.
    public static let tourEdge = Color(hex: 0x101220)

    /// Лист бумаги в иллюстрациях: скан документа и карточка формата.
    /// Единственное светлое пятно в тёмной системе — поэтому не чисто белое,
    /// а с холодной тенью к нижнему углу.
    public static let paperLight = Color(hex: 0xDCDCE2)
    public static let paperDark = Color(hex: 0xA9A9B4)

    // MARK: Полоски-заглушки вместо превью

    public static let stripeLight = Color(hex: 0x252838)
    public static let stripeDark = Color(hex: 0x1F2231)
    public static let stripeThumbLight = Color(hex: 0x292C3D)
    public static let stripeThumbDark = Color(hex: 0x222533)

    // MARK: Тинты акцента

    /// Полупрозрачная заливка акцентом. В Nocturne акцент — это линия и свечение,
    /// поэтому заливка всегда сильно разбавлена основой.
    public static func accentTint(_ percent: Double) -> Color {
        accent.opacity(percent / 100)
    }
}

extension Color {
    /// Токены Nocturne заданы шестнадцатеричными значениями — держим один
    /// инициализатор вместо трёх дробей на каждый цвет.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
