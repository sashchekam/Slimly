import Foundation
import Observation

/// Язык интерфейса: что выбрал человек и что стоит в телефоне.
///
/// За протоколом по той же причине, что и отметка о туре: выбор ставит экран
/// настроек, а читают его и этот экран, и профиль, — общий у них сервис,
/// а не значение, переданное из одного в другой.
///
/// Живёт на главной очереди: выбор языка — это состояние приложения, за ним
/// наблюдает корень и пересобирает по нему экраны.
@MainActor
public protocol LocalizationService: Sendable {
    /// Выбранный вручную язык. `nil` — идти за телефоном.
    var preferred: AppLanguage? { get }

    /// Что просит телефон — идентификатор как есть, вместе с регионом.
    ///
    /// `nil`, когда язык выбран вручную: система с этого момента показывает
    /// приложению его собственный выбор, и назвать язык телефона можно было бы
    /// только выдумав его.
    var deviceIdentifier: String? { get }

    func setPreferred(_ language: AppLanguage?)
}

public extension LocalizationService {
    /// Язык телефона, приведённый к нашему списку. `nil` — такого у нас нет
    /// или телефон уже не спрашивают.
    var deviceLanguage: AppLanguage? { deviceIdentifier.flatMap(AppLanguage.closest(to:)) }

    /// На чём приложение говорит: ручной выбор, иначе язык телефона, иначе
    /// английский — язык разработки, на котором есть каждая строка.
    var current: AppLanguage { preferred ?? deviceLanguage ?? .english }
}

public extension StorageKey where Value == String {
    static var interfaceLanguage: StorageKey { StorageKey("slimly.language") }
}

/// Выбор языка в хранилище устройства.
///
/// Хранилищ на самом деле два, и это не дублирование. Своё отвечает на вопрос
/// «выбирал ли человек язык руками»: без него «выбрал английский» неотличимо
/// от «не выбирал ничего». Системный список `AppleLanguages` отвечает на другой
/// вопрос — на каком языке система выдаст строки при следующем запуске;
/// пишет его ``SystemLanguage``, и другого способа сказать системе про ручной
/// выбор нет.
@MainActor
@Observable
public final class StoredLocalization: LocalizationService {
    /// Выбранный язык лежит полем, а не читается из хранилища на каждом
    /// обращении: за ним наблюдает корень приложения, а `UserDefaults`
    /// SwiftUI не наблюдает.
    public private(set) var preferred: AppLanguage?

    private let storage: any KeyValueStorage
    private let system: any SystemLanguage

    public init(
        storage: any KeyValueStorage = DefaultsStorage(),
        system: any SystemLanguage = DefaultsSystemLanguage()
    ) {
        self.storage = storage
        self.system = system
        preferred = storage.value(for: .interfaceLanguage).flatMap(AppLanguage.init(rawValue:))
    }

    /// Телефон спрашиваем, только пока за ним идут: после ручного выбора
    /// система вернула бы нам его же.
    public var deviceIdentifier: String? {
        preferred == nil ? system.resolvedIdentifier : nil
    }

    public func setPreferred(_ language: AppLanguage?) {
        if let language {
            storage.set(language.code, for: .interfaceLanguage)
        } else {
            storage.removeValue(for: .interfaceLanguage)
        }

        system.setOverride(language?.code)
        // Система узнает про выбор только при следующем запуске, а строки
        // берут язык отсюда — поэтому экраны переводятся сразу.
        L10nBundle.language = language
        // Присвоение последним: на него смотрит корень и пересобирает дерево,
        // а к этому моменту строки уже отдают новый язык.
        preferred = language
    }
}
