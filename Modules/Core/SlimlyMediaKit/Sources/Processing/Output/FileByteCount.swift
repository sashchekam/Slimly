import Foundation

extension URL {
    /// Вес файла в байтах; ноль, если файла нет или размер не читается.
    ///
    /// Через `FileManager`, а не через `resourceValues`: тот кеширует ответ
    /// в самом адресе и после перезаписи файла отдаёт прежнее число, а здесь
    /// размер спрашивают как раз до записи и после неё.
    var byteCount: Int64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        return (attributes?[.size] as? NSNumber)?.int64Value ?? 0
    }
}
