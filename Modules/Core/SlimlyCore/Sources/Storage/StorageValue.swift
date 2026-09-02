import Foundation

/// Примитив, которым хранилище оперирует на самом деле.
///
/// Дальше этих пяти случаев не идём намеренно: всё, что умеет `UserDefaults`
/// сверх них (массивы, словари, даты), либо раскладывается по ним, либо
/// сериализуется в `data` — иначе хранилище пришлось бы менять под каждый
/// новый тип значения.
public enum StoredValue: Sendable, Equatable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case data(Data)
}

/// Тип, который умеет лежать в хранилище.
///
/// Превращение в примитив — дело самого типа, а не хранилища: так добавление
/// нового вида значения не трогает ни один бэкенд.
public protocol StorageValue: Sendable {
    init?(stored: StoredValue)

    var stored: StoredValue { get }
}

/// Enum с примитивным `rawValue` попадает в хранилище сам по себе:
/// `extension SimulatedFailure: StorageValue { }` — весь нужный код.
public extension StorageValue where Self: RawRepresentable, RawValue: StorageValue {
    init?(stored: StoredValue) {
        guard let raw = RawValue(stored: stored) else { return nil }
        self.init(rawValue: raw)
    }

    var stored: StoredValue { rawValue.stored }
}

/// Значение без примитивного вида: хранится как JSON.
///
/// Отдельный протокол, а не `where Self: Codable`, — потому что `Codable`
/// у примитивов тоже есть, и выбор реализации стал бы неочевидным.
public protocol CodableStorageValue: StorageValue, Codable { }

public extension CodableStorageValue {
    init?(stored: StoredValue) {
        guard case let .data(data) = stored,
              let value = try? JSONDecoder().decode(Self.self, from: data) else { return nil }

        self = value
    }

    /// Кодирование модели в JSON не падает ни на чём, кроме `Double.nan`,
    /// поэтому провал считаем «значения нет»: пустые данные не декодируются
    /// и чтение честно вернёт `nil`.
    var stored: StoredValue {
        .data((try? JSONEncoder().encode(self)) ?? Data())
    }
}
