import Foundation

public protocol TodoPersisting: Sendable {
    func load() throws -> [TodoItem]
    func save(_ todos: [TodoItem]) throws
}

public struct JSONTodoPersistence: TodoPersisting {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static var applicationSupport: JSONTodoPersistence {
        guard let baseDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            preconditionFailure("Application Support directory is unavailable.")
        }
        let directory = baseDirectory.appending(path: "GlassTodoNote", directoryHint: .isDirectory)
        return JSONTodoPersistence(fileURL: directory.appending(path: "todos.json"))
    }

    public func load() throws -> [TodoItem] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder.glassTodo.decode([TodoItem].self, from: data)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return []
        }
    }

    public func save(_ todos: [TodoItem]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder.glassTodo.encode(todos)
        try data.write(to: fileURL, options: [.atomic])
    }
}

extension JSONEncoder {
    static var glassTodo: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var glassTodo: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
