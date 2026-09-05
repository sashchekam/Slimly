import Foundation

/// Количества словами.
///
/// Форма существительного согласуется с числом по правилам языка, а правила
/// эти везде свои: у английского две формы, у русского три, у японского
/// одна. Выбор отдан строковому каталогу — там у каждого языка свой набор
/// вариантов, и подбирать его таблицей в коде больше не нужно.
public enum CountFormatter {
    /// Что именно считаем. От этого зависит не только слово, но и набор форм:
    /// «фото» не склоняется, а «файл» склоняется, и знает об этом каталог.
    public enum Noun: Sendable {
        case file
        case photo
        case video
        case page
        case track
        case conversion
        case scan
    }

    /// Крупные количества с разрядами: «12 480», «12,480».
    ///
    /// Разряды разделяет выбранный язык, а не система: после ручного выбора
    /// системная локаль осталась на прежнем языке.
    public static func string(_ count: Int) -> String {
        count.formatted(.number.locale(L10nBundle.locale))
    }

    /// «1 файл», «3 файла», «128 файлов».
    public static func string(_ count: Int, _ noun: Noun) -> String {
        switch noun {
        case .file: L10n.Count.file(count)
        case .photo: L10n.Count.photo(count)
        case .video: L10n.Count.video(count)
        case .page: L10n.Count.page(count)
        case .track: L10n.Count.track(count)
        case .conversion: L10n.Count.conversion(count)
        case .scan: L10n.Count.scan(count)
        }
    }

    /// Одно слово, без числа: в профиле цифра набирается крупно, а подпись
    /// под ней — мелко, и склеить их в одну строку нельзя.
    public static func word(_ count: Int, _ noun: Noun) -> String {
        switch noun {
        case .file: L10n.Unit.file(count)
        case .photo: L10n.Unit.photo(count)
        case .video: L10n.Unit.video(count)
        case .page: L10n.Unit.page(count)
        case .track: L10n.Unit.track(count)
        case .conversion: L10n.Unit.conversion(count)
        case .scan: L10n.Unit.scan(count)
        }
    }
}
