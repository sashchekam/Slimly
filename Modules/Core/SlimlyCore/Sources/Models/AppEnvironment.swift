import Foundation

/// Паспорт сборки: то, что показывает отладочное меню и что просят приложить
/// к обращению в поддержку.
///
/// Значения собраны в одну структуру, а не разбросаны по вызовам системы:
/// строку «версия · устройство · система · ID» показывают в двух местах,
/// и собираться она должна одинаково.
public struct AppEnvironment: Sendable, Hashable {
    public let version: String
    public let build: String
    public let device: String
    public let system: String
    public let installID: String

    public init(
        version: String,
        build: String,
        device: String,
        system: String,
        installID: String
    ) {
        self.version = version
        self.build = build
        self.device = device
        self.system = system
        self.installID = installID
    }

    /// «1.4.2 (218)» — ровно то, что видно в App Store и в настройках.
    public var versionText: String {
        "\(version) (\(build))"
    }

    /// Одна строка на всё: шапка отладочного меню и хвост письма в поддержку.
    public var summary: String {
        [versionText, device, system, "ID \(installID)"].joined(separator: " · ")
    }
}

public extension StorageKey where Value == String {
    static var installID: StorageKey { StorageKey("slimly.install.id") }
}

public extension AppEnvironment {
    /// Текущая сборка. Считается один раз: за время работы приложения
    /// ни одно из этих значений не меняется.
    static let current = AppEnvironment(
        version: infoValue("CFBundleShortVersionString"),
        build: infoValue("CFBundleVersion"),
        device: hardwareIdentifier,
        system: systemVersion,
        installID: installID()
    )

    private static func infoValue(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "—"
    }

    /// Модель приходит идентификатором вроде «iPhone16,1»: маркетинговое имя
    /// система не отдаёт, а таблица соответствий устаревает быстрее, чем
    /// выходят устройства.
    ///
    /// В симуляторе `uname` рассказывает про архитектуру мака, а не про
    /// устройство, поэтому там модель берём из окружения — иначе в отчёте
    /// об ошибке оказался бы «arm64».
    private static var hardwareIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return "\(simulated) (simulator)"
        }

        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { raw in
            // Имя модели — всегда ASCII, и пустая строка тут лучше отсутствия
            // значения: строка идёт прямо в отладочный экран.
            // swiftlint:disable:next optional_data_string_conversion
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    private static var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let patch = version.patchVersion == 0 ? "" : ".\(version.patchVersion)"
        return "iOS \(version.majorVersion).\(version.minorVersion)\(patch)"
    }

    /// Свой идентификатор установки, а не системный: `identifierForVendor`
    /// живёт в UIKit, которого в этом модуле быть не должно, а нужен он только
    /// затем, чтобы два обращения из одной установки узнавались как одно.
    private static func installID(in storage: any KeyValueStorage = DefaultsStorage()) -> String {
        if let stored: String = storage.value(for: .installID) { return stored }

        let raw = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8).uppercased()
        let generated = "\(raw.prefix(4))-\(raw.suffix(4))"
        storage.set(generated, for: .installID)
        return generated
    }
}
